//
//  Surveys+CheckIn.swift
//  OCKSample
//
//  Created by Eric Schurr on 4/20/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import ResearchKit

extension Surveys {
// MARK: Check-in Survey
    static let checkInIdentifier = "checkin"
    static let checkInFormIdentifier = "checkin.form"
    static let checkInSoreItemIdentifier = "checkin.form.sore"
    static let checkInHungerItemIdentifier = "checkin.form.hunger"

    static func checkInSurvey() -> ORKTask {

        let soreAnswerFormat = ORKAnswerFormat.scale(
            withMaximumValue: 10,
            minimumValue: 1,
            defaultValue: 0,
            step: 1,
            vertical: false,
            maximumValueDescription: "Very sore",
            minimumValueDescription: "Not sore"
        )

        let soreItem = ORKFormItem(
            identifier: checkInSoreItemIdentifier,
            text: "How would you rate your soreness?",
            answerFormat: soreAnswerFormat
        )
        soreItem.isOptional = false

        let hungerAnswerFormat = ORKAnswerFormat.scale(
            withMaximumValue: 10,
            minimumValue: 0,
            defaultValue: 0,
            step: 1,
            vertical: false,
            maximumValueDescription: "Very hungry",
            minimumValueDescription: "Not hungry"
        )

        let hungerItem = ORKFormItem(
            identifier: checkInHungerItemIdentifier,
            text: "How hungry were you during your fasting hours yesterday?",
            answerFormat: hungerAnswerFormat
        )
        hungerItem.isOptional = false

        let formStep = ORKFormStep(
            identifier: checkInFormIdentifier,
            title: "Check In",
            text: "Please answer the following questions."
        )
        formStep.formItems = [soreItem, hungerItem]
        formStep.isOptional = false

        let surveyTask = ORKOrderedTask(
            identifier: checkInIdentifier,
            steps: [formStep]
        )

        return surveyTask
    }

    static func extractAnswersFromCheckInSurvey(
        _ result: ORKTaskResult) -> [OCKOutcomeValue]? {

        guard
            let response = result.results?
                .compactMap({ $0 as? ORKStepResult })
                .first(where: { $0.identifier == checkInFormIdentifier }),

            let scaleResults = response
                .results?.compactMap({ $0 as? ORKScaleQuestionResult }),

            let soreAnswer = scaleResults
                .first(where: { $0.identifier == checkInSoreItemIdentifier })?
                .scaleAnswer,

            let hungerAnswer = scaleResults
                .first(where: { $0.identifier == checkInHungerItemIdentifier })?
                .scaleAnswer
        else {
            assertionFailure("Failed to extract answers from check in survey!")
            return nil
        }

        var soreValue = OCKOutcomeValue(Double(truncating: soreAnswer))
        soreValue.kind = checkInSoreItemIdentifier

        var hungerValue = OCKOutcomeValue(Double(truncating: hungerAnswer))
        hungerValue.kind = checkInHungerItemIdentifier

        return [soreValue, hungerValue]
    }

    // MARK: Range of Motion.
    static func rangeOfMotionCheck() -> ORKTask {

        let rangeOfMotionOrderedTask = ORKOrderedTask.kneeRangeOfMotionTask(
            withIdentifier: "rangeOfMotionTask",
            limbOption: .left,
            intendedUseDescription: nil,
            options: [.excludeConclusion]
        )

        let completionStep = ORKCompletionStep(identifier: "rom.completion")
        completionStep.title = "All done!"
        completionStep.detailText = "We know the road to recovery can be tough. Keep up the good work!"

        rangeOfMotionOrderedTask.appendSteps([completionStep])

        return rangeOfMotionOrderedTask
    }

    static func extractRangeOfMotionOutcome(
        _ result: ORKTaskResult) -> [OCKOutcomeValue]? {

        guard let motionResult = result.results?
            .compactMap({ $0 as? ORKStepResult })
            .compactMap({ $0.results })
            .flatMap({ $0 })
            .compactMap({ $0 as? ORKRangeOfMotionResult })
            .first else {

            assertionFailure("Failed to parse range of motion result")
            return nil
        }

        var range = OCKOutcomeValue(motionResult.range)
        range.kind = #keyPath(ORKRangeOfMotionResult.range)

        return [range]
    }
}
