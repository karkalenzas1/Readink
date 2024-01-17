import SwiftUI
import LocalAuthentication

struct AuthView: View {
    @State private var unlocked = false
    @State private var text = "LOCKED"
    @State private var isAuthenticated = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text(text)
                    .bold()
                    .padding()
                
                Button("Authenticate") {
                    authenticate()
                }
                
                NavigationLink(
                    destination: ContentView(),
                    isActive: $isAuthenticated,
                    label: {
                        EmptyView()
                    })
                    .hidden()
            }
        }
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?

        // Check whether it's possible to use biometric authentication
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {

            // Handle events
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "This is a security check reason.") { success, authenticationError in
                
                if success {
                    text = "UNLOCKED"
                    isAuthenticated = true
                } else {
                    text = "There was a problem!"
                }
            }
        } else {
            text = "Phone does not have biometrics"
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
