//
//  OCKAnyEvent+Answer.swift
//  OCKSample
//
//  Created by Eric Schurr on 4/20/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore

extension OCKAnyEvent {

    func answer(kind: String) -> Double {
        let values = outcome?.values ?? []
        let match = values.first(where: { $0.kind == kind })
        return match?.doubleValue ?? 0
    }
}
