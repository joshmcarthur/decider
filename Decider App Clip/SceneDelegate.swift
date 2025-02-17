import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: ClipView())
        self.window = window
        window.makeKeyAndVisible()
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // Handle shared content
        if userActivity.activityType == "com.apple.sharing",
           let sharedText = userActivity.userInfo?["content"] as? String {

            // Create a new activity with our custom type
            let newActivity = NSUserActivity(activityType: "com.joshmcarthur.listdecider.Decider.Clip.share")
            newActivity.userInfo = ["sharedText": sharedText]

            // Set it as the scene's activity
            if let windowScene = scene as? UIWindowScene {
                windowScene.userActivity = newActivity
            }
        }
    }
}