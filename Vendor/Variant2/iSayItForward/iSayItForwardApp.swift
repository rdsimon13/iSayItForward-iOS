import SwiftUI

@main
struct iSayItForwardApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      WelcomeView()
    }
  }
}
