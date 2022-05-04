<!--
Name of your final project
-->
# final-app-eschurr
![Swift](https://img.shields.io/badge/swift-5.5-brightgreen.svg) ![Xcode 13.2+](https://img.shields.io/badge/xcode-13.2%2B-blue.svg) ![iOS 15.0+](https://img.shields.io/badge/iOS-15.0%2B-blue.svg) ![watchOS 8.0+](https://img.shields.io/badge/watchOS-8.0%2B-blue.svg) ![CareKit 2.1+](https://img.shields.io/badge/CareKit-2.1%2B-red.svg) ![ci](https://github.com/netreconlab/CareKitSample-ParseCareKit/workflows/ci/badge.svg?branch=main)

## Description
<!--
Give a short description on what your project accomplishes and what tools is uses. Basically, what problems does it solve and why it's different from other apps in the app store.
-->
My project attempts to combine a unique diet plan (intermittent fasting) with other elements of important health routines, such as drinking water, taking vitamins, exercising, and more. Intermittent fasting while exercising is a proven and great way to lose weight fast, but it can be difficult without having a guide. This application takes all the different tools one would want to use to get fit and puts them all into one unique place.

### Demo Video
<!--
Add the public link to your YouTube or video posted elsewhere.
-->
To learn more about this application, watch the video below:

<a href="http://www.youtube.com/watch?feature=player_embedded&v=d_3NYs5H5JA
" target="_blank"><img src="http://img.youtube.com/vi/d_3NYs5H5JA/0.jpg" 
alt="SurelyFit Demo Video" width="240" height="180" border="10" /></a>

### Designed for the following users
<!--
Describe the types of users your app is designed for and who will benefit from your app.
-->
My project is built for users who want to get healthy. When I have been trying to lose weight and get stronger at the same time, it’s been frustrating to have to use two separate apps. You'd need one app for working out, then have to use another app that provides features like entering meals and tracking nutrients. The idea for this app is to combine both of those into one single app to use seamlessly together and make your weight loss/fitness/muscle gaining journey much easier and less confusing. More importantly, it will help people understand how those two things can go hand in hand.
<!--
In addition, you can drop screenshots directly into your README file to add them to your README. Take these from your presentations.
-->

<img src="https://user-images.githubusercontent.com/82740749/166621740-3c6cbec7-ea53-4ce7-a253-e674d6453bc8.png" width="200"> <img src="https://user-images.githubusercontent.com/82740749/166622000-6987fe28-238a-455a-a410-51bb6e5ca4ac.png" width="200"> <img src="https://user-images.githubusercontent.com/82740749/166622032-40a8f706-7fcb-4581-bf48-33163892e754.png" width = "200"> <img src="https://user-images.githubusercontent.com/82740749/166622050-f8c6625e-1868-45dc-ad98-3b97009ea0d0.png" width="200"> <img src="https://user-images.githubusercontent.com/82740749/166622062-5ff38d8e-7a76-4da8-a4fc-e949846e86f9.png" width="200"> <img src="https://user-images.githubusercontent.com/82740749/166622067-20b6e4fe-05e5-4bdc-aeca-642b7c82e472.png" width="200"> <img src="https://user-images.githubusercontent.com/82740749/166622070-ec04dcac-cc4e-4a34-a219-c05ef52bd7c5.png" width="200"> <img src="https://user-images.githubusercontent.com/82740749/166622078-216dbc53-e979-4ba0-a7a1-37c22bbd96c4.png" width="200"> <img src="https://user-images.githubusercontent.com/82740749/166622085-59e9b9be-aa9d-4ede-8863-4e065ba737ad.png" width = "200">


<!--
List all of the members who developed the project and
link to each members respective GitHub profile
-->
Developed by: 
- [Eric Schurr](https://github.com/eschurr) - `University of Kentucky`, `Computer Science`

ParseCareKit synchronizes the following entities to Parse tables/classes using [Parse-Swift](https://github.com/parse-community/Parse-Swift):

- [x] OCKTask <-> Task
- [x] OCKHealthKitTask <-> HealthKitTask 
- [x] OCKOutcome <-> Outcome
- [x] OCKRevisionRecord.KnowledgeVector <-> Clock
- [x] OCKPatient <-> Patient
- [x] OCKCarePlan <-> CarePlan
- [x] OCKContact <-> Contact

**Use at your own risk. There is no promise that this is HIPAA compliant and we are not responsible for any mishandling of your data**

<!--
What features were added by you, this should be descriptions of features added from the [Code](https://uk.instructure.com/courses/2030626/assignments/11151475) and [Demo](https://uk.instructure.com/courses/2030626/assignments/11151413) parts of the final. Feel free to add any figures that may help describe a feature. Note that there should be information here about how the OCKTask/OCKHealthTask's and OCKCarePlan's you added pertain to your app.
-->
## Contributions/Features
- CustomFeaturedContentView that subclasses OCKFeaturedContentView, providing a link that explains to the user what Intermittent Fasting is, how to do it, and why it could be beneficial.
- A check-on Research Kit survey displayed by OCKSurveyTaskViewController that asks the user about their soreness and hunger levels. Hopefully, as they continue the program, they should see that their day-to-day soreness and hunger slowly decrease as they get used to their routine.
- OCKTask vitamins displayed by OCKChecklistTaskViewController to remind users to take their vitamins in the morning.
- OCKTask water displayed by OCKButtonLogTaskViewController to have users log every cup of water drank throughout the day.
- OCKTask fasting displayed by OCKGridTaskViewController to help users track their fasting habits and remind them when their meals should be eaten.
- Range of motion check 
- OCKTask exercise displayed by OCKSimpleTaskViewController that is used by the user to log thier 30+ minute exercise every day.
- LinkViews for meal links and workout links the user can use for healthy meals and good workout plans.
- New tab called "Insights" to MainTabView that displays graphs for the data the user is logging, such as soreness+hunger, vitamins, and water.
- A searchable contact view and a profile view as a form.
- Improved styling and custom logo.
## Final Checklist
<!--
This is from the checkist from the final [Code](https://uk.instructure.com/courses/2030626/assignments/11151475). You should mark completed items with an x and leave non-completed items empty
-->
- [x] Signup/Login screen tailored to app
- [x] Signup/Login with email address
- [x] Custom app logo
- [x] Custom styling
- [x] Add at least **5 new OCKTask/OCKHealthKitTasks** to your app
  - [x] Have a minimum of 7 OCKTask/OCKHealthKitTasks in your app
  - [x] 3/7 of OCKTasks should have different OCKSchedules than what's in the original app
- [x] Use at least 5/7 card below in your app
  - [x] InstructionsTaskView - typically used with a OCKTask
  - [x] SimpleTaskView - typically used with a OCKTask
  - [x] Checklist - typically used with a OCKTask
  - [x] Button Log - typically used with a OCKTask
  - [x] GridTaskView - typically used with a OCKTask
  - [x] NumericProgressTaskView (SwiftUI) - typically used with a OCKHealthKitTask
  - [ ] LabeledValueTaskView (SwiftUI) - typically used with a OCKHealthKitTask
- [x] Add the LinkView (SwiftUI) card to your app
- [x] Replace the current TipView with a class with CustomFeaturedContentView that subclasses OCKFeaturedContentView. This card should have an initializer which takes any link
- [x] Tailor the ResearchKit Onboarding to reflect your application
- [x] Add tailored check-in ResearchKit survey to your app
- [x] Add a new tab called "Insights" to MainTabView
- [x] Replace current ContactView with Searchable contact view
- [x] Change the ProfileView to use a Form view
- [x] Add at least two OCKCarePlan's and tie them to their respective OCKTask's and OCContact's 

## Wishlist features
<!--
Describe at least 3 features you want to add in the future before releasing your app in the app-store
-->
1. Integration of workout plans and live workout guides into the application so users don't have to switch to another application to use a workout guide
2. Integration of a meal database that can be displayed in the application that generates recipes for users
3. Calorie tracking

## Challenges faced while developing
<!--
Describe any challenges you faced with learning Swift, your baseline app, or adding features. You can describe how you overcame them.
-->
This was one of the tougher programming projects I have worked on. The MVVM architectural pattern is not something I have used before, along with Swift, so the first few months invovled a lot of steep learning curves, followed by the last month or so trying to integrate all of it into a real-time application. Adding different OCKTasks/OCKHealthKit tasks and trying to remember everywhere that these interactions had to occur for it to display and store the data in my application was a definite challenge.

## Setup Your Parse Server

### Heroku
The easiest way to setup your server is using the [one-button-click](https://github.com/netreconlab/parse-hipaa#heroku) deplyment method for [parse-hipaa](https://github.com/netreconlab/parse-hipaa).


## View your data in Parse Dashboard

### Heroku
The easiest way to setup your dashboard is using the [one-button-click](https://github.com/netreconlab/parse-hipaa-dashboard#heroku) deplyment method for [parse-hipaa-dashboard](https://github.com/netreconlab/parse-hipaa-dashboard).
