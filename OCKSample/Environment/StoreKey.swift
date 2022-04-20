//
//  StoreKey.swift
//  OCKSample
//
//  Created by Eric Schurr on 4/20/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI
import CareKitStore

struct StoreKey: EnvironmentKey {

    static var defaultValue: OCKStore? {
        // swiftlint:disable:next force_cast
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.store
    }
}

extension EnvironmentValues {

    var store: OCKStore? {
        get {
            self[StoreKey.self]
        }

        set {
            self[StoreKey.self] = newValue
        }
    }
}
