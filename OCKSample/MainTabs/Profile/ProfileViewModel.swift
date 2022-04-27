//
//  Profile.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKit
import CareKitStore
import SwiftUI
import ParseCareKit
import UIKit
import os.log
import Combine
import ParseSwift

// swiftlint:disable type_body_length

class ProfileViewModel: ObservableObject {

    @Published var patient: OCKPatient?
    @Published var contact: OCKContact?
    @Published var sex: OCKBiologicalSex = .other("unspecified")
    @Published var isShowingSaveAlert = false
    @Published var isLoggedOut = false {
        willSet {
            if newValue {
                error = nil
                patient = nil
                contact = nil
                sex = .other("unspecified")
                clearSubscriptions()
            }
        }
    }
    @Published public internal(set) var error: Error?
    @Published var profileUIImage = UIImage(systemName: "person.fill") {
        willSet {
            guard self.profileUIImage != newValue,
                let inputImage = newValue else {
                return
            }

            if !settingProfilePictureForFirstTime {
                guard var user = User.current?.mergeable,
                      let image = inputImage.jpegData(compressionQuality: 0.25) else {
                    return
                }

                let newProfilePicture = ParseFile(name: "profile.jpg", data: image)
                user.profilePicture = newProfilePicture
                let userToSave = user
                Task {
                    do {
                        _ = try await userToSave.save()
                        Logger.profile.info("Saved updated profile picture successfully.")
                    } catch {
                        Logger.profile.error("Couldn't save profile picture: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private(set) var storeManager: OCKSynchronizedStoreManager?
    private var cancellables: Set<AnyCancellable> = []
    private var settingProfilePictureForFirstTime = true

    init() {
        reloadViewModel()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadViewModel),
                                               name: Notification.Name(rawValue: Constants.reloadView),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(replaceStore),
                                               name: Notification.Name(rawValue: Constants.storeInitialized),
                                               object: nil)
    }

    // MARK: Helpers

    @objc private func reloadViewModel() {
        Task {
            _ = await findAndObserveCurrentProfile()
        }
    }

    @MainActor
    @objc private func replaceStore() {
        guard let currentStore = StoreManagerKey.defaultValue else { return }
        storeManager = currentStore
        reloadViewModel()
    }

    func refreshViewIfNeeded() {
        if cancellables.count == 0 {
            reloadViewModel()
        }
    }

    @MainActor
    private func fetchProfilePicture() async throws {

         // Profile pics are stored in Parse User.
        guard let currentUser = try await User.current?.fetch() else {
            Logger.profile.error("User isn't logged in")
            return
        }

        if let pictureFile = currentUser.profilePicture {

            // Download picture from server
            do {
                let profilePicture = try await pictureFile.fetch()
                guard let path = profilePicture.localURL?.relativePath else {
                    return
                }
                self.profileUIImage = UIImage(contentsOfFile: path)
            } catch {
                Logger.profile.error("Couldn't fetch profile picture: \(error.localizedDescription).")
            }
        }
        self.settingProfilePictureForFirstTime = false
    }

    @MainActor
    private func findAndObserveCurrentProfile() async {

        guard let uuid = Self.getRemoteClockUUIDAfterLoginFromLocalStorage() else {
            return
        }

        clearSubscriptions()

        // Build query to search for OCKPatient
        // swiftlint:disable:next line_length
        var queryForCurrentPatient = OCKPatientQuery(for: Date()) // This makes the query for the current version of Patient
        queryForCurrentPatient.ids = [uuid.uuidString] // Search for the current logged in user

        do {
            // swiftlint:disable:next force_cast
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            guard let foundPatient = try await appDelegate.store?.fetchPatients(query: queryForCurrentPatient),
                let currentPatient = foundPatient.first else {
                // swiftlint:disable:next line_length
                Logger.profile.error("Error: Couldn't find patient with id \"\(uuid)\". It's possible they have never been saved.")
                return
            }
            self.observePatient(currentPatient)

            // Query the contact also so the user can edit
            var queryForCurrentContact = OCKContactQuery(for: Date())
            queryForCurrentContact.ids = [uuid.uuidString]

            guard let foundContact = try await appDelegate.store?.fetchContacts(query: queryForCurrentContact),
                let currentContact = foundContact.first else {
                // swiftlint:disable:next line_length
                Logger.profile.error("Error: Couldn't find contact with id \"\(uuid)\". It's possible they have never been saved.")
                return
            }
            self.observeContact(currentContact)

            try? await fetchProfilePicture()
        } catch {
            // swiftlint:disable:next line_length
            Logger.profile.error("Error: Couldn't find patient with id \"\(uuid)\". It's possible they have never been saved. Query error: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func observePatient(_ patient: OCKPatient) {

        storeManager?.publisher(forPatient: patient, categories: [.add, .update, .delete])
            .sink { [weak self] in
                self?.patient = $0 as? OCKPatient
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func observeContact(_ contact: OCKContact) {

        storeManager?.publisher(forContact: contact, categories: [.add, .update, .delete])
            .sink { [weak self] in
                self?.contact = $0 as? OCKContact
            }
            .store(in: &cancellables)
    }

    private func clearSubscriptions() {
        cancellables = []
    }

    static func getRemoteClockUUIDAfterLoginFromLocalStorage() -> UUID? {
        guard let uuid = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String else {
            return nil
        }

        return UUID(uuidString: uuid)
    }

    static func getRemoteClockUUIDAfterLoginFromCloud() async throws -> UUID {

        guard let lastUserTypeSelected = User.current?.lastTypeSelected,
              let remoteClockUUID = User.current?.userTypeUUIDs?[lastUserTypeSelected] else {
                  throw AppError.remoteClockIDNotAvailable
              }
        return remoteClockUUID
    }

    @MainActor
    static func setupRemoteAfterLoginButtonTapped() async throws {

        let remoteUUID = try await Self.getRemoteClockUUIDAfterLoginFromCloud()

        // Save remote ID to local
        UserDefaults.standard.setValue(remoteUUID.uuidString, forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()

        do {
            try LoginViewModel.setDefaultACL()
        } catch {
            Logger.profile.error("Couldn't set defaultACL: \(error.localizedDescription)")
        }

        // Importing UIKit gives us access here to get the OCKStore and ParseRemote
        // swiftlint:disable:next force_cast
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.setupRemotes(uuid: remoteUUID)
        appDelegate.parseRemote.automaticallySynchronizes = true

        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        return
    }

    // MARK: User intentions
    @MainActor
    func saveProfile(_ first: String,
                     last: String,
                     birth: Date,
                     sex: OCKBiologicalSex,
                     note: String) async throws {

        isShowingSaveAlert = true // Make alert pop up for user.
        if var patientToUpdate = patient {
            // If there is a currentPatient that was fetched, check to see if any of the fields changed

            var patientHasBeenUpdated = false

            if patient?.name.givenName != first {
                patientHasBeenUpdated = true
                patientToUpdate.name.givenName = first
            }

            if patient?.name.familyName != last {
                patientHasBeenUpdated = true
                patientToUpdate.name.familyName = last
            }

            if patient?.birthday != birth {
                patientHasBeenUpdated = true
                patientToUpdate.birthday = birth
            }

            if patient?.sex != sex {
                patientHasBeenUpdated = true
                patientToUpdate.sex = sex
            }

            let notes = [OCKNote(author: first, title: "my note", content: note)]
            if patient?.notes != notes {
                patientHasBeenUpdated = true
                patientToUpdate.notes = notes
            }

            if patientHasBeenUpdated {
                let updated = try await storeManager?.store.updateAnyPatient(patientToUpdate)
                Logger.profile.info("Successfully updated patient")
                guard let updatedPatient = updated as? OCKPatient else {
                    return
                }
                self.patient = updatedPatient
            }

        } else {
            // swiftlint:disable:next line_length
            guard let remoteUUID = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String else {
                Logger.profile.error("Error: The user currently isn't logged in")
                isLoggedOut = true
                return
            }

            var newPatient = OCKPatient(id: remoteUUID, givenName: first, familyName: last)
            newPatient.birthday = birth

            // This is new patient that has never been saved before
            let new = try await storeManager?.store.addAnyPatient(newPatient)
            Logger.profile.info("Succesffully saved new patient")
            guard let newPatient = new as? OCKPatient else {
                return
            }
            self.patient = newPatient
        }
    }

    @MainActor
    func saveContact(_ street: String,
                     city: String,
                     state: String,
                     zipcode: String) async throws {

        /*
         TODo: Be sure to this methods to save changes properly to OCKContact.
         */

        guard let remoteUUID = Self.getRemoteClockUUIDAfterLoginFromLocalStorage()?.uuidString else {
            Logger.profile.error("Error: The user currently isn't logged in")
            isLoggedOut = true
            return
        }

        if var contactToUpdate = contact {
            // If there is a currentContact that was fetched, check to see if any of the fields changed

            var contactHasBeenUpdated = false

            // Since OCKPatient was updated earlier, we should compare against this name
            if let patientName = patient?.name,
                contact?.name != patient?.name {
                contactHasBeenUpdated = true
                contactToUpdate.name = patientName
            }

            // Create a mutable temp address to compare
            let potentialAddress = OCKPostalAddress()
            potentialAddress.street = street
            potentialAddress.city = city
            potentialAddress.state = state
            potentialAddress.postalCode = zipcode

            if contact?.address != potentialAddress {
                contactHasBeenUpdated = true
                contactToUpdate.address = potentialAddress
            }

            if contactHasBeenUpdated {
                let updated = try await storeManager?.store.updateAnyContact(contactToUpdate)
                Logger.profile.info("Successfully updated contact")
                guard let updatedContact = updated as? OCKContact else {
                    return
                }
                self.contact = updatedContact
            }

        } else {

            guard let patientName = self.patient?.name else {
                Logger.profile.info("The patient didn't have a name.")
                return
            }

            // Added code to create a contact for the respective signed up user
            let newContact = OCKContact(id: remoteUUID,
                                        name: patientName,
                                        carePlanUUID: nil)

            // This is new contact that has never been saved before
            _ = try await storeManager?.store.addAnyContact(newContact)
        }
    }

    @MainActor
    static func savePatientAfterSignUp(_ type: UserType, first: String, last: String) async throws -> OCKPatient {

        let remoteUUID = UUID()

        // Save remote ID locally
        UserDefaults.standard.setValue(remoteUUID.uuidString, forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()

        do {
            try LoginViewModel.setDefaultACL()
        } catch {
            Logger.profile.error("Couldn't set defaultACL: \(error.localizedDescription)")
        }

        // swiftlint:disable:next force_cast
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.setupRemotes(uuid: remoteUUID)
        let storeManager = appDelegate.storeManager

        var newPatient = OCKPatient(remoteUUID: remoteUUID,
                                    id: remoteUUID.uuidString,
                                    givenName: first,
                                    familyName: last)
        newPatient.userType = type
        let savedPatient = try await storeManager.store.addAnyPatient(newPatient)
        guard let patient = savedPatient as? OCKPatient else {
            throw AppError.couldntCast
        }

        // Added code to create a contact for the respective signed up user
        let newContact = OCKContact(id: remoteUUID.uuidString,
                                    name: newPatient.name,
                                    carePlanUUID: nil)

        // This is new contact that has never been saved before
        _ = try await storeManager.store.addAnyContact(newContact)

        try await appDelegate.store?.populateSampleData()
        try await appDelegate.healthKitStore.populateSampleData(patient.uuid)
        appDelegate.parseRemote.automaticallySynchronizes = true

        // Post notification to sync
        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        Logger.profile.info("Successfully added a new Patient")
        return patient
    }

    // You may not have seen "throws" before, but it's simple,
    // this throws an error if one occurs, if not it behaves as normal
    // Normally, you've seen do {} catch{} which catches the error, same concept...
    @MainActor
    func logout() async {
        do {
            try await User.logout()
        } catch {
            Logger.profile.error("Error logging out: \(error.localizedDescription)")
        }
        UserDefaults.standard.removeObject(forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()

        // swiftlint:disable:next force_cast
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.resetAppToInitialState()
        isLoggedOut = true
    }
}
