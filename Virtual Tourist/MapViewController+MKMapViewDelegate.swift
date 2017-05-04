//
//  MapViewController+MKMapViewDelegate.swift
//  Virtual Tourist
//
//  Created by Lybron Sobers on 3/14/17.
//  Copyright © 2017 Lybron Sobers. All rights reserved.
//

import Foundation
import MapKit

extension MapViewController: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    let centerLatitude = mapView.region.center.latitude
    let centerLongitude = mapView.region.center.longitude
    let latitudeSpan = mapView.region.span.latitudeDelta
    let longitudeSpan = mapView.region.span.longitudeDelta
    
    UserDefaults.standard.set(centerLatitude, forKey: MapUserPreferenceKeys.LastRegionLatitudeKey)
    UserDefaults.standard.set(centerLongitude, forKey: MapUserPreferenceKeys.LastRegionLongitudeKey)
    UserDefaults.standard.set(latitudeSpan, forKey: MapUserPreferenceKeys.LastRegionSpanLatitudeKey)
    UserDefaults.standard.set(longitudeSpan, forKey: MapUserPreferenceKeys.LastRegionSpanLongitudeKey)
  }
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    let reuseId = "pin"
    
    var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
    
    if pinView == nil {
      pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
      pinView!.canShowCallout = true
      pinView!.pinTintColor = .red
      pinView?.animatesDrop = true
      pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
    }
    else {
      pinView!.annotation = annotation
    }
    
    return pinView
  }
  
  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    if isEditingPins {
      removePin(view.annotation as! VTPointAnnotation)
      mapView.removeAnnotation(view.annotation!)
    }
  }
  
  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    self.performSegue(withIdentifier: PinDetailSegue, sender: view.annotation)
  }
  
}
