// MIT License
//
// Copyright (c) 2016-present, Approov Ltd.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files
// (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
// ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH
// THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit
import ApproovService

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize the Approov auto service layer as early as possible in the launch path:
        // every URLSession-based HTTP client created afterwards is protected automatically —
        // the rest of the app keeps using plain URLSession with no Approov-specific types.
        // An empty config string selects bypass mode, so a clean checkout remains runnable.
        // CI and local simulator/device runs can inject test-only values as launch environment
        // variables without committing account configuration or development keys.
        let environment = ProcessInfo.processInfo.environment
        do {
            try ApproovService.initialize(environment["APPROOV_CONFIG"] ?? "")
        } catch {
            NSLog("Approov initialization failed: \(error.localizedDescription)")
            return false
        }

        if let developmentKey = environment["APPROOV_DEV_KEY"], !developmentKey.isEmpty {
            ApproovService.setDevKey(developmentKey)
        }

        if environment["APPROOV_ENABLE_MESSAGE_SIGNING"] == "1" {
            ApproovService.setServiceMutator(
                ApproovDefaultMessageSigning().setDefaultFactory(
                    ApproovDefaultMessageSigning.generateDefaultSignatureParametersFactory()))
        }

        if environment["APPROOV_ENABLE_SECRET_SUBSTITUTION"] == "1" {
            ApproovService.addSubstitutionHeader("Api-Key")
        }

#if DEBUG
        if environment["APPROOV_LOG_DIAGNOSTICS"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                let diagnostics = ApproovService.getInterceptionDiagnostics()
                NSLog("Approov diagnostics: forwarded=\(diagnostics.requestsForwarded) " +
                      "pinAllowed=\(diagnostics.pinnedChallengesAllowed) " +
                      "pinBlocked=\(diagnostics.pinnedChallengesBlocked) " +
                      "delegated=\(diagnostics.delegatedChallenges)")
            }
        }
#endif

        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}
