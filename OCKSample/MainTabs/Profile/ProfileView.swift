//
//  ProfileView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import CareKitUI
import CareKitStore
import CareKit
import os.log

// swiftlint:disable multiple_closures_with_trailing_closure

struct ProfileView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.tintColor) private var tintColor
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var userStatus: UserStatus
    @State var firstName = ""
    @State var lastName = ""
    @State var birthday = Calendar.current.date(byAdding: .year, value: -20, to: Date())!

    @State var note = ""
    @State var sex = OCKBiologicalSex.other("unspecified")
    @State private var sexOtherField = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipcode = ""
    @State var showContact = false
    @State var showingImagePicker = false

    var body: some View {

        NavigationView {
            VStack {
                /*NavigationLink(isActive: $showContact,
                               destination: {
                    MyContactView()
                        .navigationBarTitle("My Contact Card")
                }) {
                    EmptyView()
                }*/
                if let image = profileViewModel.profileUIImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100, alignment: .center)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                        .overlay(Circle().stroke(Color(tintColor), lineWidth: 5))
                        .onTapGesture {
                            self.showingImagePicker = true
                        }
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100, alignment: .center)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                        .overlay(Circle().stroke(Color(tintColor), lineWidth: 5))
                        .onTapGesture {
                            self.showingImagePicker = true
                        }
                }

                VStack {
                    Form {
                        Section(header: Text("About")) {
                            TextField("First Name", text: $firstName)
                            TextField("Last Name", text: $lastName)
                            TextField("Note", text: $note)
                            DatePicker("Birthday",
                                       selection: $birthday,
                                       displayedComponents: [DatePickerComponents.date])

                            Picker(selection: $sex, label: Text("Sex"), content: {
                                Text(OCKBiologicalSex.female.rawValue).tag(OCKBiologicalSex.female)
                                Text(OCKBiologicalSex.male.rawValue).tag(OCKBiologicalSex.male)
                                TextField("Other", text: $sexOtherField).tag(OCKBiologicalSex.other(sexOtherField))
                            })
                        }

                        Section(header: Text("Contact")) {
                            TextField("Street", text: $street)
                            TextField("City", text: $city)
                            TextField("State", text: $state)
                            TextField("Postal code", text: $zipcode)
                        }
                    }

                    // Notice that "action" is a closure (which is essentially
                    // a function as argument like we discussed in class)
                    Button(action: {

                        Task {
                            do {
                                try await profileViewModel.saveProfile(firstName,
                                                                       last: lastName,
                                                                       birth: birthday,
                                                                       sex: sex,
                                                                       note: note)
                                try await profileViewModel.saveContact(street,
                                                                       city: city,
                                                                       state: state,
                                                                       zipcode: zipcode)
                            } catch {
                                Logger.profile.error("Error saving profile: \(error.localizedDescription)")
                            }
                        }

                    }, label: {

                        Text("Save Profile")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 50)
                    })
                    .background(Color(.green))
                    .cornerRadius(15)

                    // Notice that "action" is a closure (which is essentially
                    // a function as argument like we discussed in class)
                    Button(action: {
                        Task {
                            await profileViewModel.logout()
                        }

                    }, label: {

                        Text("Log Out")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 50)
                    })
                    .background(Color(.red))
                    .cornerRadius(15)
                }

                Spacer()
            }
            .navigationBarItems(trailing:
                             Button(action: {
                                 self.showContact = true
                             }) {
                                 Text("My Contact")
                             })
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $profileViewModel.profileUIImage)
        }
        .onReceive(profileViewModel.$patient, perform: { patient in
            // TODo: Be sure to update this list so changes are reflected in the view.
            if let currentFirstName = patient?.name.givenName {
                firstName = currentFirstName
            } else {
                /*
                 Else statements are default for when the view resets. For example,
                 when you logout and then login as a different user.
                 */
                firstName = ""
            }

            if let currentLastName = patient?.name.familyName {
                lastName = currentLastName
            } else {
                lastName = ""
            }

            if let currentBirthday = patient?.birthday {
                birthday = currentBirthday
            } else {
                birthday = Calendar.current.date(byAdding: .year, value: -20, to: Date())!
            }

            if let currentNote = patient?.notes?.first?.content {
                note = currentNote
            } else {
                note = ""
            }

            if let currentSex = patient?.sex {
                sex = currentSex
            } else {
                sex = OCKBiologicalSex.other("unspecified")
            }
        })
        .onReceive(profileViewModel.$contact, perform: { contact in
            // TODo: Be sure to update this list so changes are reflected in the view.
            if let currentStreet = contact?.address?.street {
                street = currentStreet
            } else {
                street = ""
            }

            if let currentCity = contact?.address?.city {
                city = currentCity
            } else {
                city = ""
            }

            if let currentState = contact?.address?.state {
                state = currentState
            } else {
                state = ""
            }

            if let currentZipcode = contact?.address?.postalCode {
                zipcode = currentZipcode
            } else {
                zipcode = ""
            }
        })
        .alert(isPresented: $profileViewModel.isShowingSaveAlert) {
            return Alert(title: Text("Update"),
                         message: Text("All changs saved successfully!"),
                         dismissButton: .default(Text("Ok"), action: {
                            profileViewModel.isShowingSaveAlert = false
                            self.presentationMode.wrappedValue.dismiss()
                         }))
        }.onReceive(profileViewModel.$isLoggedOut, perform: { value in
            if self.userStatus.isLoggedOut != value {
                self.userStatus.check()
        }
        }).onAppear(perform: {
            profileViewModel.refreshViewIfNeeded()
        })
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(UserStatus(isLoggedOut: false))
            .environmentObject(ProfileViewModel())
    }
}
