//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Lybron Sobers on 3/16/17.
//  Copyright © 2017 Lybron Sobers. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
  convenience init(photoData: NSData = NSData(), context: NSManagedObjectContext) {
    if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
      self.init(entity: entity, insertInto: context)
      self.photoData = photoData
    } else {
      fatalError("No entity with the name Pin")
    }
  }
}
