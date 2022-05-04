//
//  OCKStore+Default.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore
import Contacts
import os.log
import UIKit
import ParseSwift
import ParseCareKit

extension OCKStore {

    /**
         Adds an `OCKCarePlan`*asynchronously*  to `OCKStore` if it has not been added already.

         - parameter carePlans: The array of `OCKCarePlan`'s to be added to the `OCKStore`.
         - parameter patientUUID: The uuid of the `OCKPatient` to tie to the `OCKCarePlan`. Defaults to nil.
         - throws: An error if there was a problem adding the missing `OCKCarePlan`'s.
         - note: `OCKCarePlan`'s that have an existing `id` will not be added and will not cause errors to be thrown.
    */
    func addCarePlansIfNotPresent(_ carePlans: [OCKCarePlan],
                                  patientUUID: UUID? = nil) async throws {
        let carePlanIdsToAdd = carePlans.compactMap { $0.id }

        // Prepare query to see if carePlans are already added
        var query = OCKCarePlanQuery(for: Date())
        query.ids = carePlanIdsToAdd

        let foundCarePlans = try await fetchCarePlans(query: query)
        var carePlansNotInStore = [OCKCarePlan]()

        // Check results to see if there's a missing carePlan
        carePlans.forEach { potentialCarePlan in
            if foundCarePlans.first(where: { $0.id == potentialCarePlan.id }) == nil {
                var mutableCarePlan = potentialCarePlan
                mutableCarePlan.patientUUID = patientUUID
                carePlansNotInStore.append(mutableCarePlan)

            }
        }

        // Only add if there's a new carePlan
        if carePlansNotInStore.count > 0 {
            do {
                _ = try await addCarePlans(carePlansNotInStore)
                Logger.ockStore.info("Added carePlans into OCKStore!")
            } catch {
                Logger.ockStore.error("Error adding carePlans: \(error.localizedDescription)")
            }
        }
    }

    // Add this method to your app
    @MainActor
    class func getCarePlanUUIDs() async throws -> [CarePlanID: UUID] {
        var results = [CarePlanID: UUID]()

        guard let store = StoreKey.defaultValue else {
            return results
        }

        var query = OCKCarePlanQuery(for: Date())
        query.ids = [CarePlanID.health.rawValue,
                     CarePlanID.checkIn.rawValue]

        let foundCarePlans = try await store.fetchCarePlans(query: query)
        results[CarePlanID.health] = foundCarePlans
            .first(where: { $0.id == CarePlanID.health.rawValue })?.uuid
        results[CarePlanID.checkIn] = foundCarePlans
            .first(where: { $0.id == CarePlanID.checkIn.rawValue })?.uuid
        return results
    }

    func addTasksIfNotPresent(_ tasks: [OCKTask]) async throws {
        let taskIdsToAdd = tasks.compactMap { $0.id }

        // Prepare query to see if tasks are already added
        var query = OCKTaskQuery(for: Date())
        query.ids = taskIdsToAdd

        let foundTasks = try await fetchTasks(query: query)
        var tasksNotInStore = [OCKTask]()

        // Check results to see if there's a missing task
        tasks.forEach { potentialTask in
            if foundTasks.first(where: { $0.id == potentialTask.id }) == nil {
                tasksNotInStore.append(potentialTask)
            }
        }

        // Only add if there's a new task
        if tasksNotInStore.count > 0 {
            do {
                _ = try await addTasks(tasksNotInStore)
                Logger.ockStore.info("Added tasks into OCKStore!")
            } catch {
                Logger.ockStore.error("Error adding tasks: \(error.localizedDescription)")
            }
        }
    }

    func addContactsIfNotPresent(_ contacts: [OCKContact]) async throws {
        let contactIdsToAdd = contacts.compactMap { $0.id }

        // Prepare query to see if contacts are already added
        var query = OCKContactQuery(for: Date())
        query.ids = contactIdsToAdd

        let foundContacts = try await fetchContacts(query: query)
        var contactsNotInStore = [OCKContact]()

        // Check results to see if there's a missing task
        contacts.forEach { potential in
            if foundContacts.first(where: { $0.id == potential.id }) == nil {
                contactsNotInStore.append(potential)
            }
        }

        // Only add if there's a new task
        if contactsNotInStore.count > 0 {
            do {
                _ = try await addContacts(contactsNotInStore)
                Logger.ockStore.info("Added contacts into OCKStore!")
            } catch {
                Logger.ockStore.error("Error adding contacts: \(error.localizedDescription)")
            }
        }
    }

