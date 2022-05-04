//
//  CustomFeaturedTaskView.swift
//  OCKSample
//
//  Created by Eric Schurr on 5/3/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import UIKit
import CareKitUI
import CareKit

/// A simple subclass to take control of what CareKit already gives us.
 class CustomFeaturedContentView: OCKFeaturedContentView {
     var url: URL?

     // Need to override so we can become delegate when the user taps on card
     override init(imageOverlayStyle: UIUserInterfaceStyle = .unspecified) {
         super.init(imageOverlayStyle: imageOverlayStyle)
         // Need to become a delegate so we know when view is tapped.
         self.delegate = self
     }

     convenience init(url: String, imageOverlayStyle: UIUserInterfaceStyle = .unspecified) {
         self.init(imageOverlayStyle: imageOverlayStyle) // This calls your local init
         self.url = URL(string: url)
         // Need to become a delegate so we know when view is tapped.
         self.delegate = self
     }
 }

 /// Need to conform to delegate in order to be delegated to.
 extension CustomFeaturedContentView: OCKFeaturedContentViewDelegate {

     func didTapView(_ view: OCKFeaturedContentView) {
         // When tapped open a URL.
         guard let url = url else {
             return
         }
         DispatchQueue.main.async {
             UIApplication.shared.open(url)
         }
     }
 }
