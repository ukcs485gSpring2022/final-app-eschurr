//
//  InsightsViewController.swift
//  OCKSample
//
//  Created by Eric Schurr on 5/3/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

/*
  You should notice this looks like CareView and MyContactView combined,
  but only shows charts instead.
 */

 import UIKit
 import CareKitStore
 import CareKitUI
 import CareKit
 import ParseSwift
 import ParseCareKit
 import os.log

 class InsightsViewController: OCKListViewController {

     /// The manager of the `Store` from which the `Contact` data is fetched.
     public let storeManager: OCKSynchronizedStoreManager

     /// Initialize using a store manager. All of the contacts in the store manager will be queried and dispalyed.
     ///
     /// - Parameters:
     ///   - storeManager: The store manager owning the store whose contacts should be displayed.
     public init(storeManager: OCKSynchronizedStoreManager) {
         self.storeManager = storeManager
         super.init(nibName: nil, bundle: nil)
     }

     @available(*, unavailable)
     public required init?(coder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }

     override func viewDidLoad() {
         super.viewDidLoad()

         navigationItem.title = "Insights"

         Task {
             await displayTasks(Date())
         }
     }

     override func viewDidAppear(_ animated: Bool) {
         Task {
             await displayTasks(Date())
         }
     }

     override func appendViewController(_ viewController: UIViewController, animated: Bool) {
         super.appendViewController(viewController, animated: animated)

         // Make sure this contact card matches app style when possible
         if let carekitView = viewController.view as? OCKView {
             carekitView.customStyle = CustomStyleKey.defaultValue
         }
     }

     @MainActor
     func fetchTasks(on date: Date) async -> [OCKAnyTask] {
         var query = OCKTaskQuery(for: date)
         query.excludesTasksWithNoEvents = true
         do {
             let tasks = try await storeManager.store.fetchAnyTasks(query: query)
             let orderedTasks = TaskID.ordered.compactMap { orderedTaskID in
                 tasks.first(where: { $0.id == orderedTaskID }) }
             return orderedTasks
         } catch {
             Logger.insights.error("\(error.localizedDescription, privacy: .public)")
             return []
         }
     }

     func taskViewController(for task: OCKAnyTask,
                             on date: Date) -> [UIViewController]? {
         switch task.id {

         case TaskID.vitamins:

             let vitaminsGradientStart = GraphColorKey.defaultValue
             let vitaminsGradientEnd = TintColorKey.defaultValue

             let vitaminDataSeries = OCKDataSeriesConfiguration(
                 taskID: TaskID.vitamins,
                 legendTitle: "Vitamins",
                 gradientStartColor: vitaminsGradientStart,
                 gradientEndColor: vitaminsGradientEnd,
                 markerSize: 5,
                 eventAggregator: eventAggregatorMean)

             let insightsCard = OCKCartesianChartViewController(
                 plotType: .scatter,
                 selectedDate: date,
                 configurations: [vitaminDataSeries],
                 storeManager: self.storeManager)

             insightsCard.chartView.headerView.titleLabel.text = "Did you take your mulitvitamin?"
             insightsCard.chartView.headerView.detailLabel.text = "This Week"
             insightsCard.chartView.headerView.accessibilityLabel = "Vitamin usage, this week"

             return [insightsCard]

         case TaskID.water:

             let waterGradientStart = GraphColorKey.defaultValue
             let waterGradientEnd = TintColorKey.defaultValue

             let waterDataSeries = OCKDataSeriesConfiguration(
                 taskID: TaskID.water,
                 legendTitle: "Water",
                 gradientStartColor: waterGradientStart,
                 gradientEndColor: waterGradientEnd,
                 markerSize: 5,
                 eventAggregator: eventAggregatorMean)

             let insightsCard = OCKCartesianChartViewController(
                 plotType: .line,
                 selectedDate: date,
                 configurations: [waterDataSeries],
                 storeManager: self.storeManager)

             insightsCard.chartView.headerView.titleLabel.text = "Average cups of water"
             insightsCard.chartView.headerView.detailLabel.text = "This Week"
             insightsCard.chartView.headerView.accessibilityLabel = "Water intake, this week"

             return [insightsCard]

         case TaskID.checkIn:

             // dynamic gradient colors
             let checkInGradientStart = GraphColorKey.defaultValue
             let checkInGradientEnd = TintColorKey.defaultValue

             /*
              Note that that there's a small bug for the check in graph because
              it averages all of the "Pain + Sleep" hours. This okay for now. If
              you are collecting ResearchKit input that only collects 1 value per
              survey, you won't have this problem.
              */
             let checkInDataSeries = OCKDataSeriesConfiguration(
                 taskID: TaskID.checkIn,
                 legendTitle: "Check In",
                 gradientStartColor: checkInGradientStart,
                 gradientEndColor: checkInGradientEnd,
                 markerSize: 10,
                 eventAggregator: eventAggregatorMean)

             let insightsCard = OCKCartesianChartViewController(
                 plotType: .bar,
                 selectedDate: date,
                 configurations: [checkInDataSeries],
                 storeManager: self.storeManager)

             insightsCard.chartView.headerView.titleLabel.text = "Average Check In's"
             insightsCard.chartView.headerView.detailLabel.text = "This Week"
             insightsCard.chartView.headerView.accessibilityLabel = "Average Check In's, This Week"

             return [insightsCard]

         case TaskID.nausea:
             var cards = [UIViewController]()
             // dynamic gradient colors
             let nauseaGradientStart = UIColor { traitCollection -> UIColor in
                 return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0.06253327429, green: 0.6597633362, blue: 0.8644603491, alpha: 1) : #colorLiteral(red: 0, green: 0.2858072221, blue: 0.6897063851, alpha: 1)
             }
             let nauseaGradientEnd = TintColorKey.defaultValue

             // Create a plot comparing nausea to medication adherence.
             let nauseaDataSeries = OCKDataSeriesConfiguration(
                 taskID: TaskID.nausea,
                 legendTitle: "Nausea",
                 gradientStartColor: nauseaGradientStart,
                 gradientEndColor: nauseaGradientEnd,
                 markerSize: 10,
                 eventAggregator: OCKEventAggregator.countOutcomeValues)

             let doxylamineDataSeries = OCKDataSeriesConfiguration(
                 taskID: TaskID.doxylamine,
                 legendTitle: "Doxylamine",
                 gradientStartColor: .systemGray2,
                 gradientEndColor: .systemGray,
                 markerSize: 10,
                 eventAggregator: OCKEventAggregator.countOutcomeValues)

             let insightsCard = OCKCartesianChartViewController(
                 plotType: .bar,
                 selectedDate: date,
                 configurations: [nauseaDataSeries, doxylamineDataSeries],
                 storeManager: self.storeManager)

             insightsCard.chartView.headerView.titleLabel.text = "Nausea & Doxylamine Intake"
             insightsCard.chartView.headerView.detailLabel.text = "This Week"
             insightsCard.chartView.headerView.accessibilityLabel = "Nausea & Doxylamine Intake, This Week"
             cards.append(insightsCard)

             return cards

         default:
             return nil
         }
     }

     @MainActor
     func displayTasks(_ date: Date) async {

         let tasks = await fetchTasks(on: date)
         self.clear() // Clear after pulling tasks from database

         tasks.compactMap {
             let cards = self.taskViewController(for: $0, on: date)
             cards?.forEach {
                 if let carekitView = $0.view as? OCKView {
                     carekitView.customStyle = CustomStyleKey.defaultValue
                 }
             }
             return cards
         }.forEach { (cards: [UIViewController]) in
             cards.forEach {
                 self.appendViewController($0, animated: false)
             }
         }
     }
 }
