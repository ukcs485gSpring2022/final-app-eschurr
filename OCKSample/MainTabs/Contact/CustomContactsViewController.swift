//
//  CustomContactsViewController.swift
//  OCKSample
//
//  Created by Eric Schurr on 4/20/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import UIKit
import CareKitStore
import CareKit
import Contacts
import ContactsUI
import ParseSwift
import ParseCareKit
import os.log

class CustomContactsViewController: OCKListViewController {

     fileprivate weak var contactDelegate: OCKContactViewControllerDelegate?
     fileprivate var allContacts = [OCKAnyContact]()
     // fileprivate let appDelegate = UIApplication.shared.delegate as! AppDelegate

     override func viewDidLoad() {
         super.viewDidLoad()

         let searchController = UISearchController(searchResultsController: nil)
         searchController.searchBar.searchBarStyle = UISearchBar.Style.prominent
         searchController.searchBar.placeholder = " Search Contacts"
         searchController.searchBar.showsCancelButton = true
         searchController.searchBar.delegate = self
         navigationItem.searchController = searchController
         definesPresentationContext = true

         navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self,
                                                            action: #selector(presentContactsListViewController))

         Task {
             try? await fetchContacts()
         }
     }

     override func viewDidAppear(_ animated: Bool) {

         Task {
             try? await fetchContacts()
         }
     }

     @objc private func presentContactsListViewController() {

         let contactPicker = CNContactPickerViewController()
         contactPicker.delegate = self
         contactPicker.predicateForEnablingContact = NSPredicate(
           format: "phoneNumbers.@count > 0")
         present(contactPicker, animated: true, completion: nil)
     }

     @objc private func dismissViewController() {
         dismiss(animated: true, completion: nil)
     }

     func clearAndKeepSearchBar() {
         clear()
     }

     @MainActor
     func fetchContacts() async throws {

         var query = OCKContactQuery(for: Date())
         query.sortDescriptors.append(.familyName(ascending: true))
         query.sortDescriptors.append(.givenName(ascending: true))

         guard let contacts = try await
                StoreManagerKey.defaultValue?.store.fetchAnyContacts(query: query) else {
                    Logger.contact.error("Couldn't unwrap")
                    throw AppError.errorString("Couldn't ")
         }

         guard User.current != nil,
               let personUUIDString = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String,
             let convertedContacts = contacts as? [OCKContact] else {
             return
         }

         let filterdContacts = convertedContacts.filter {
             if $0.id == personUUIDString {
                 // Should not show the contact info for this user
                 return false
             }
             return true
         }
         self.clearAndKeepSearchBar()
         self.allContacts = filterdContacts
         self.displayContacts(self.allContacts)

     }

     func displayContacts(_ contacts: [OCKAnyContact]) {
         for contact in contacts {
             guard let synchronizedStoreManager = StoreManagerKey.defaultValue else {
                 return
             }
             let contactViewController = OCKSimpleContactViewController(contact: contact,
                                                                        storeManager: synchronizedStoreManager)
             contactViewController.delegate = self.contactDelegate
             self.appendViewController(contactViewController, animated: false)
         }
     }

     func convertDeviceContacts(_ contact: CNContact) -> OCKAnyContact {

         var convertedContact = OCKContact(id: contact.identifier, givenName: contact.givenName,
                                           familyName: contact.familyName, carePlanUUID: nil)
         convertedContact.title = contact.jobTitle

         var emails = [OCKLabeledValue]()
         contact.emailAddresses.forEach {
             emails.append(OCKLabeledValue(label: $0.label ?? "email", value: $0.value as String))
         }
         convertedContact.emailAddresses = emails

         var phoneNumbers = [OCKLabeledValue]()
         contact.phoneNumbers.forEach {
             phoneNumbers.append(OCKLabeledValue(label: $0.label ?? "phone", value: $0.value.stringValue))
         }
         convertedContact.phoneNumbers = phoneNumbers
         convertedContact.messagingNumbers = phoneNumbers

         if let address = contact.postalAddresses.first {
             convertedContact.address = {
                 let newAddress = OCKPostalAddress()
                 newAddress.street = address.value.street
                 newAddress.city = address.value.city
                 newAddress.state = address.value.state
                 newAddress.postalCode = address.value.postalCode
                 return newAddress
             }()
         }

         return convertedContact
     }
    }

    extension CustomContactsViewController: UISearchBarDelegate {
     func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
         print("Searching text is '\(searchText)'")

         if searchBar.text!.isEmpty {
             // Show all contacts
             clearAndKeepSearchBar()
             displayContacts(allContacts)
             return
         }

         clearAndKeepSearchBar()

         let filteredContacts = allContacts.filter { (contact: OCKAnyContact) -> Bool in

             if contact.name.givenName != nil {
                 return contact.name.givenName!.lowercased().contains(searchText.lowercased())
             } else if contact.name.familyName != nil {
                 return contact.name.familyName!.lowercased().contains(searchText.lowercased())
             } else {
                 return false
             }
         }

         displayContacts(filteredContacts)
     }

     func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
         clearAndKeepSearchBar()
         displayContacts(allContacts)
     }
    }

    extension CustomContactsViewController: OCKContactViewControllerDelegate {
        // swiftlint:disable:next line_length
     func contactViewController<C, VS>(_ viewController: CareKit.OCKContactViewController<C, VS>, didEncounterError error: Error) where C: CareKit.OCKContactController, VS: CareKit.OCKContactViewSynchronizerProtocol {

     }

    }

    extension CustomContactsViewController: CNContactPickerDelegate {

        @MainActor
         func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
             let newContact = convertDeviceContacts(contact)

             if !(self.allContacts.contains {$0.id == newContact.id}) {

                 Task {
                     // Note - once the functionality is added to edit a contact,
                     // and let the user potentially edit the before the save

                     do {
                         _ = try await StoreManagerKey.defaultValue?.store.addAnyContact(newContact)
                         try await fetchContacts()
                     } catch {
                         Logger.contact.error("Couldn't add contact: \(error.localizedDescription)")
                     }
                 }
             }
     }

     func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
         let newContacts = contacts.compactMap { convertDeviceContacts($0) }

         var contactsToAdd = [OCKAnyContact]()
         for newContact in newContacts {
             if !(self.allContacts.contains {$0.id == newContact.id}) {
                 contactsToAdd.append(newContact)
             }
         }

         let immutableContactsToAdd = contactsToAdd

         Task {
             // Note - once the functionality is added to edit a contact,
             // and let the user potentially edit the before the save

             do {
                 _ = try await StoreManagerKey.defaultValue?.store.addAnyContacts(immutableContactsToAdd)
                 try await fetchContacts()
             } catch {
                 Logger.contact.error("Couldn't add contact: \(error.localizedDescription)")
             }
         }

     }
}
