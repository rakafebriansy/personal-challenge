//
//  AppRouter.swift
//  hijaiapp
//
//  Created by Raka Febrian Syahputra on 04/09/26.
//

import SwiftUI

enum AppTab: Int, Hashable {
    case canvas = 0
    case scanner = 1
    case voice = 2
    case challenge = 3
}

@Observable
final class AppRouter {
    static let shared = AppRouter()
    
    var selectedTab: AppTab = .canvas
    var isTabBarDisabled: Bool = false
}
