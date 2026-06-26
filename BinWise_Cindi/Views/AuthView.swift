import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.appLanguage) var language

    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var confirmPassword = ""

    private var localError: String? {
        if !isLogin && password != confirmPassword && !confirmPassword.isEmpty {
            return language.text("Passwords do not match.", "两次密码不一致。")
        }
        return nil
    }

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    header
                    if authVM.isLoggedIn {
                        welcomeBackCard
                    } else {
                        modePicker
                        fields
                        if let err = authVM.errorMessage ?? localError {
                            errorBanner(err)
                        }
                        actionButton
                        guestButton
                    }
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.top, DS.Spacing.xxl)
                .padding(.bottom, DS.Spacing.xl)
            }

            if authVM.isLoading {
                loadingOverlay
            }
        }
    }

    // MARK: – Header

    private var header: some View {
        VStack(spacing: DS.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(DS.amberGradient)
                    .frame(width: 64, height: 64)
                Image(systemName: "arrow.3.trianglepath")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            Text("BinWise")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(DS.textPrimary)
            Text(language.text("Smart Waste Sorting", "智能垃圾分类"))
                .font(.subheadline)
                .foregroundColor(DS.textSecondary)
        }
    }

    // MARK: – Welcome back (Firebase already restored a session from disk)

    /// Shown instead of the Sign In/Sign Up form when Firebase has already restored a
    /// persisted session on cold start. Requires an explicit tap before routing to
    /// MainTabView — proves the Firebase session restore is real, not just skipped past.
    private var welcomeBackCard: some View {
        VStack(spacing: DS.Spacing.lg) {
            VStack(spacing: DS.Spacing.xs) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 36))
                    .foregroundColor(DS.statusSuccess)
                Text(language.text("Welcome back!", "欢迎回来！"))
                    .font(.title3.weight(.bold))
                    .foregroundColor(DS.textPrimary)
                if let email = authVM.user?.email, !email.isEmpty {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(DS.textSecondary)
                }
                Text(language.text("Firebase remembered your session.", "Firebase已自动恢复你的登录状态。"))
                    .font(.caption2)
                    .foregroundColor(DS.textTertiary)
            }
            .padding(DS.Spacing.lg)
            .frame(maxWidth: .infinity)
            .cardStyle()

            Button {
                authVM.confirmExistingSession()
            } label: {
                Text(language.text("Continue as \(authVM.user?.firstNameOrEmail ?? "you")",
                                   "以\(authVM.user?.firstNameOrEmail ?? "你")身份继续"))
                    .primaryButtonStyle()
            }

            Button {
                authVM.signOut()
            } label: {
                Text(language.text("Not you? Sign out", "不是你？退出登录"))
                    .font(.subheadline)
                    .foregroundColor(DS.textTertiary)
            }
        }
    }

    // MARK: – Mode picker (Sign In | Sign Up)

    private var modePicker: some View {
        Picker("", selection: $isLogin) {
            Text(language.text("Sign In", "登录")).tag(true)
            Text(language.text("Sign Up", "注册")).tag(false)
        }
        .pickerStyle(.segmented)
        .onChange(of: isLogin) { _ in
            authVM.errorMessage = nil
            confirmPassword = ""
        }
    }

    // MARK: – Fields

    private var fields: some View {
        VStack(spacing: DS.Spacing.sm) {
            if !isLogin {
                inputField(
                    icon: "person",
                    placeholder: language.text("Name (optional)", "姓名（可选）"),
                    text: $displayName
                )
            }
            inputField(
                icon: "envelope",
                placeholder: language.text("Email", "邮箱"),
                text: $email,
                keyboard: .emailAddress
            )
            secureField(
                icon: "lock",
                placeholder: language.text("Password", "密码"),
                text: $password
            )
            if !isLogin {
                secureField(
                    icon: "lock.rotation",
                    placeholder: language.text("Confirm Password", "确认密码"),
                    text: $confirmPassword
                )
            }
        }
    }

    private func inputField(icon: String, placeholder: String,
                            text: Binding<String>,
                            keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(DS.textSecondary)
                .frame(width: 20)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(DS.Spacing.md)
        .background(DS.bgCard)
        .cornerRadius(DS.Radius.control)
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.control).stroke(DS.borderLight, lineWidth: 1))
    }

    private func secureField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(DS.textSecondary)
                .frame(width: 20)
            SecureField(placeholder, text: text)
        }
        .padding(DS.Spacing.md)
        .background(DS.bgCard)
        .cornerRadius(DS.Radius.control)
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.control).stroke(DS.borderLight, lineWidth: 1))
    }

    // MARK: – Error

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.85))
        .cornerRadius(DS.Radius.control)
    }

    // MARK: – Action

    private var actionButton: some View {
        Button {
            Task {
                if isLogin {
                    await authVM.signIn(email: email, password: password)
                } else {
                    guard localError == nil else { return }
                    await authVM.signUp(email: email, password: password, displayName: displayName)
                }
            }
        } label: {
            Text(isLogin
                 ? language.text("Sign In", "登录")
                 : language.text("Sign Up", "注册"))
                .primaryButtonStyle()
        }
        .disabled(email.isEmpty || password.isEmpty || authVM.isLoading)
        .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1)
    }

    // MARK: – Guest

    private var guestButton: some View {
        Button {
            authVM.continueAsGuest()
        } label: {
            Text(language.text("Continue without account →", "以访客身份继续 →"))
                .font(.subheadline)
                .foregroundColor(DS.textTertiary)
        }
    }

    // MARK: – Loading

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.5)
        }
    }
}
