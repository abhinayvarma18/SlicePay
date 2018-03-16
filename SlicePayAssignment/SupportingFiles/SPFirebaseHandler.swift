//
//  SPFirebaseHandler.swift
//  SlicePayAssignment
//
//  Created by ABHINAY on 15/03/18.
//  Copyright © 2018 ABHINAY. All rights reserved.
//

import UIKit
import FirebaseDatabase
import CoreData

class SPFirebaseHandler: NSObject {
    
    static let handler = SPFirebaseHandler()
    fileprivate let instance:DatabaseReference = Database.database().reference()
    var userKey:String = UserDefaults.standard.value(forKey: "userId") as? String ?? "dummynotpossible"
    static let fieldString:String = "fieldArray"
    
    open lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()
    
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application.
        let modelURL = Bundle.main.url(forResource: "SlicePayAssignment", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    open lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SlicePayAssignment.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                               configurationName: nil,
                                               at: url, options: nil)
        } catch {
            // Report any error we got.
            abort()
        }
        
        return coordinator
    }()
    
    open lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    func fetchFields(completion:@escaping (FormFields) -> ()) {
        instance.child(SPFirebaseHandler.fieldString).queryOrdered(byChild: "active").queryEqual(toValue: true).observeSingleEvent(of: .value, with: {(snapshot) in
            let fieldArray = snapshot.value as? [String:Any] ?? [:]
            let fieldItems = FormFields()
            for key in fieldArray.keys {
                let model = FormField()
                model.fieldName = key
                fieldItems.fields.append(model)
            }
            completion(fieldItems)
        })
    }
    
    
    func updateChangeOfFirebase(completion:@escaping (FormFields?) -> ()) {
        instance.child("FormInfo").child(userKey).observe(.value, with: {(snapshot) in
            let savedDataOnServer = snapshot.value as? Dictionary<String,String> ?? [:]
            let currentProfile = self.fetchProfileFromDB()
            if(savedDataOnServer.isEmpty && currentProfile == nil) {
                //no data saved yet on server for the existing user node
                 completion(nil)
                 return
            }
            
            let updatedProfile = self.parseFirebaseProfileData(dict: savedDataOnServer)
            
            if(currentProfile == nil) {
                //when no data is saved in local db
                self.saveProfileInDB(profileDict: updatedProfile, andState: true)
                completion(updatedProfile)
            }else{
                if(!(self.compareElements(serverObject:updatedProfile, currentObj: currentProfile!)) && currentProfile![0].value(forKey: "isSynced") as! Bool) {
                    //when data differs in remote and local and has successfully synced to server already
                    //It doesn't have to update the data in local if there is any sync which is not yet done
                    //so if there is any change in local db with no internet it wont let override server data until it updates its data on remote
                    self.saveProfileInDB(profileDict: updatedProfile, andState: true)
                    completion(updatedProfile)
                }else{
                    // No Internet Data's been saved here which was saved while there was no internet
                    //IMP:OVERRIDING SERVER DATA ON NO-INTERNET
                    if(currentProfile![0].value(forKey: "isSynced") as! Bool == false) {
                        let profileForm:FormFields = FormFields()
                        self.updateLocalDatabaseValueOverFirebase(updatedArray: currentProfile!)
                        for field in currentProfile! {
                            let fieldModel = FormField()
                            fieldModel.fieldName = field.value(forKey: "dynamicFieldName") as? String
                            fieldModel.fieldValue = field.value(forKey: "dynamicFieldValue") as? String
                            profileForm.fields.append(fieldModel)
                        }
                        self.saveProfileInDB(profileDict: profileForm, andState: true)
                        completion(nil)
                    }else {
                        completion(updatedProfile)
                    }
                  }
            }
        })
    }
    
    func updateLocalDatabaseValueOverFirebase(updatedArray:[FormValues]) {
        var updatedProfileDict:Dictionary<String,String> = [:]
        
        for field in updatedArray {
            
            updatedProfileDict[field.value(forKey: "dynamicFieldName") as! String] = field.value(forKey: "dynamicFieldValue") as? String
        }
        
        instance.child("FormInfo").child(userKey).setValue(updatedProfileDict)
    }
    
    func updateValuesOnFirebase(newModel:FormFields,completion:@escaping()->()) {
        var updatedProfileDict:Dictionary<String,String> = [:]
        
        for field in newModel.fields {
            updatedProfileDict[field.fieldName!] = field.fieldValue
        }
        self.saveProfileInDB(profileDict: newModel, andState: true)
        instance.child("FormInfo").child(userKey).setValue(updatedProfileDict)
        completion()
    }
    
    
    func compareElements(serverObject:FormFields,currentObj:[FormValues]) -> Bool {
        
        if(serverObject.fields.count == 0) {
            return false
        }
        
        for serverfield in (serverObject.fields) {
            let foundDbFieldArray = currentObj.filter({($0.value(forKey: "dynamicFieldName") as! String) == serverfield.fieldName})
            if(foundDbFieldArray.count == 0 || serverfield.fieldValue != (foundDbFieldArray[0].value(forKey: "dynamicFieldValue") as? String)) {
                return false
            }
        }
        return true
    }
    
    func parseFirebaseProfileData(dict:Dictionary<String,Any>) -> FormFields {
        let fields = FormFields()
        for (key,value) in dict {
            let newField = FormField()
            newField.fieldName = key
            newField.fieldValue = value as? String ?? ""
            fields.fields.append(newField)
        }
        return fields
    }
    
    func saveProfileInDB(profileDict:FormFields, andState:Bool) {
        self.resetAllRecords(entity: "FormValues")
        print("count of dict is \(profileDict.fields.count)")
        let entity =  NSEntityDescription.entity(forEntityName: "FormValues", in:managedObjectContext!)
        for field in profileDict.fields {
            let item = NSManagedObject(entity: entity!, insertInto:managedObjectContext!)
            item.setValue(field.fieldName, forKey: "dynamicFieldName")
            item.setValue(field.fieldValue, forKey: "dynamicFieldValue")
            item.setValue(andState, forKey: "isSynced")
            do {
                try managedObjectContext!.save()
            } catch {
                print("Something went wrong.")
            }
        }
    }
    
    func resetAllRecords(entity : String) // entity = Your_Entity_Name
    {
      //  let context = ( UIApplication.shared.delegate as! AppDelegate ).persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do
        {
            try managedObjectContext!.execute(deleteRequest)
            try managedObjectContext!.save()
        }
        catch
        {
            print ("There was an error")
        }
    }
    
    
    func fetchProfileFromDB() -> [FormValues]? {
        let fetchRequest = NSFetchRequest<FormValues>(entityName: "FormValues")
        do {
            let fetchedResults = try managedObjectContext!.fetch(fetchRequest)
            if fetchedResults.count > 0 {
                return fetchedResults
            }else{
                return nil
            }
        } catch _ as NSError {
            // something went wrong, print the error.
            return nil
        }
    }
}
