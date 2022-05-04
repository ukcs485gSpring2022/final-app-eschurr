//
//  InsightsView.swift
//  OCKSample
//
//  Created by Eric Schurr on 5/3/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

/*
  You should notice this looks like CareView but with references
  to InsightsViewController instead.
 */

 import SwiftUI
 import UIKit
 import CareKit
 import CareKitStore
 import os.log

 struct InsightsView: UIViewControllerRepresentable {

     @ObservedObject var viewModel = InsightsViewModel()

     @MainActor
     func makeUIViewController(context: Context) -> some UIViewController {
         let viewController = createViewContoller()
         let navigationController = UINavigationController(rootViewController: viewController)
         navigationController.navigationBar.backgroundColor = UIColor { $0.userInterfaceStyle == .light ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1): #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) }

         return navigationController
     }

     @MainActor
     func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
         // swiftlint:disable:next force_cast
         let appDelegate = UIApplication.shared.delegate as! AppDelegate

         if appDelegate.isFirstLogin && appDelegate.isFirstAppOpen {
             guard let navigationController = uiViewController as? UINavigationController,
                     let currentViewController = navigationController.viewControllers.first as? InsightsViewController,
                   appDelegate.storeManager !== currentViewController.storeManager  else {
                 return
             }
             // Replace current view controller
             let viewController = createViewContoller()
             navigationController.viewControllers = [viewController]
         }
     }

     // MARK: Helpers
     func createViewContoller() -> UIViewController {
         guard let manager = StoreManagerKey.defaultValue else {
             Logger.insights.error("Couldn't unwrap storeManager")
             return InsightsViewController(storeManager: .init(wrapping: OCKStore(name: "none_insights",
                                                                                  type: .inMemory)))
         }
         return InsightsViewController(storeManager: manager)
     }
 }

 struct InsightsView_Previews: PreviewProvider {

     static var previews: some View {
         InsightsView()
     }
 }
