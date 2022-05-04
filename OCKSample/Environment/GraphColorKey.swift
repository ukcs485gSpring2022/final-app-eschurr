//
//  GraphColorKey.swift
//  OCKSample
//
//  Created by Eric Schurr on 5/3/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI

struct GraphColorKey: EnvironmentKey {

    static var defaultValue: UIColor {
        #if os(iOS)
        return UIColor { $0.userInterfaceStyle == .light ?  #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1) : #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1) }
        #else
        return #colorLiteral(red: 0, green: 0.2855202556, blue: 0.6887390018, alpha: 1)
        #endif
    }
}

extension EnvironmentValues {

    var graphColor: UIColor {
        self[GraphColorKey.self]
    }
}
