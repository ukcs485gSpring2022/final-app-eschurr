//
//  Constants.swift
//  OCKSample
//
//  Created by Corey Baker on 11/27/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKit
import CareKitStore
import ParseSwift
import os.log

enum AppError: Error {
    case couldntCast
    case couldntBeUnwrapped
    case valueNotFoundInUserInfo
    case remoteClockIDNotAvailable
    case emptyTaskEvents
    case invalidIndexPath(_ indexPath: IndexPath)
    case noOutcomeValueForEvent(_ event: OCKAnyEvent, _ index: Int)
    case cannotMakeOutcomeFor(_ event: OCKAnyEvent)
    case parseError(_ error: ParseError)
    case error(_ error: Error)
    case errorString(_ string: String)
}

extension AppError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .couldntCast:
            return NSLocalizedString("OCKSampleError: Couldn't cast to required type.",
                                     comment: "Casting error")
        case .couldntBeUnwrapped:
            return NSLocalizedString("OCKSampleError: Couldn't unwrap a required type.",
                                     comment: "Unwrapping error")
        case .valueNotFoundInUserInfo:
            return NSLocalizedString("OCKSampleError: Couldn't find the required value in userInfo.",
                                     comment: "Value not found error")
        case .remoteClockIDNotAvailable:
            return NSLocalizedString("OCKSampleError: Couldn't get remote clock ID.",
                                     comment: "Value not available error")
        case .emptyTaskEvents: return "Task events is empty"
        case let .noOutcomeValueForEvent(event, index): return "Event has no outcome value at index \(index): \(event)"
        case .invalidIndexPath(let indexPath): return "Invalid index path \(indexPath)"
        case .cannotMakeOutcomeFor(let event): return "Cannot make outcome for event: \(event)"
        case .parseError(let error): return "\(error)"
        case .error(let error): return "\(error)"
        case .errorString(let string): return string
        }
    }
}

enum Constants {
    static let parseConfigFileName = "ParseCareKit"
    static let parseUserSessionTokenKey = "requestParseSessionToken"
    static let parseRemoteClockIDKey = "requestRemoteClockID"
    static let requestSync = "requestSync"
    static let reloadView = "reloadView"
    static let progressUpdate = "progressUpdate"
    static let userLoggedIn = "userLoggedIn"
    static let storeInitialized = "storeInitialized"
    static let storeDeinitialized = "storeDeinitialized"
    static let userTypeKey = "userType"
}

enum CarePlanID: String {
    case health
    case checkIn
}

enum TaskID {
    static let doxylamine = "doxylamine"
    static let nausea = "nausea"
    static let stretch = "stretch"
    static let kegels = "kegels"
    static let steps = "steps"
    static let fasting = "fasting"
    static let onboarding = "onboarding"
    static let checkIn = "checkIn"
    static let rangeOfMotionCheck = "rangeOfMotionCheck"
    static let mealLinks = "mealLinks"
    static let vitamins = "vitamins"
    static let water = "water"
    static let workoutLinks = "workoutLinks"

    static var ordered: [String] {
        [Self.vitamins,
         Self.water,
         Self.steps,
         Self.mealLinks,
         Self.workoutLinks,
         Self.fasting,
         Self.checkIn,
         Self.rangeOfMotionCheck,
         Self.doxylamine,
         Self.kegels,
         Self.stretch,
         Self.nausea
         ]
    }
}

enum UserType: String, Codable {
    case patient                           = "Patient"
    case none                              = "None"

    // Return all types as an array, make sure to maintain order above
    func allTypesAsArray() -> [String] {
        return [UserType.patient.rawValue,
                UserType.none.rawValue]
    }
}

enum InstallationChannel: String {
    case global
}

let eventAggregatorMean = OCKEventAggregator.custom { events -> Double in

     let totalCompleted = Double(events.map { $0.outcome?.values.count ?? 0 }.reduce(0, +))

     Logger.constants.debug("Total \(totalCompleted)")

     let tempSumOfCompleted = events.compactMap { $0.outcome?.values.compactMap { $0.doubleValue ?? 0.0 }.reduce(0, +) }
     Logger.constants.debug("TempSum \(tempSumOfCompleted)")
     let sumOfCompleted = Double(tempSumOfCompleted.compactMap { $0 }.reduce(0, +))
     Logger.constants.debug("Sum \(sumOfCompleted)")

     if totalCompleted == 0 {
         return Double(0)
     } else {
         return  sumOfCompleted / totalCompleted
     }
 }
