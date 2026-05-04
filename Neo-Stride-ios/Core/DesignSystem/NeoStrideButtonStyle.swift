import SwiftUI

struct NeoStridePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(NeoStrideColors.accent.opacity(configuration.isPressed ? 0.75 : 1.0))
            .foregroundStyle(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension ButtonStyle where Self == NeoStridePrimaryButtonStyle {
    static var neoStridePrimary: NeoStridePrimaryButtonStyle { NeoStridePrimaryButtonStyle() }
}
