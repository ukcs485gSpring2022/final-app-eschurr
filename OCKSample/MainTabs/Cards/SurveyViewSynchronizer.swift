//
//  SurveyViewSynchronizer.swift
//  OCKSample
//
//  Created by Eric Schurr on 4/20/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import CareKitUI
import ResearchKit
import UIKit
import os.log

final class SurveyViewSynchronizer: OCKSurveyTaskViewSynchronizer {

 override func updateView(
     _ view: OCKInstructionsTaskView,
     context: OCKSynchronizationContext<OCKTaskEvents>) {

     super.updateView(view, context: context)

     if let event = context.viewModel.first?.first, event.outcome != nil {
         view.instructionsLabel.isHidden = false

         let sore = event.answer(kind: Surveys.checkInSoreItemIdentifier)
         let hunger = event.answer(kind: Surveys.checkInHungerItemIdentifier)

         view.instructionsLabel.text = """
             Sore: \(Int(sore))
             Hunger: \(Int(hunger))
             """
     } else {
         view.instructionsLabel.isHidden = true
     }
 }
}
