//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Lybron Sobers on 3/16/17.
//  Copyright © 2017 Lybron Sobers. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var photoData: NSData?
    @NSManaged public var pin: Pin?

}
