//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Lybron Sobers on 3/14/17.
//  Copyright © 2017 Lybron Sobers. All rights reserved.
//

import UIKit
import CoreData

struct FlickrClient {
  
  public static let shared = FlickrClient()
  
  // MARK: Fetch Photos
  public func getPhotosForLocation(_ pin: Pin, context: NSManagedObjectContext, completion: @escaping (_ finished: Bool?, _ error: NSError?) -> Void) {
    
    let params = [
      FlickrClient.API.ParameterKeys.apiKey:FlickrClient.API.ParameterValues.apiKey,
      FlickrClient.API.ParameterKeys.method:FlickrClient.API.ParameterValues.searchMethod,
      FlickrClient.API.ParameterKeys.format:FlickrClient.API.ParameterValues.responseFormat,
      FlickrClient.API.ParameterKeys.noJSONCallback:FlickrClient.API.ParameterValues.disableJSONCallback,
      FlickrClient.API.ParameterKeys.latitude: "\(pin.latitude)",
      FlickrClient.API.ParameterKeys.longitude: "\(pin.longitude)",
      FlickrClient.API.ParameterKeys.radius: FlickrClient.API.ParameterValues.radius,
      FlickrClient.API.ParameterKeys.radiusUnits:FlickrClient.API.ParameterValues.radiusUnits]
    
    let url = flickrURLFrom(parameters: params)
    let request = URLRequest(url: url)
    let task = URLSessionDataTask.task(request: request) { (data, error) in
      
      guard error == nil else {
        completion(nil, NSError(domain: "FlickrClient.getPhotosForLocation", code: 1, userInfo: [NSLocalizedDescriptionKey: VTNetworkError.requestError.rawValue]))
        return
      }
      
      guard let data = data else {
        completion(nil, NSError(domain: "FlickrClient.getPhotoPhotosForLocation", code: 1, userInfo: [NSLocalizedDescriptionKey: VTNetworkError.noDataError.rawValue]))
        return
      }
      
      guard let photosDictionary = self.parseData(data) as? [String:AnyObject], let photoSet = photosDictionary["photos"] as? [String:AnyObject] else {
        return
      }
      
      guard let photo = photoSet["photo"] as? [[String:AnyObject]] else {
        return
      }
      
      let dispatchGroup = DispatchGroup()
      
      let limit = min(30, photo.count)
      
      for index in 0...limit {
        if limit <= index { break }
        
        let p = photo[index]
        
        if let photoID = p["id"] as? String {
          let placeholderImage = UIImage(named: "pointer-100")
          let placeholderData = UIImagePNGRepresentation(placeholderImage!)
          let placholderPhoto = Photo(photoData: placeholderData! as NSData, context: context)
          placholderPhoto.pin = pin
          
          dispatchGroup.enter()
          
          self.getPhotoURL(photo: placholderPhoto, id: photoID, context: context, group: dispatchGroup) { (group, success, error) in
            
            guard error == nil else {
              return
            }
            
            if let group = group { group.leave() }
            
            dispatchGroup.leave()

          }
          
        }
        
      }
      
      dispatchGroup.notify(queue: DispatchQueue.main, execute: {
        completion(true, nil)
      })
      
    }
    
    task.resume()
  }
  
  private func getPhotoURL(photo: Photo, id: String, context: NSManagedObjectContext, group: DispatchGroup, completion: @escaping (_ group: DispatchGroup?, _ success: Bool, _ error: NSError?) -> Void) {
    
    let params = [
      FlickrClient.API.ParameterKeys.apiKey:FlickrClient.API.ParameterValues.apiKey,
      FlickrClient.API.ParameterKeys.method:FlickrClient.API.ParameterValues.getPhotoSizesMethod,
      FlickrClient.API.ParameterKeys.format:FlickrClient.API.ParameterValues.responseFormat,
      FlickrClient.API.ParameterKeys.noJSONCallback:FlickrClient.API.ParameterValues.disableJSONCallback,
      FlickrClient.API.ParameterKeys.photoID: id]
    
    let url = flickrURLFrom(parameters: params)
    let request = URLRequest(url: url)
    let task = URLSessionDataTask.task(request: request) { (data, error) in
      guard error == nil else {
        completion(group, false, NSError(domain: "FlickrClient.fetchPhoto", code: 1, userInfo: [NSLocalizedDescriptionKey: VTNetworkError.requestError.rawValue]))
        return
      }
      
      guard let data = data else {
        completion(group, false, NSError(domain: "FlickrClient.fetchPhoto", code: 1, userInfo: [NSLocalizedDescriptionKey: VTNetworkError.noDataError.rawValue]))
        return
      }
      
      guard let object = self.parseData(data) as? [String:AnyObject], let sizes = object["sizes"] as? [String:AnyObject], let size = sizes["size"] as? [[String:AnyObject]] else {
        return
      }
      
      let largeSquare = size[1]
      
      if let source = largeSquare["source"] as? String {
        
        group.enter()
        
        self.fetchPhoto(photo: photo, url: source, context: context, group: group, completion: { (group,success, error) in
          
          if let group = group { group.leave() }
          
          guard error == nil else {
            completion(group, false, error!)
            return
          }
          
          completion(group, true, nil)
        })
      }

    }
    
    task.resume()
  }
  
  private func fetchPhoto(photo: Photo, url: String, context: NSManagedObjectContext, group: DispatchGroup, completion: @escaping (_ group: DispatchGroup?, _ success: Bool, _ error: NSError?) -> Void) {
    
    guard let url = URL(string: url) else {
      completion(group, false, NSError(domain: "FlickrClient.fetchPhoto", code: 1, userInfo: [NSLocalizedDescriptionKey:VTNetworkError.requestError.rawValue]))
      return
    }
    
    let request = URLRequest(url: url)
    
    group.enter()
    
    let task = URLSessionDataTask.task(request: request) { (data, error) in
      
      guard error == nil else {
        completion(group, false, NSError(domain: "FlickrClient.fetchPhoto", code: 1, userInfo: [NSLocalizedDescriptionKey:VTNetworkError.requestError.rawValue]))
        return
      }
      
      guard let data = data else {
        completion(group, false, NSError(domain: "FlickrClient.fetchPhoto", code: 1, userInfo: [NSLocalizedDescriptionKey:VTNetworkError.requestError.rawValue]))
        return
      }
      
      photo.photoData = data as NSData
      
      do {
        try context.save()
      } catch {
        print("photo could not be saved")
      }
      
      completion(group, true, nil)
      
    }
    
    task.resume()
  }
  
  // MARK: Flickr URL
  private func flickrURLFrom(parameters: [String:String]) -> URL {
    let url = URL.from(
      scheme: FlickrClient.API.BaseURLComponents.scheme,
      host: FlickrClient.API.BaseURLComponents.host,
      path: FlickrClient.API.BaseURLComponents.path,
      parameters: parameters)
    
    return url
  }
  
  // MARK: Parse Data
  private func parseData(_ data: Data) -> AnyObject? {
    do {
      let parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
      return parsedData
    } catch {
      return nil
    }
  }
  
  // MARK: Privatize init
  private init() {}

}
