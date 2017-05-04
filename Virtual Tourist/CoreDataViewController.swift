//
//  CoreDataViewController.swift
//  Virtual Tourist
//
//  Created by Lybron Sobers on 3/16/17.
//  Copyright © 2017 Lybron Sobers. All rights reserved.
//

import UIKit
import CoreData

class CoreDataViewController: UIViewController {
  
  // MARK: Properties
  var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? {
    didSet {
      fetchedResultsController?.delegate = self
      executeSearch()
      updateData()
    }
  }
  
  func executeSearch() {
    if let fc = fetchedResultsController {
      do {
        try fc.performFetch()
      } catch let e as NSError {
        print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
      }
    }
  }
  
  func updateData() {}
}

extension CoreDataViewController: NSFetchedResultsControllerDelegate {
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    if let _ = controller.fetchedObjects {
      updateData()
    }
  }
}
