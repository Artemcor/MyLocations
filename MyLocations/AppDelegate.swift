//
//  AppDelegate.swift
//  MyLocations
//
//  Created by Стожок Артём on 13.10.2021.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    lazy var persistentContainer: NSPersistentContainer = {
      let container = NSPersistentContainer(name: "MyLocations")
      container.loadPersistentStores {_, error in
        if let error = error {
          fatalError("Could not load data store: \(error)")
        }
    }
      return container
    }()
    lazy var managedObjectContext = persistentContainer.viewContext

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let tabController = window!.rootViewController as! UITabBarController
        if let tabViewControllers = tabController.viewControllers {
            var navController = tabViewControllers[0] as! UINavigationController
            let controller1 = navController.viewControllers.first as! CurrentLocationViewController
            controller1.managedObjectContext = managedObjectContext
            navController = tabViewControllers[1] as! UINavigationController
            let controller2 = navController.viewControllers.first as! LocationViewController
            controller2.manageObjectContext = managedObjectContext
            navController = tabViewControllers[2] as! UINavigationController
            let controller3 = navController.viewControllers.first as! MapViewController
            controller3.managedObjectContext = managedObjectContext
        }
        print(applicationDocumentsDirectory)
        listenForFatalCoreDataNotifications()
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        saveContext()
        NotificationCenter.default.post(name: didEnterBackGroundNotification, object: nil)
    }
    
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
    
    //MARK: - Helpers
    
    func listenForFatalCoreDataNotifications() {
        NotificationCenter.default.addObserver(forName: dataSaveFailedNotofication, object: nil, queue: OperationQueue.main) {_ in
            let massege = """
            There was a fatal error in the app and it cannot continue.
            
            Press OK to terminate the app. Sorry for the inconvenience.
            """
            let alert = UIAlertController(title: "Internal Error", message: massege, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default) {_ in
                let exception = NSException(name: NSExceptionName.internalInconsistencyException, reason: "Fatal Core data Error", userInfo: nil)
                exception.raise()
            }
            alert.addAction(action)
            let tabController = self.window?.rootViewController
            tabController?.present(alert, animated: true, completion: nil)
        }
    }
}