    func populateCarePlans(_ patientUUID: UUID? = nil) async throws {
        let checkInCarePlan = OCKCarePlan(id: CarePlanID.checkIn.rawValue,
                                          title: "Check In",
                                          patientUUID: nil)
        let healthCarePlan = OCKCarePlan(id: CarePlanID.health.rawValue,
                                          title: "Health",
                                          patientUUID: nil)

        try await addCarePlansIfNotPresent([checkInCarePlan, healthCarePlan],
                                           patientUUID: patientUUID)
    }

    // Adds tasks and contacts into the store
    func populateSampleData(_ patientUUID: UUID? = nil) async throws {

        try await populateCarePlans()
        let carePlanUUIDs = try await Self.getCarePlanUUIDs()

        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo)!
        let afterLunch = Calendar.current.date(byAdding: .hour, value: 14, to: aFewDaysAgo)!
        let lunchTime = Calendar.current.date(byAdding: .hour, value: 12, to: aFewDaysAgo)!
        let dinnerTime = Calendar.current.date(byAdding: .hour, value: 18, to: aFewDaysAgo)!
        _ = Calendar.current.date(byAdding: .hour, value: 22, to: aFewDaysAgo)!

        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast, end: nil,
                               interval: DateComponents(day: 1)),

            OCKScheduleElement(start: afterLunch, end: nil,
                               interval: DateComponents(day: 2))
        ])

        let fastingSchedule = OCKSchedule(composing: [
            OCKScheduleElement(start: lunchTime, end: nil,
                               interval: DateComponents(day: 1)),

            OCKScheduleElement(start: dinnerTime, end: nil,
                               interval: DateComponents(day: 2))
        ])

        let vitaminsSchedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast, end: nil,
                               interval: DateComponents(day: 1))

        ])

        let waterSchedule = OCKSchedule(composing: [
            OCKScheduleElement(start: thisMorning, end: nil,
                               interval: DateComponents(day: 1))

        ])

        var doxylamine = OCKTask(id: TaskID.doxylamine, title: "Take ",
                                 carePlanUUID: nil, schedule: schedule)
        doxylamine.instructions = "Take 25mg of doxylamine when you experience nausea."
        doxylamine.asset = "pills.fill"

        var fasting = OCKTask(id: TaskID.fasting, title: "Intermittent Fasting",
                                 carePlanUUID: nil, schedule: fastingSchedule)
        // swiftlint:disable line_length
        fasting.instructions = "Only eat during an 8 hour window to help weight loss. Log your first meal and your second meal (lunch and dinner). Snacking is OK in between!"
        fasting.asset = "meals.fill"

        var vitamins = OCKTask(id: TaskID.vitamins, title: "Take your vitamins every morning!",
                               carePlanUUID: nil, schedule: vitaminsSchedule)
        vitamins.instructions = "Take your multivitamin every morning to promote general health."
        vitamins.asset = "vitamins.fill"

        var water = OCKTask(id: TaskID.water, title: "Water", carePlanUUID: nil, schedule: waterSchedule)

        // swiftlint:disable line_length
        water.instructions = "Drinking water is important for fitness. Log every time you drink a cup of water. Try to drink at least 11 cups every day!"
        water.asset = "water.fill"

        let nauseaSchedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast, end: nil, interval: DateComponents(day: 1),
                               text: "Anytime throughout the day", targetValues: [], duration: .allDay)
            ])

        var nausea = OCKTask(id: TaskID.nausea,
                             title: "Track your nausea",
                             carePlanUUID: carePlanUUIDs[.health],
                             schedule: nauseaSchedule)
        nausea.impactsAdherence = false
        nausea.instructions = "Tap the button below anytime you experience nausea."
        nausea.asset = "bed.double"

        let exerciseElement = OCKScheduleElement(start: beforeBreakfast, end: nil, interval: DateComponents(day: 1), duration: .allDay)
        let exerciseSchedule = OCKSchedule(composing: [exerciseElement])
        var exercise = OCKTask(id: TaskID.exercise, title: "Exercise", carePlanUUID: nil, schedule: exerciseSchedule)
        exercise.impactsAdherence = true
        exercise.instructions = "Try to exercise once a day for 30 minutes!"

        let stretchElement = OCKScheduleElement(start: beforeBreakfast, end: nil, interval: DateComponents(day: 1))
        let stretchSchedule = OCKSchedule(composing: [stretchElement])
        var stretch = OCKTask(id: "stretch", title: "Stretch", carePlanUUID: nil, schedule: stretchSchedule)
        stretch.impactsAdherence = true
        stretch.asset = "figure.walk"

        try await addTasksIfNotPresent([/*nausea, doxylamine,*/ exercise, stretch, fasting, vitamins, water])

        try await addOnboardingTask()
        try await addCheckInSurvey()

        var contact1 = OCKContact(id: "jane", givenName: "Jane",
                                  familyName: "Daniels", carePlanUUID: nil)
        contact1.asset = "JaneDaniels"
        contact1.title = "Family Practice Doctor"
        contact1.role = "Dr. Daniels is a family practice doctor with 8 years of experience."
        contact1.emailAddresses = [OCKLabeledValue(label: CNLabelEmailiCloud, value: "janedaniels@uky.edu")]
        contact1.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(859) 257-2000")]
        contact1.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(859) 357-2040")]

        contact1.address = {
            let address = OCKPostalAddress()
            address.street = "2195 Harrodsburg Rd"
            address.city = "Lexington"
            address.state = "KY"
            address.postalCode = "40504"
            return address
        }()

        var contact2 = OCKContact(id: "matthew", givenName: "Matthew",
                                  familyName: "Reiff", carePlanUUID: nil)
        contact2.asset = "MatthewReiff"
        contact2.title = "OBGYN"
        contact2.role = "Dr. Reiff is an OBGYN with 13 years of experience."
        contact2.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(859) 257-1000")]
        contact2.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(859) 257-1234")]
        contact2.address = {
            let address = OCKPostalAddress()
            address.street = "1000 S Limestone"
            address.city = "Lexington"
            address.state = "KY"
            address.postalCode = "40536"
            return address
        }()

        try await addContactsIfNotPresent([contact1, contact2])
    }

    func addOnboardingTask(_ carePlanUUID: UUID? = nil) async throws {
        let onboardSchedule = OCKSchedule.dailyAtTime(
            hour: 0, minutes: 0,
            start: Date(), end: nil,
            text: "Task Due!",
            duration: .allDay
        )

        var onboardTask = OCKTask(
            id: TaskID.onboarding,
            title: "Onboard",
            carePlanUUID: carePlanUUID,
            schedule: onboardSchedule
        )

        onboardTask.instructions = "You'll need to agree to some terms and conditions before we get started!"
        onboardTask.impactsAdherence = false

        try await addTasksIfNotPresent([onboardTask])
    }

    func addCheckInSurvey(_ carePlanUUID: UUID? = nil) async throws {
        let checkInSchedule = OCKSchedule.dailyAtTime(
            hour: 8, minutes: 0,
            start: Date(), end: nil,
            text: nil
        )

        let checkInTask = OCKTask(
            id: TaskID.checkIn,
            title: "Check In",
            carePlanUUID: carePlanUUID,
            schedule: checkInSchedule
        )

        let thisMorning = Calendar.current.startOfDay(for: Date())

        let nextWeek = Calendar.current.date(
            byAdding: .weekOfYear,
            value: 1,
            to: Date()
        )!

        let nextMonth = Calendar.current.date(
            byAdding: .month,
            value: 1,
            to: thisMorning
        )

        let dailyElement = OCKScheduleElement(
            start: thisMorning,
            end: nextWeek,
            interval: DateComponents(day: 1),
            text: nil,
            targetValues: [],
            duration: .allDay
        )

        let weeklyElement = OCKScheduleElement(
            start: nextWeek,
            end: nextMonth,
            interval: DateComponents(weekOfYear: 1),
            text: nil,
            targetValues: [],
            duration: .allDay
        )

        let rangeOfMotionCheckSchedule = OCKSchedule(
            composing: [dailyElement, weeklyElement]
        )

        let rangeOfMotionCheckTask = OCKTask(
            id: TaskID.rangeOfMotionCheck,
            title: "Range Of Motion",
            carePlanUUID: carePlanUUID,
            schedule: rangeOfMotionCheckSchedule
        )

        try await addTasksIfNotPresent([checkInTask, rangeOfMotionCheckTask])
    }
}
