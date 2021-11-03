//
//  Location+CoreDataProperties.swift
//  MyLocations
//
//  Created by Стожок Артём on 28.10.2021.
//
//

import Foundation
import CoreData
import CoreLocation


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var category: String
    @NSManaged public var date: Date
    @NSManaged public var latitude: Double
    @NSManaged public var locationDescription: String
    @NSManaged public var longtitude: Double
    @NSManaged public var placemark: CLPlacemark?
    @NSManaged public var photoID: NSNumber?

}

extension Location : Identifiable {

}
