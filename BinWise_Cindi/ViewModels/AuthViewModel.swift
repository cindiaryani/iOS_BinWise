import SwiftUI
import FirebaseCore
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var user: UserProfile?
    @Published var isLoggedIn: Bool = false
    @Published var isGuest: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isCheckingAuth: Bool = true
    /// True only after the user explicitly signs in/up/continues-as-guest *in this app
    /// launch*. Firebase silently restores `isLoggedIn` from a persisted session on cold
    /// start, but routing must not skip straight past AuthView because of that — the
    /// user needs to see (and demo) the Sign In screen actually working.
    @Published var sessionConfirmed: Bool = false

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        guard FirebaseApp.app() != nil else {
            isCheckingAuth = false
            return
        }
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }
            if let firebaseUser {
                let localName = UserDefaults.standard.string(forKey: "displayName.\(firebaseUser.uid)")
                self.user = UserProfile(
                    uid: firebaseUser.uid,
                    email: firebaseUser.email ?? "",
                    displayName: firebaseUser.displayName ?? localName,
                    joinDate: firebaseUser.metadata.creationDate ?? Date()
                )
                self.isLoggedIn = true
                self.isGuest = false
            } else {
                self.user = nil
                self.isLoggedIn = false
            }
            self.isCheckingAuth = false
        }
    }

    func signIn(email: String, password: String) async {
        guard FirebaseApp.app() != nil else {
            errorMessage = "Firebase is not configured. Please add GoogleService-Info.plist."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                Auth.auth().signIn(withEmail: email, password: password) { _, error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume() }
                }
            }
            sessionConfirmed = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUp(email: String, password: String, displayName: String) async {
        guard FirebaseApp.app() != nil else {
            errorMessage = "Firebase is not configured. Please add GoogleService-Info.plist."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                Auth.auth().createUser(withEmail: email, password: password) { result, error in
                    if let error {
                        cont.resume(throwing: error)
                        return
                    }
                    if let result, !displayName.isEmpty {
                        // Firestore isn't wired up yet — persist displayName locally too,
                        // keyed by uid, so it survives even before Firebase's profile syncs.
                        UserDefaults.standard.set(displayName, forKey: "displayName.\(result.user.uid)")
                        let req = result.user.createProfileChangeRequest()
                        req.displayName = displayName
                        req.commitChanges { _ in cont.resume() }
                    } else {
                        cont.resume()
                    }
                }
            }
            sessionConfirmed = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Called when the user taps "Continue as [name]" on AuthView's welcome-back card —
    /// confirms a Firebase session that was already restored from disk on cold start.
    func confirmExistingSession() {
        sessionConfirmed = true
    }

    func signOut() {
        guard FirebaseApp.app() != nil else { return }
        try? Auth.auth().signOut()
        isGuest = false
        sessionConfirmed = false
    }

    func continueAsGuest() {
        isGuest = true
        isLoggedIn = false
        isCheckingAuth = false
        sessionConfirmed = true
    }
}
