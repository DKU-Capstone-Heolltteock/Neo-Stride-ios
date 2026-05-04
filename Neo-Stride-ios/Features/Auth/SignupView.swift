import SwiftUI

struct SignupView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("회원가입")
                .font(.largeTitle.bold())
                .foregroundStyle(NeoStrideColors.primaryText)

            VStack(spacing: 14) {
                TextField("이메일", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(NeoStrideColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                TextField("이름", text: $viewModel.name)
                    .padding(14)
                    .background(NeoStrideColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                SecureField("비밀번호", text: $viewModel.password)
                    .padding(14)
                    .background(NeoStrideColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(NeoStrideColors.warning)
            }

            Button(viewModel.isLoading ? "처리 중..." : "가입하기") {
                Task {
                    if await viewModel.signup() {
                        dismiss()
                    }
                }
            }
            .buttonStyle(.neoStridePrimary)
            .disabled(viewModel.isLoading)

            Spacer()
        }
        .padding(24)
        .background(NeoStrideColors.background.ignoresSafeArea())
    }
}
