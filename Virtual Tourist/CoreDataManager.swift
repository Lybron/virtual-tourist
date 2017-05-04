//
//  CoreDataManager.swift
//  Virtual Tourist
//
//  Created by Lybron Sobers on 3/14/17.
//  Copyright © 2017 Lybron Sobers. All rights reserved.
//

import CoreData

// MARK: - CoreDataStack

struct CoreDataManager {
  
  // MARK: Properties
  public static let shared = CoreDataManager(modelName: "Model")!
  
  private let model: NSManagedObjectModel
  internal let coordinator: NSPersistentStoreCoordinator
  private let modelURL: URL
  internal let dbURL: URL
  let context: NSManagedObjectContext
  internal let persistingContext: NSManagedObjectContext
  internal let backgroundContext: NSManagedObjectContext
  
  // MARK: Initializers
  
  private init?(modelName: String) {
    
    guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
      print("Unable to find \(modelName)in the main bundle")
      return nil
    }
    self.modelURL = modelURL
    
    // Try to create the model from the URL
    guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
      print("unable to create a model from \(modelURL)")
      return nil
    }
    self.model = model
    
    // Create the store coordinator
    coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    
    persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    persistingContext.persistentStoreCoordinator = coordinator
    
    // create a context and add connect it to the coordinator
    context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = coordinator
    
    backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    backgroundContext.persistentStoreCoordinator = coordinator
    
    // Add a SQLite store located in the documents folder
    let fm = FileManager.default
    
    guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
      print("Unable to reach the documents folder")
      return nil
    }
    
    self.dbURL = docUrl.appendingPathComponent("model.sqlite")
    
    // Options for migration
    let options = [NSInferMappingModelAutomaticallyOption: true,NSMigratePersistentStoresAutomaticallyOption: true]
    
    do {
      try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: options as [NSObject : AnyObject]?)
    } catch {
      print("unable to add store at \(dbURL)")
    }
  }
  
  // MARK: Utils
  
  func addStoreCoordinator(_ storeType: String, configuration: String?, storeURL: URL, options : [NSObject:AnyObject]?) throws {
    try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: nil)
  }
  
}

// MARK: - CoreDataStack (Removing Data)

internal extension CoreDataManager  {
  
  func dropAllData() throws {
    try coordinator.destroyPersistentStore(at: dbURL, ofType:NSSQLiteStoreType , options: nil)
    try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
  }
}

// MARK: - CoreDataManager (Batch Processing in the Background)

extension CoreDataManager {
  func performInBackGround(_ block: @escaping (_ workerContext: NSManagedObjectContext) -> ()){
    backgroundContext.perform() {
      block(self.backgroundContext)
      do {
        try self.backgroundContext.save()
      } catch {
        fatalError("Error while saving background context: \(error)")
      }
    }
  }
}

// MARK: - CoreDataManager (Save Data)

extension CoreDataManager {
  
  func saveContext() throws {
    
    context.performAndWait() {
      
      if self.context.hasChanges {
        do {
          try self.context.save()
        } catch {
          fatalError("Error while saving main context: \(error)")
        }
        
        // Save in the background
        self.persistingContext.perform() {
          do {
            try self.persistingContext.save()
          } catch {
            fatalError("Error while saving persisting context: \(error)")
          }
        }
      }
    }
  }
  
  func autoSave(_ delayInSeconds : Int) {
    
    if delayInSeconds > 0 {
      do {
        try saveContext()
        print("Autosaving")
      } catch {
        print("Error while autosaving")
      }
      
      let delayInNanoSeconds = UInt64(delayInSeconds) * NSEC_PER_SEC
      let time = DispatchTime.now() + Double(Int64(delayInNanoSeconds)) / Double(NSEC_PER_SEC)
      
      DispatchQueue.main.asyncAfter(deadline: time) {
        self.autoSave(delayInSeconds)
      }
    }
  }
}
