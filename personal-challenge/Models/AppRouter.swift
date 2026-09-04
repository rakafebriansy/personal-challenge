//
//  AppRouter.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 04/09/26.
//

import SwiftUI

enum AppTab: Int, Hashable {
    case scanner = 0
    case canvas = 1
    case voice = 2
    case challenge = 3
}

@Observable
final class AppRouter {
    static let shared = AppRouter()
    
    var selectedTab: AppTab = .scanner
}
