/*
 Copyright (c) 2019, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation
import UIKit
import SwiftUI
import Combine
import CareKit
import CareKitStore
import CareKitUI
import os.log
import ResearchKit

// swiftlint:disable type_body_length
class CareViewController: OCKDailyPageViewController {

    private var isSyncing = false
    private var isLoading = false
    private var cancellables: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh,
                                                            target: self,
                                                            action: #selector(synchronizeWithRemote))

        NotificationCenter.default.addObserver(self, selector: #selector(synchronizeWithRemote),
                                               name: Notification.Name(rawValue: Constants.requestSync),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateSynchronizationProgress(_:)),
                                               name: Notification.Name(rawValue: Constants.progressUpdate),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shouldReload),
                                               name: Notification.Name(rawValue: Constants.reloadView),
                                               object: nil)
    }

    private func observeTask(_ task: OCKTask) {

        storeManager.publisher(forEventsBelongingToTask: task, categories: [.add, .update, .delete])
            .sink { [weak self] in
                Logger.feed.info("Task updated: \($0, privacy: .private)")
                self?.reloadView()
            }
            .store(in: &cancellables)
    }

    private func clearSubscriptions() {
        cancellables = []
    }

    @objc private func updateSynchronizationProgress(_ notification: Notification) {
        guard let receivedInfo = notification.userInfo as? [String: Any],
            let progress = receivedInfo[Constants.progressUpdate] as? Int else {
            return
        }

        switch progress {
        case 0, 100:
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "\(progress)",
                                                                         style: .plain, target: self,
                                                                         action: #selector(self.synchronizeWithRemote))
            }
            if progress == 100 {
                // Let the user see 100
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh,
                                                                             target: self,
                                                                             // swiftlint:disable:next line_length
                                                                             action: #selector(self.synchronizeWithRemote))
                    self.navigationItem.rightBarButtonItem?.tintColor = self.navigationItem.leftBarButtonItem?.tintColor
                }
            }
        default:
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "\(progress)",
                                                                    style: .plain, target: self,
                                                                         action: #selector(self.synchronizeWithRemote))
                self.navigationItem.rightBarButtonItem?.tintColor = TintColorKey.defaultValue
            }
        }
    }

    @MainActor
    @objc private func synchronizeWithRemote() {

        if isSyncing {
            return
        } else {
            isSyncing = true
        }

        DispatchQueue.main.async {

            // swiftlint:disable:next force_cast
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.store?.synchronize { error in

                DispatchQueue.main.async {
                    let errorString = error?.localizedDescription ?? "Successful sync with remote!"
                    Logger.feed.info("\(errorString)")
                    if error != nil {
                        self.navigationItem.rightBarButtonItem?.tintColor = .red
                    } else {
                        // swiftlint:disable:next force_cast
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        if appDelegate.isFirstAppOpen {
                            self.reloadView()
                        }
                        self.isSyncing = false
                    }
                    self.isSyncing = false
                }
            }
        }
    }

    @objc private func shouldReload() {
        reloadView()
    }

    private func reloadView() {
        if isLoading {
            return
        } else {
            isLoading = true
        }
        DispatchQueue.main.async {
            self.reload()
        }
    }

    // This will be called each time the selected date changes.
    // Use this as an opportunity to rebuild the content shown to the user.
    override func dailyPageViewController(_ dailyPageViewController: OCKDailyPageViewController,
                                          prepare listViewController: OCKListViewController, for date: Date) {
        self.clearSubscriptions()

        Task {
            guard await checkIfOnboardingIsComplete() else {

                let onboardCard =
                    OCKSurveyTaskViewController(
                    taskID: TaskID.onboarding,
                    eventQuery: OCKEventQuery(for: date),
                    storeManager: self.storeManager,
                    survey: Surveys.onboardingSurvey(),
                    extractOutcome: { _ in [OCKOutcomeValue(Date())] }
                )

                onboardCard.surveyDelegate = self

                listViewController.appendViewController(
                    onboardCard,
                    animated: false
                )

                return
            }

            let isCurrentDay = Calendar.current.isDate(date, inSameDayAs: Date())

            // Only show the tip view on the current date
            if isCurrentDay {
                if Calendar.current.isDate(date, inSameDayAs: Date()) {
                    let tipTitle = "Why Intermittent Fasting and Exercising?"
                    // swiftlint:disable:next line_length
                    let featuredContent = CustomFeaturedContentView(url: "https://www.healthline.com/health/how-to-exercise-safely-intermittent-fasting#exercising-and-fasting-safely")
                    featuredContent.imageView.image = UIImage(named: "fastingexercising.jpg")
                    featuredContent.label.text = tipTitle
                    featuredContent.label.textColor = .white
                    listViewController.appendView(featuredContent, animated: false)
                }
            }

            Task {
                let tasks = await self.fetchTasks(on: date)
                tasks.compactMap {
                    let cards = self.taskViewController(for: $0, on: date)
                    cards?.forEach {
                        if let carekitView = $0.view as? OCKView {
                            carekitView.customStyle = CustomStyleKey.defaultValue
                        }
                        $0.view.isUserInteractionEnabled = isCurrentDay
                        $0.view.alpha = !isCurrentDay ? 0.4 : 1.0
                    }
                    return cards
                }.forEach { (cards: [UIViewController]) in
                    cards.forEach {
                        listViewController.appendViewController($0, animated: false)
                    }
                }
                self.isLoading = false
            }
        }
    }

    // swiftlint:disable cyclomatic_complexity
    private func taskViewController(for task: OCKAnyTask,
                                    on date: Date) -> [UIViewController]? {

        switch task.id {

        case TaskID.vitamins:
            return [OCKChecklistTaskViewController(
                task: task,
                eventQuery: .init(for: date),
                storeManager: self.storeManager)]

        case TaskID.water:
            return[OCKButtonLogTaskViewController(
                task: task,
                eventQuery: .init(for: date),
                storeManager: self.storeManager)]

        // create a card for intermittent fasting
        case TaskID.fasting:
            return [OCKGridTaskViewController(
                taskID: TaskID.fasting,
                eventQuery: .init(for: date),
                storeManager: self.storeManager)]

        case TaskID.checkIn:
            let checkInCard =
                OCKSurveyTaskViewController(
                taskID: TaskID.checkIn,
                eventQuery: OCKEventQuery(for: date),
                storeManager: self.storeManager,
                survey: Surveys.checkInSurvey(),
                viewSynchronizer: SurveyViewSynchronizer(),
                extractOutcome: Surveys.extractAnswersFromCheckInSurvey
            )
            checkInCard.surveyDelegate = self
            return [checkInCard]

        case TaskID.rangeOfMotionCheck:
            let rangeOfMotionCheckCard =
                OCKSurveyTaskViewController(
                taskID: TaskID.rangeOfMotionCheck,
                eventQuery: OCKEventQuery(for: date),
                storeManager: self.storeManager,
                survey: Surveys.rangeOfMotionCheck(),
                extractOutcome: Surveys.extractRangeOfMotionOutcome
            )
            rangeOfMotionCheckCard.surveyDelegate = self
            return [rangeOfMotionCheckCard]

        case TaskID.mealLinks:
            let view = LinkView(title: Text("Meal Links"),
                                detail: Text("Websites for good, healthy recipes!"),
                                instructions: nil,
                                links: [.website("https://allthehealthythings.com", title: "All The Healthy Things"),
                                        // swiftlint:disable:next line_length
                                        .website("https://www.allrecipes.com/recipes/84/healthy-recipes/", title: "All Recipes"),
                                        .website("https://www.eatingwell.com/recipes/", title: "Eating Well"),
                                        .website("https://healthyrecipesblogs.com", title: "Healthy Recipes")])
                .padding([.vertical], 20)
                .careKitStyle(CustomStyleKey.defaultValue)
            return [view.formattedHostingController()]

        case TaskID.workoutLinks:
            let view = LinkView(title: Text("Workout Links"),
                                detail: Text("Ideas for workouts you could do!"),
                                instructions: nil,
                                links:
                                    // swiftlint:disable:next line_length
                                    [.website("https://www.muscleandfitness.com/workout-plan/workouts/workout-routines/complete-mf-beginners-training-guide-plan/", title: "Beginner Lifting Plan"),
                                     // swiftlint:disable:next line_length
                                        .website("https://greatist.com/fitness/best-cardio-workouts", title: "Cardio Workouts"),
                                     // swiftlint:disable:next line_length
                                        .website("https://www.fatherly.com/health-science/best-damn-bodyweight-workout/", title: "Bodyweight Workouts")])
                .padding([.vertical], 20)
                .careKitStyle(CustomStyleKey.defaultValue)
            return [view.formattedHostingController()]

        case TaskID.steps:
                    let view = NumericProgressTaskView(
                        task: task,
                        eventQuery: OCKEventQuery(for: date),
                        storeManager: self.storeManager)
                        .padding([.vertical], 20)
                        .careKitStyle(CustomStyleKey.defaultValue)

                    return [view.formattedHostingController()]
        case TaskID.stretch:
            return [OCKInstructionsTaskViewController(task: task,
                                                     eventQuery: .init(for: date),
                                                     storeManager: self.storeManager)]

        case TaskID.exercise:
            return [OCKSimpleTaskViewController(task: task,
                                               eventQuery: .init(for: date),
                                               storeManager: self.storeManager)]

        // Create a card for the doxylamine task if there are events for it on this day.
        case TaskID.doxylamine:

            return [OCKChecklistTaskViewController(
                task: task,
                eventQuery: .init(for: date),
                storeManager: self.storeManager)]

        case TaskID.nausea:
            var cards = [UIViewController]()

            // Also create a card that displays a single event.
            // The event query passed into the initializer specifies that only
            // today's log entries should be displayed by this log task view controller.
            let nauseaCard = OCKButtonLogTaskViewController(task: task,
                                                            eventQuery: .init(for: date),
                                                            storeManager: self.storeManager)
            cards.append(nauseaCard)
            return cards

        default:
            return nil
        }
    }
    // swiftlint:enable cyclomatic_complexity

    private func fetchTasks(on date: Date) async -> [OCKAnyTask] {
        var query = OCKTaskQuery(for: date)
        query.excludesTasksWithNoEvents = true
        do {
            let tasks = try await storeManager.store.fetchAnyTasks(query: query)
            let orderedTasks = TaskID.ordered.compactMap { orderedTaskID in
                tasks.first(where: { $0.id == orderedTaskID }) }
            return orderedTasks
        } catch {
            Logger.feed.error("\(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    @MainActor
    private func checkIfOnboardingIsComplete() async -> Bool {

        var query = OCKOutcomeQuery()
        query.taskIDs = [TaskID.onboarding]

        // swiftlint:disable:next force_cast
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        guard let store = appDelegate.store else {
            Logger.feed.error("CareKit store couldn't be unwrapped")
            return false
        }

        do {
            let outcomes = try await
                store.fetchOutcomes(query: query)
            return !outcomes.isEmpty
        } catch {
            return false
        }

    }
}

extension CareViewController: OCKSurveyTaskViewControllerDelegate {
    func surveyTask(
        viewController: OCKSurveyTaskViewController,
        for task: OCKAnyTask,
        didFinish result: Result<ORKTaskViewControllerFinishReason, Error>) {

        if case let .success(reason) = result, reason == .completed {
            reload()
        }
    }

}

private extension View {
    func formattedHostingController() -> UIHostingController<Self> {
        let viewController = UIHostingController(rootView: self)
        viewController.view.backgroundColor = .clear
        return viewController
    }
}
