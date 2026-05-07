#if canImport(SwiftUI)
import SwiftUI
import LazyBillCore

@main
struct LazyBillApp: App {
    @StateObject private var store = BillStore.preview

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(store)
        }
    }
}
#endif
