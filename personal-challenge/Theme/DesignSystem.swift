//
//  DesignSystem.swift
//  personal-challenge
//

import SwiftUI

struct AppTheme {
    static let cornerRadius: CGFloat = 16
    
    // Apple native semantic colors
    static let primaryBackground = Color(UIColor.systemGroupedBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let cardBackground = Color(UIColor.tertiarySystemGroupedBackground)
    
    static let accentColor = Color.indigo
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppTheme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

struct PrimaryButtonModifier: ViewModifier {
    var color: Color = AppTheme.accentColor
    var isEnabled: Bool = true
    
    func body(content: Content) -> some View {
        content
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isEnabled ? color : Color(UIColor.systemGray4))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardModifier())
    }
    
    func primaryButtonStyle(color: Color = AppTheme.accentColor, isEnabled: Bool = true) -> some View {
        self.modifier(PrimaryButtonModifier(color: color, isEnabled: isEnabled))
    }
    
    func sectionHeaderStyle() -> some View {
        self
            .font(.system(.title3, design: .rounded).weight(.bold))
            .foregroundStyle(AppTheme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
