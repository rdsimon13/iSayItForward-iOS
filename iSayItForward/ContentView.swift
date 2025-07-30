import SwiftUI

struct ContentView: View {
    var body: some View {
        SignupView { user in
            print("Signed up user: \(user.name), \(user.email)")
            // Navigate or store user info as needed
        }
    }
}
