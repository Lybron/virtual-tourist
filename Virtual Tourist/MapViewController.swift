//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Lybron Sobers on 3/14/17.
//  Copyright © 2017 Lybron Sobers. All rights reserved.
//

import UIKit
import MapKit
import CoreData

internal let PinDetailSegue = "PinDetailSegue"

class MapViewController: CoreDataViewController {
  
  // MARK: Properties
  internal var isEditingPins: Bool = false
  
  // MARK: IBOutlets
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var editView: UIView!
  @IBOutlet weak var editButton: UIBarButtonItem!
  
  // MARK: View Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureMap()
    
    let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(dropPin(_:)))
    longPressRecognizer.delegate = self
    longPressRecognizer.minimumPressDuration = 0.5
    self.mapView.addGestureRecognizer(longPressRecognizer)
    
    // Core Data
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: CoreDataConstants.EntityNames.Pin)
    request.sortDescriptors = []
    fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataManager.shared.context, sectionNameKeyPath: nil, cacheName: nil)
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  // MARK: Map Data  
  
  @IBAction func toggleEditing(_ sender: Any) {
    if isEditingPins {
      hideEditPrompt()
    } else {
      showEditPrompt()
    }
    
    isEditingPins = !isEditingPins
  }
  
  private func showEditPrompt() {
    editButton.title = "Done"
    editView.isHidden = false
    
    UIView.animate(withDuration: 0.25, animations: {
      var newFrame = self.editView.frame
      newFrame.origin.y = self.view.frame.height - self.editView.frame.size.height
      self.editView.frame = newFrame
      
      var newMapFrame = self.view.frame
      newMapFrame.size.height = self.view.frame.size.height - self.editView.frame.size.height
      self.mapView.frame = newMapFrame
    })
  }
  
  private func hideEditPrompt() {
    editButton.title = "Edit"
    UIView.animate(withDuration: 0.25, animations: {
      var newFrame = self.editView.frame
      newFrame.origin.y = self.view.frame.height
      self.editView.frame = newFrame
      self.mapView.frame = self.view.frame
    }, completion: { (finished) in
      do {
        try CoreDataManager.shared.saveContext()
      } catch {
        fatalError("could not delete pins")
      }
    })
  }
  
  internal func removePin(_ annotation: VTPointAnnotation) {
    guard let pin = pinByID(annotation.uniqueID) else {
      return
    }
    
    CoreDataManager.shared.context.delete(pin)
  }
  
  private func pinByID(_ uniqueID: String) -> Pin? {
    let pinFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CoreDataConstants.EntityNames.Pin)
    pinFetchRequest.sortDescriptors = []
    
    let pinPredicate = NSPredicate(format: "uniqueID = %@", argumentArray: [uniqueID])
    pinFetchRequest.predicate = pinPredicate
    
    do {
      let matchingPins = try CoreDataManager.shared.context.fetch(pinFetchRequest) as! [Pin]
      
      if let pin = matchingPins.first {
        return pin
      }
    } catch {
      fatalError("core data error fetching pin")
    }
    
    return nil
  }
  
  override func executeSearch() {
    super.executeSearch()
    
    if let pins = fetchedResultsController?.fetchedObjects as? [Pin] {
      self.mapView.removeAnnotations(self.mapView.annotations)
      
      for pin in pins {
        let annotation = VTPointAnnotation()
        annotation.uniqueID = pin.uniqueID
        annotation.title = pin.title
        annotation.subtitle = pin.subtitle
        annotation.coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(pin.latitude), CLLocationDegrees(pin.longitude))
        
        self.mapView.addAnnotation(annotation)
      }
    } else {
      showError(NSError(domain: "updatePinsError", code: 1, userInfo: [NSLocalizedDescriptionKey: "There was an error creating pins for the map."]))
    }
  }
  
  private func configureMap() {
    let centerLatitude = UserDefaults.standard.float(forKey: MapUserPreferenceKeys.LastRegionLatitudeKey)
    let centerLongitude = UserDefaults.standard.float(forKey: MapUserPreferenceKeys.LastRegionLongitudeKey)
    let latitudeSpan = UserDefaults.standard.float(forKey: MapUserPreferenceKeys.LastRegionSpanLatitudeKey)
    let longitudeSpan = UserDefaults.standard.float(forKey: MapUserPreferenceKeys.LastRegionSpanLongitudeKey)
    
    let span = MKCoordinateSpan(latitudeDelta: CLLocationDegrees(latitudeSpan), longitudeDelta: CLLocationDegrees(longitudeSpan))
    let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(centerLatitude), longitude: CLLocationDegrees(centerLongitude))
    
    let region = MKCoordinateRegion(center: coordinate, span: span)
    
    self.mapView.setRegion(region, animated: false)
    self.mapView.isPitchEnabled = false
  }
  
  // MARK: Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == PinDetailSegue, let annotation = sender as? VTPointAnnotation {
      if let albumController = segue.destination as? PhotoAlbumViewController {
        
        let fetch = pinByID(annotation.uniqueID)
        
        guard let pin = fetch else {
          return
        }
        
        albumController.pin = pin
        
        let photosFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CoreDataConstants.EntityNames.Photo)
        photosFetchRequest.sortDescriptors = []
        
        let photosPRedicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
        photosFetchRequest.predicate = photosPRedicate
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: photosFetchRequest, managedObjectContext: CoreDataManager.shared.context, sectionNameKeyPath: nil, cacheName: nil)
        
        albumController.fetchedResultsController = fetchedResultsController
        
      }
    }
  }
  
}

// MARK: UIGestureReconizerDelegate
extension MapViewController: UIGestureRecognizerDelegate {
  
  private func createPin(_ placemark: CLPlacemark, context bgContext: NSManagedObjectContext) {
    let pin = Pin(
      uniqueID: UUID().uuidString,
      title: placemark.name ?? "Unknown Place",
      subtitle: placemark.country ?? "",
      latitude: Float(placemark.location!.coordinate.latitude),
      longitude: Float(placemark.location!.coordinate.longitude),
      context: bgContext)
    
    
    let annotation = VTPointAnnotation()
    annotation.uniqueID = pin.uniqueID
    annotation.title = pin.title
    annotation.subtitle = pin.subtitle
    annotation.coordinate = placemark.location!.coordinate
    
    DispatchQueue.main.async {
      self.mapView.addAnnotation(annotation)
    }    
  }
  
  internal func dropPin(_ sender: Any?) {
    guard let gesture = sender as? UILongPressGestureRecognizer else {
      return
    }
    
    if gesture.state == .began {
      let touchPoint = gesture.location(in: mapView)
      
      let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
      
      let annotation = MKPointAnnotation()
      annotation.coordinate = coordinate
      
      let geocoder = CLGeocoder()
      geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { (placemarks, error) in
        
        guard error == nil else {
          self.showError(NSError(domain: "reverseGeocodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "There was an error determining the selected location"]))
          return
        }
        
        if let placemarks = placemarks, !placemarks.isEmpty {
          let placemark = placemarks[0]
          
          CoreDataManager.shared.performInBackGround({ (bgContext) in
            self.createPin(placemark, context: bgContext)
          })
          
        }
      }
    }
  }
}
