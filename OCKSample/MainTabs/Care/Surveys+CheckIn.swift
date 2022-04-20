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
    static let checkInPainItemIdentifier = "checkin.form.pain"
    static let checkInSleepItemIdentifier = "checkin.form.sleep"

    static func checkInSurvey() -> ORKTask {

        let painAnswerFormat = ORKAnswerFormat.scale(
            withMaximumValue: 10,
            minimumValue: 1,
            defaultValue: 0,
            step: 1,
            vertical: false,
            maximumValueDescription: "Very painful",
            minimumValueDescription: "No pain"
        )

        let painItem = ORKFormItem(
            identifier: checkInPainItemIdentifier,
            text: "How would you rate your pain?",
            answerFormat: painAnswerFormat
        )
        painItem.isOptional = false

        let sleepAnswerFormat = ORKAnswerFormat.scale(
            withMaximumValue: 12,
            minimumValue: 0,
            defaultValue: 0,
            step: 1,
            vertical: false,
            maximumValueDescription: nil,
            minimumValueDescription: nil
        )

        let sleepItem = ORKFormItem(
            identifier: checkInSleepItemIdentifier,
            text: "How many hours of sleep did you get last night?",
            answerFormat: sleepAnswerFormat
        )
        sleepItem.isOptional = false

        let formStep = ORKFormStep(
            identifier: checkInFormIdentifier,
            title: "Check In",
            text: "Please answer the following questions."
        )
        formStep.formItems = [painItem, sleepItem]
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

            let painAnswer = scaleResults
                .first(where: { $0.identifier == checkInPainItemIdentifier })?
                .scaleAnswer,

            let sleepAnswer = scaleResults
                .first(where: { $0.identifier == checkInSleepItemIdentifier })?
                .scaleAnswer
        else {
            assertionFailure("Failed to extract answers from check in survey!")
            return nil
        }

        var painValue = OCKOutcomeValue(Double(truncating: painAnswer))
        painValue.kind = checkInPainItemIdentifier

        var sleepValue = OCKOutcomeValue(Double(truncating: sleepAnswer))
        sleepValue.kind = checkInSleepItemIdentifier

        return [painValue, sleepValue]
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
