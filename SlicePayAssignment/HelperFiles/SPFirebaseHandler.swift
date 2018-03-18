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
import FirebaseStorage

class SPFirebaseHandler: NSObject {
    
    static let handler = SPFirebaseHandler()
    fileprivate let instance:DatabaseReference = Database.database().reference()
    var userKey:String = UserDefaults.standard.value(forKey: "userId") as? String ?? "dummynotpossible"
    static let fieldString:String = "fieldsArray"
    var reference:UInt?
    var firstTimeSave:Bool? = false
    let sharedActivity = SPActivityLoaderView.sharedInstance
    //MARK:Firebase methods fetch , save , delete
    
    //Fetching Fields initially
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
    
    func removeListenerFromNode() {
        instance.child("formInfo").child(userKey).removeObserver(withHandle: reference!)
    }
    
    
    func setupListnerOnUserNode(completion:@escaping (FormFields?) -> ()) {
        reference = instance.child("formInfo").child(userKey).observe(.value, with: {(snapshot) in
            print("I was called 2nd")
            self.sharedActivity.showLoader()
            let savedDataOnServer = snapshot.value as? Dictionary<String,Any> ?? [:]
            let currentProfile = self.fetchProfileFromDB()
            if(savedDataOnServer.isEmpty && currentProfile == nil) {
                //no data saved yet on server for the existing user node
                self.firstTimeSave = true
                 completion(nil)
                 return
            }else if(!savedDataOnServer.isEmpty) {
                self.firstTimeSave = false
            }
            
            let updatedProfile = self.parseFirebaseProfileData(dict: savedDataOnServer)
            
            if(currentProfile == nil) {
                //when no data is saved in local db
                self.saveProfileInDB(profileDict: updatedProfile, andState: true)
                completion(updatedProfile)
            }else{
                if(!(self.compareElements(serverObject:updatedProfile, currentObj: currentProfile!)) && currentProfile![0].value(forKey: "isSynced") as! Bool) {
                    print("I was called 3rd local DB only")
                    //when data differs in remote and local and has successfully synced to server already
                    //It doesn't have to update the data in local if there is any sync which is not yet done
                    //so if there is any change in local db with no internet it wont let override server data until it updates its data on remote
                    self.saveProfileInDB(profileDict: updatedProfile, andState: true)
                    completion(updatedProfile)
                }else{
                    // No Internet Data's been saved here which was saved while there was no internet
                    //IMP:OVERRIDING SERVER DATA ON NO-INTERNET
                    if(currentProfile![0].value(forKey: "isSynced") as! Bool == false) {
                        print("I was called 4th")
                        let profileForm:FormFields = FormFields()
                        for field in currentProfile! {
                            let fieldModel = FormField()
                            if(field.value(forKey: "dynamicFieldName") as? String != "profileImage") {
                                fieldModel.fieldName = field.value(forKey: "dynamicFieldName") as? String
                                fieldModel.fieldValue = field.value(forKey: "dynamicFieldValue") as? String
                            }else{
                                profileForm.imageUrl = field.value(forKey: "dynamicFieldValue") as? String
                            }
                            profileForm.fields.append(fieldModel)
                        }
                        self.saveProfileInDB(profileDict: profileForm, andState: true)
                        self.updateLocalDatabaseValueOverFirebase(updatedArray: currentProfile!)
                        completion(nil)
                    }else {
                        print("I was called 5th")
                        completion(nil)
                    }
                }
            }
        })
    }
    
    func isSyncedDataInLocalDB()->Bool {
        let offLineData = self.fetchProfileFromDB()
        if(offLineData != nil) {
            if(offLineData![0].value(forKey: "isSynced") as! Bool == false) {
                return false
            }
        }
        return true
    }
    
    func updateLocalDatabaseValueOverFirebase(updatedArray:[FormValues]) {
        sharedActivity.showLoader()
        var updatedProfileDict:Dictionary<String,String> = [:]
        let databaseModel = FormFields()
        for field in updatedArray {
            if(field.value(forKey: "dynamicFieldName") as! String != "profileImage") {
                updatedProfileDict[field.value(forKey: "dynamicFieldName") as! String] = field.value(forKey: "dynamicFieldValue") as? String
                let fieldModel = FormField()
                fieldModel.fieldName = field.value(forKey: "dynamicFieldName") as? String
                fieldModel.fieldValue = field.value(forKey: "dynamicFieldValue") as? String
                databaseModel.fields.append(fieldModel)
            }else{
                updatedProfileDict[field.value(forKey: "dynamicFieldName") as! String] = field.value(forKey: "dynamicFieldValue") as? String
            }
        }
        
        if(self.isSyncedDataInLocalDB()) {
            instance.child("formInfo").child(userKey).setValue(updatedProfileDict)
            sharedActivity.removeLoader()
        }else{
            if let fileImage = self.load(fileName: "FileName") {
                self.saveImageOnStorage(image: fileImage, completion: {(image) in
                    updatedProfileDict["profileImage"] = image
                    databaseModel.imageUrl = image
                    self.saveProfileInDB(profileDict: databaseModel, andState: true)
                    self.instance.child("formInfo").child(self.userKey).setValue(updatedProfileDict)
                    self.sharedActivity.removeLoader()
                 })
            }else{
                self.sharedActivity.removeLoader()
            }
        }
    }
    
    
    
