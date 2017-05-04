//
//  Pin+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Lybron Sobers on 3/16/17.
//  Copyright © 2017 Lybron Sobers. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {
  convenience init(uniqueID: String = UUID().uuidString, title: String = "Place", subtitle: String = "Country", latitude: Float = 0.0, longitude: Float = 0.0, context: NSManagedObjectContext) {
    if let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
      self.init(entity: entity, insertInto: context)
      self.uniqueID = uniqueID
      self.title = title
      self.subtitle = subtitle
      self.latitude = latitude
      self.longitude = longitude
    } else {
      fatalError("No entity with the name Pin")
    }
  }
}
