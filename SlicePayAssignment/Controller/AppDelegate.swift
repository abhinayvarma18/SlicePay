//
//  AppDelegate.swift
//  SlicePayAssignment
//
//  Created by ABHINAY on 14/03/18.
//  Copyright © 2018 ABHINAY. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FirebaseAuth
import Fabric
import Crashlytics


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        Fabric.with([Crashlytics.self])
        
        InternetStatus().monitorReachabilityChanges()
        
        Auth.auth().signInAnonymously() { (user,error) in
            if(error == nil) {
                UserDefaults.standard.setValue(user?.uid, forKey: "userId")
                self.fetchDataFromFirebase()
            }
        }
        
        return true
    }

    func fetchDataFromFirebase() {
        let firebaseManager = SPFirebaseHandler.handler
        var modelToUpdate:FormFields?
        var message:String = ""
        let cachedValues = firebaseManager.fetchProfileFromDB()
        if(isServerReachable() && cachedValues?.count == 0) {
            firebaseManager.fetchFields(completion: {(fields) in
                message = "Dynamic ui loaded from firebase based on active state of fieldsArray"
                modelToUpdate = fields
                let dummyVC = SPViewController()
                dummyVC.currentModel = modelToUpdate
                self.window?.backgroundColor = UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 1.0)
                self.window?.rootViewController = dummyVC
                self.window?.makeKeyAndVisible()
                let alert = UIAlertController(title: "Normal Launch", message: message, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {(handle) in
                    
                    
                }))
               // self.present(alert, animated: true, completion: nil)
            })
        }else{
            modelToUpdate = FormFields()
            if(cachedValues != nil) {
                for cache in cachedValues! {
                    let field = FormField()
                    if(cache.value(forKey: "dynamicFieldName") as? String != "profileImage") {
                        field.fieldName = cache.value(forKey: "dynamicFieldName") as? String
                        field.fieldValue = cache.value(forKey: "dynamicFieldValue") as? String
                         modelToUpdate?.fields.append(field)
                    }else{
                        modelToUpdate?.imageUrl = cache.value(forKey: "dynamicFieldValue") as? String
                    }
                }
//                if(isServerReachable()) {
//                    time = "Internet available! showing updated data synced on server"
//                    message = "Showing last saved updated data from app local database if it was not saved it will be saved automatically"
//                }else{
//                    title = "No Internet"
//                    message = "Showing data from app local database"
//                }
            }else{
                //first time when local db is empty to not show anything
                //this is the least minimum fields required
                let noInternetfieldsArray = ["name","password","description","address","mobile","phone","email"]
                for string in noInternetfieldsArray {
                    let field = FormField()
                    field.fieldName = string
                    modelToUpdate?.fields.append(field)
                }
                //title = "Hardcoded Data"
                //message = "Showing no internet dummy data. Since nothing is saved in app local database too.(1st time launch)"
            }
          
           // let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
           // alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {(handle) in
                let dummyVC = SPViewController()
                dummyVC.currentModel = modelToUpdate
                self.window?.backgroundColor = UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 1.0)
                self.window?.rootViewController = dummyVC
                self.window?.makeKeyAndVisible()
                //dummyVC.present(alert, animated: true, completion: nil)
            //}))
        }
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "SlicePayAssignment")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}