    func updateValuesOnFirebase(newModel:FormFields,completion:@escaping(DatabaseReference?)->()) {
        var updatedProfileDict:Dictionary<String,String> = [:]
        self.sharedActivity.showLoader()
        for field in newModel.fields {
            updatedProfileDict[field.fieldName!] = field.fieldValue
        }
        let checkFlag = self.isSyncedDataInLocalDB()
        if(newModel.imageUrl == "needstobbesaved" || !checkFlag) {
            if(!checkFlag) {
                newModel.image = self.load(fileName: "FileName")
            }
            self.saveImageOnStorage(image: newModel.image!, completion: {(image) in
                updatedProfileDict["profileImage"] = image
                newModel.imageUrl = image
                self.saveProfileInDB(profileDict: newModel, andState: true)
                
                //save image on firebase storage
                self.instance.child("formInfo").child(self.userKey).setValue(updatedProfileDict, withCompletionBlock: { (error,ref) in
                    if(self.firstTimeSave)! {
                        self.sharedActivity.removeLoader()
                        completion(ref)
                        self.firstTimeSave = false
                    }else{
                        self.sharedActivity.removeLoader()
                        completion(nil)
                    }
                })
            })
        }else{
            updatedProfileDict["profileImage"] = newModel.imageUrl
            self.saveProfileInDB(profileDict: newModel, andState: true)
            
            //save image on firebase storage
            self.instance.child("formInfo").child(self.userKey).setValue(updatedProfileDict, withCompletionBlock: { (error,ref) in
                if(self.firstTimeSave)! {
                    self.sharedActivity.removeLoader()
                    completion(ref)
                    self.firstTimeSave = false
                }else{
                    self.sharedActivity.removeLoader()
                    completion(nil)
                }
            })
        }
    }
    
    func saveImageOnStorage(image:UIImage,completion: @escaping (String)-> ()) {
        let imageName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).png")
        
        if let uploadData = UIImagePNGRepresentation(image) {
            
            storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if let error = error {
                    print(error)
                    return
                }
                
                if let profileImageUrl = metadata?.downloadURL()?.absoluteString {
                    completion(profileImageUrl)
                }
            })
        }
    }
    
    func compareElements(serverObject:FormFields,currentObj:[FormValues]) -> Bool {
        
        if(serverObject.fields.count == 0 || serverObject.fields.count != currentObj.count - 1) {
            return false
        }
        
        for serverfield in (serverObject.fields) {
            let foundDbFieldArray = currentObj.filter({($0.value(forKey: "dynamicFieldName") as! String) == serverfield.fieldName})
            if(foundDbFieldArray.count == 0 || serverfield.fieldValue != (foundDbFieldArray[0].value(forKey: "dynamicFieldValue") as? String)) {
                return false
            }
        }
        
        let imageArray = currentObj.filter({($0.value(forKey: "dynamicFieldName") as! String) == "profileImage"})
        if(imageArray.count != 0 && serverObject.imageUrl != imageArray[0].value(forKey: "dynamicFieldValue") as? String) {
            return false
        }
        
        return true
    }
    
    func parseFirebaseProfileData(dict:Dictionary<String,Any>) -> FormFields {
        let fields = FormFields()
        for (key,value) in dict {
            let newField = FormField()
            if(key != "profileImage") {
                newField.fieldName = key
                newField.fieldValue = value as? String ?? ""
                if(value as? Int != nil && (newField.fieldValue?.isEmpty)!) {
                    newField.fieldValue = String(value as! Int)
                }
                fields.fields.append(newField)
            }else{
                fields.imageUrl = value as? String ?? ""
            }
        }
        return fields
    }
    
    
    //MARK:Local DB methods
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
        if(profileDict.fields.count != 0) {
            let item = NSManagedObject(entity: entity!, insertInto:managedObjectContext!)
            item.setValue("profileImage", forKey: "dynamicFieldName")
            item.setValue(profileDict.imageUrl, forKey: "dynamicFieldValue")
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
    
    //Load last local save image from the file where we saved
    func load(fileName: String) -> UIImage? {
        var documentsUrl: URL {
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        let fileURL = documentsUrl.appendingPathComponent(fileName)
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image : \(error)")
        }
        return nil
    }
    
}

