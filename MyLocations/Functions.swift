//
//  Functions.swift
//  MyLocations
//
//  Created by Стожок Артём on 21.10.2021.
//

import Foundation

func afterDelay(_ seconds: Double, run: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: run)
}

let applicationDocumentsDirectory: URL = {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}()

let dataSaveFailedNotofication = Notification.Name("DataSaveFailedNotification")
let didEnterBackGroundNotification = Notification.Name("didEnterBackGroundNotification")

func fatalCoreDataError(_ error: Error) {
    print("*** Fetal error: \(error)")
    NotificationCenter.default.post(name: dataSaveFailedNotofication, object: nil)
}
