import SwiftUI

enum AppRoute {
    case welcome
    case compose
    case confirm
}

private struct AppRouteKey: EnvironmentKey {
    static let defaultValue: Binding<AppRoute>? = nil
}

extension EnvironmentValues {
    var appRoute: Binding<AppRoute>? {
        get { self[AppRouteKey.self] }
        set { self[AppRouteKey.self] = newValue }
    }
}
