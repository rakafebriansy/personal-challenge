//
//  AccessibilityHelpers.swift
//  hijaiapp
//
//  Created by Raka Febrian Syahputra on 06/09/26.
//

import SwiftUI
import UIKit

enum AccessibilityNotificationHelper {
    /// Post VoiceOver announcement to notify assistive tech users of state transitions.
    static func postAnnouncement(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    /// Notify VoiceOver that screen or layout significantly changed
    static func postScreenChanged(focusOn element: Any? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: element)
    }
    
    /// Notify VoiceOver of a layout change (e.g. dynamic contents appearing/disappearing)
    static func postLayoutChanged(focusOn element: Any? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: element)
    }
}

struct AccessibleButtonModifier: ViewModifier {
    let label: String
    var hint: String? = nil
    var value: String? = nil
    var isSelected: Bool = false
    var isHeader: Bool = false
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .accessibilityAddTraits(isHeader ? .isHeader : [])
    }
}

extension View {
    /// Helper to announce an accessibility message when a condition or state changes.
    func onAccessibilityAnnouncement<T: Equatable>(of value: T, message: @escaping (T) -> String?) -> some View {
        self.onChange(of: value) { _, newValue in
            if let announcement = message(newValue), !announcement.isEmpty {
                AccessibilityNotificationHelper.postAnnouncement(announcement)
            }
        }
    }
    
    /// Attach accessible button traits, label, and hint cleanly
    func accessibleButton(label: String, hint: String? = nil, value: String? = nil, isSelected: Bool = false) -> some View {
        self.modifier(AccessibleButtonModifier(label: label, hint: hint, value: value, isSelected: isSelected))
    }
}
