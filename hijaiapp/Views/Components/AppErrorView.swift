//
//  AppErrorView.swift
//  hijaiapp
//
//  Created by Raka Febrian Syahputra on 06/09/26.
//

import SwiftUI

struct AppErrorView: View {
    let title: String
    let message: String
    var iconName: String = "exclamationmark.triangle.fill"
    var iconColor: Color = .orange
    var primaryActionTitle: String? = "Try Again"
    var primaryAction: (() -> Void)? = nil
    var secondaryActionTitle: String? = nil
    var secondaryAction: (() -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 72, height: 72)
                
                Image(systemName: iconName)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .ignore)
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                Text(message)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 16)
            }
            
            VStack(spacing: 8) {
                if let primaryTitle = primaryActionTitle, let action = primaryAction {
                    Button(action: action) {
                        Text(primaryTitle)
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(AppTheme.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .accessibilityHint("Double tap to \(primaryTitle.lowercased())")
                }
                
                if let secondaryTitle = secondaryActionTitle, let action = secondaryAction {
                    Button(action: action) {
                        Text(secondaryTitle)
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .accessibilityHint("Double tap to \(secondaryTitle.lowercased())")
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.primaryBackground.ignoresSafeArea())
    }
}

struct ErrorBannerView: View {
    let message: String
    var onRetry: (() -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(Color.red)
                .accessibilityHidden(true)
            
            Text(message)
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Text("Retry")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.accentColor)
                }
                .accessibilityLabel("Retry action")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.red.opacity(colorScheme == .dark ? 0.15 : 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.red.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
}

#Preview {
    AppErrorView(
        title: "Model Unavailable",
        message: "The on-device machine learning model could not be loaded. Please ensure the app bundle is intact and restart.",
        primaryActionTitle: "Try Again",
        primaryAction: {},
        secondaryActionTitle: "Dismiss",
        secondaryAction: {}
    )
}
