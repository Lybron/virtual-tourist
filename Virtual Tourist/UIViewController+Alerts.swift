//
//  UIViewController+Alerts.swift
//  Virtual Tourist
//
//  Created by Lybron Sobers on 3/14/17.
//  Copyright © 2017 Lybron Sobers. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
  func showError(_ error: NSError) {
    let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
    present(alertController, animated: true, completion: nil)
  }
}
