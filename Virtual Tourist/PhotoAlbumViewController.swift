//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Lybron Sobers on 3/14/17.
//  Copyright © 2017 Lybron Sobers. All rights reserved.
//

import UIKit
import MapKit
import CoreData

private let reuseIdentifier = "PhotoCell"

class PhotoAlbumViewController: UIViewController {
  
  // MARK: Properties
  var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
    didSet {
      fetchedResultsController?.delegate = self
      executeSearch()
    }
  }
  
  var pin: Pin!
  
  // MARK: IBOutlets
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
  @IBOutlet weak var newButton: UIBarButtonItem!
  @IBOutlet weak var pinsLabel: UILabel!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  // MARK: View Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.allowsMultipleSelection = true
    
    configureMap()
    configureCollectionView()
    
    if let fetchControl = fetchedResultsController, let objects = fetchControl.fetchedObjects {
      if objects.count == 0 { fetchPhotos() }
    }
  }
  
  // MARK: IBActions
  @IBAction func collectionButtonPressed(_ sender: Any) {
    if collectionView.indexPathsForSelectedItems!.count > 0 {
      removeSelectedItems()
    } else {
      loadNewCollection()
    }
  }
  
  private func loadNewCollection() {
    for photo in fetchedResultsController!.fetchedObjects! {
      CoreDataManager.shared.context.delete(photo as! Photo)
    }
    
    do {
      try CoreDataManager.shared.context.save()
    } catch {
      print("error saving before new collection")
    }
    
    updateData()
    
    fetchPhotos()
  }
  
  private func fetchPhotos() {
    self.newButton.isEnabled = false
    
    self.view.insertSubview(self.activityIndicator, aboveSubview: self.collectionView)
    self.activityIndicator.isHidden = false
    self.activityIndicator.startAnimating()
    
    CoreDataManager.shared.context.perform({
      FlickrClient.shared.getPhotosForLocation(self.pin, context: self.fetchedResultsController!.managedObjectContext, completion: { (finished, error) in
                
        self.newButton.isEnabled = true
        self.activityIndicator.isHidden = true
        self.activityIndicator.stopAnimating()
        
        self.configureCollectionView()
      })
    })
  }
  
  private func removeSelectedItems() {
    
    guard let collection = collectionView, collectionView.indexPathsForSelectedItems!.count > 0 else {
      return
    }
    
    for indexPath in collection.indexPathsForSelectedItems! {
      let photo = self.fetchedResultsController!.object(at: indexPath)
      CoreDataManager.shared.context.delete(photo as! Photo)
    }
    
    do {
      try CoreDataManager.shared.saveContext()
    } catch {
      print("Changes could not be saved")
    }
    
    collection.deleteItems(at: collection.indexPathsForSelectedItems!)
    
    collection.reloadData()
    
    editingMode(false)
  }
  
  // MARK: Helpers
  func executeSearch() {
    if let fetchControl = fetchedResultsController {
      do {
        try fetchControl.performFetch()
      } catch let e as NSError {
        print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
      }
    }
  }
  
  func updateData() {
    if let collection = collectionView {
      collection.reloadData()
    }
  }
  
  private func configureMap() {
    let annotation = MKPointAnnotation()
    annotation.title = pin.title
    annotation.subtitle = pin.subtitle
    annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
    mapView.addAnnotation(annotation)
    mapView.isUserInteractionEnabled = false
    
    let region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(annotation.coordinate.latitude, annotation.coordinate.longitude), span: MKCoordinateSpanMake(0.1, 0.1))
    self.mapView.setRegion(region, animated: false)
  }
  
  private func configureCollectionView() {
    if let fetchControl = fetchedResultsController, let objects = fetchControl.fetchedObjects {
      if objects.count == 0 {
        collectionView.isHidden = true
        pinsLabel.isHidden = false
        return }
    }
    
    pinsLabel.isHidden = true
    collectionView.isHidden = false
    
    let space: CGFloat = 3.0
    let dimension = (view.frame.size.width - (2 * space)) / 3.0
    
    flowLayout.minimumInteritemSpacing = space
    flowLayout.minimumLineSpacing = space
    flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    
    collectionView!.collectionViewLayout = flowLayout
  }
  
  func editingMode(_ enabled: Bool) {
    if enabled {
      newButton.title = "Remove Items"
      newButton.tintColor = .red
    } else {
      newButton.title = "New Collection"
      newButton.tintColor = .blue
    }
  }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    
    if let fetchControl = fetchedResultsController, let sections = fetchControl.sections {
      return sections.count
    } else {
      return 0
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    if let fetchControl = fetchedResultsController, let sections = fetchControl.sections {
      return sections[section].numberOfObjects
    } else {
      return 0
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
    
    let photo = fetchedResultsController?.object(at: indexPath) as! Photo
    
    cell.photoView?.contentMode = .scaleAspectFill
    cell.photoView?.image = UIImage(data: photo.photoData! as Data)
    
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let cell = collectionView.cellForItem(at: indexPath) else { return }
    
    cell.alpha = 0.7
    
    if collectionView.indexPathsForSelectedItems!.count > 0 { editingMode(true) }
  }
  
  func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    guard let cell = collectionView.cellForItem(at: indexPath) else { return }
    
    cell.alpha = 1.0
    
    if collectionView.indexPathsForSelectedItems!.count == 0 { editingMode(false) }
  }
  
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    
    switch type {
    case .update:
      if let _ = indexPath {
        collectionView.reloadData()
      }
    default:
      break
    }
  }
 
}
