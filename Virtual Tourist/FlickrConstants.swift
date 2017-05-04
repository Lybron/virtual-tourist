//
//  FlickrConstants.swift
//  Virtual Tourist
//
//  Created by Lybron Sobers on 3/14/17.
//  Copyright © 2017 Lybron Sobers. All rights reserved.
//

import Foundation

extension FlickrClient {
  
  struct API {
    // MARK: Base URL
    struct BaseURLComponents {
      static let scheme = "https://"
      static let host = "api.flickr.com"
      static let path = "/services/rest"
    }
    
    // MARK: Parameter Keys
    struct ParameterKeys {
      static let method = "method"
      static let apiKey = "api_key"
      static let photoID = "photo_id"
      static let extras = "extras"
      static let format = "format"
      static let noJSONCallback = "nojsoncallback"
      static let safeSearch = "safe_search"
      static let text = "text"
      static let boundingBox = "bbox"
      static let page = "page"
      static let longitude = "lon"
      static let latitude = "lat"
      static let radius = "radius"
      static let radiusUnits = "radius_units"
    }
    
    // MARK: Parameter Values
    struct ParameterValues {
      static let searchMethod = "flickr.photos.search"
      static let getPhotoSizesMethod = "flickr.photos.getSizes"
      static let apiKey = "ca74719098fa1a1d410072187930db3a"
      static let responseFormat = "json"
      static let disableJSONCallback = "1"
      static let mediumURL = "url_m"
      static let useSafeSearch = "1"
      static let radius = "1.6"
      static let radiusUnits = "km"
    }

    // MARK: Response Keys
    struct ResponseKeys {
      static let status = "stat"
      static let photos = "photos"
      static let photo = "photo"
      static let title = "title"
      static let mediumURL = "url_m"
      static let pages = "pages"
      static let total = "total"
    }
    
    // MARK: Response Values
    struct ResponseValues {
      static let okStatus = "ok"
    }    
  }
  
}
