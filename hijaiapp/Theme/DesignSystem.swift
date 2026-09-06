//
//  DesignSystem.swift
//  personal-challenge
//

import SwiftUI

enum AppThemeMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var iconName: String {
        switch self {
        case .system: return "circle.righthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

struct AppTheme {
    static let cornerRadius: CGFloat = 16
    
    static let primaryBackground = Color(UIColor.systemGroupedBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let cardBackground = Color(UIColor.tertiarySystemGroupedBackground)
    
    static let accentColor = Color.indigo
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
}

struct CardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppTheme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .shadow(
                color: colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.04),
                radius: 8,
                x: 0,
                y: 4
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.03),
                        lineWidth: 1
                    )
            )
    }
}

struct PrimaryButtonModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var color: Color = AppTheme.accentColor
    var isEnabled: Bool = true
    
    func body(content: Content) -> some View {
        content
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isEnabled ? color : (colorScheme == .dark ? Color(UIColor.systemGray5) : Color(UIColor.systemGray4)))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ThemeMenuButton: View {
    @AppStorage("selectedThemeMode") private var themeMode: AppThemeMode = .system
    
    var body: some View {
        Menu {
            Picker("Appearance", selection: $themeMode) {
                ForEach(AppThemeMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.iconName)
                        .tag(mode)
                }
            }
        } label: {
            Image(systemName: themeMode.iconName)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.accentColor)
        }
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
