import SwiftUI

struct LoginView: View {
    @StateObject var viewModel: AuthViewModel
    @State private var showingSignup = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Neo-Stride")
                        .font(.largeTitle.bold())
                        .foregroundStyle(NeoStrideColors.primaryText)
                    Text("러닝 기록과 AI 코칭을 시작하세요")
                        .foregroundStyle(NeoStrideColors.secondaryText)
                }

                VStack(spacing: 14) {
                    TextField("이메일", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .neoStrideTextField()

                    SecureField("비밀번호", text: $viewModel.password)
                        .textContentType(.password)
                        .neoStrideTextField()

                    Toggle("로그인 유지", isOn: $viewModel.keepLogin)
                        .tint(NeoStrideColors.accent)
                        .foregroundStyle(NeoStrideColors.secondaryText)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(NeoStrideColors.warning)
                }

                Button(viewModel.isLoading ? "로그인 중..." : "로그인") {
                    Task { await viewModel.login() }
                }
                .buttonStyle(.neoStridePrimary)
                .disabled(viewModel.isLoading)

                Button("회원가입") {
                    showingSignup = true
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(NeoStrideColors.accent)

                Spacer()
            }
            .padding(24)
            .background(NeoStrideColors.background.ignoresSafeArea())
            .navigationDestination(isPresented: $showingSignup) {
                SignupView(viewModel: viewModel)
            }
        }
    }
}

private extension View {
    func neoStrideTextField() -> some View {
        self
            .padding(14)
            .background(NeoStrideColors.surface)
            .foregroundStyle(NeoStrideColors.primaryText)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
