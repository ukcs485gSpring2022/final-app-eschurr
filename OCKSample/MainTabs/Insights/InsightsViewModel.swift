//
//  InsightsViewModel.swift
//  OCKSample
//
//  Created by Eric Schurr on 5/3/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

 /*
  You should notice this looks like CareViewModel.
 */

 class InsightsViewModel: ObservableObject {
     @Published var update = false

     init() {
         NotificationCenter.default.addObserver(self, selector: #selector(reloadViewModel),
                                                name: Notification.Name(rawValue: Constants.storeInitialized),
                                                object: nil)
     }

     // MARK: Helpers
     @objc private func reloadViewModel() {
         update = !update
     }
 }
