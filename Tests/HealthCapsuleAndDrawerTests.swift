import SwiftUI
import AppKit
import FinderSync

/// Standalone test suite verifying AmbientHealthCapsule, DiagnosticDrawerView, and their contracts.
@main
struct HealthCapsuleAndDrawerTests {
    static func main() {
        print("🧪 [Test] Running Ambient Health Capsule & Diagnostic Drawer Tests...")

        // 1. Verify DesignTokens drawer layout constants
        assert(DesignTokens.Layout.diagnosticDrawerWidth == 320, "Diagnostic drawer width must be 320 pt")
        assert(DesignTokens.Spacing.capsulePaddingHorizontal == 10, "Capsule horizontal padding must be 10 pt")
        assert(DesignTokens.Spacing.capsulePaddingVertical == 4, "Capsule vertical padding must be 4 pt")

        // 2. Verify Health Snapshot construction and level logic
        let healthySnapshot = FinderExtensionDiagnostics.makeSnapshot(
            fullDiskAccessGranted: true,
            finderSyncControllerEnabled: true,
            pluginKitState: .enabled,
            heartbeatState: .recent(observedPathCount: 3),
            watchScope: .everywhere,
            pendingActionCount: 0,
            oldestPendingAge: nil,
            failedActionCount: 0
        )
        assert(healthySnapshot.healthLevel == .healthy, "Fully working setup should be healthy")
        assert(healthySnapshot.menuServiceLevel == .healthy, "Service level should be healthy")

        let fdaDeniedSnapshot = FinderExtensionDiagnostics.makeSnapshot(
            fullDiskAccessGranted: false,
            finderSyncControllerEnabled: true,
            pluginKitState: .enabled,
            heartbeatState: .recent(observedPathCount: 2),
            watchScope: .everywhere,
            pendingActionCount: 0,
            oldestPendingAge: nil,
            failedActionCount: 0
        )
        assert(fdaDeniedSnapshot.healthLevel == .warning, "FDA denied should yield warning level")
        assert(fdaDeniedSnapshot.recommendedRepairAction == .openFullDiskAccessSettings, "Should recommend opening FDA settings")

        let notRegisteredSnapshot = FinderExtensionDiagnostics.makeSnapshot(
            fullDiskAccessGranted: true,
            finderSyncControllerEnabled: true,
            pluginKitState: .notRegistered,
            heartbeatState: .missing,
            watchScope: .everywhere,
            pendingActionCount: 0,
            oldestPendingAge: nil,
            failedActionCount: 0
        )
        assert(notRegisteredSnapshot.healthLevel == .critical, "Not registered extension should be critical")
        assert(notRegisteredSnapshot.recommendedRepairAction == .registerExtension, "Should recommend registering extension")

        // 3. Verify AmbientHealthCapsule View Instantiation
        var capsuleTapped = false
        let capsule = AmbientHealthCapsule {
            capsuleTapped = true
        }
        _ = capsule.body
        capsule.onTap()
        assert(capsuleTapped == true, "Invoking capsule onTap should call the callback")

        // 4. Verify DiagnosticDrawerView View Instantiation & Binding
        var isDrawerPresented = true
        let drawerBinding = Binding(
            get: { isDrawerPresented },
            set: { isDrawerPresented = $0 }
        )
        let drawer = DiagnosticDrawerView(isPresented: drawerBinding)
        _ = drawer.body
        assert(drawer.isPresented == true, "Drawer isPresented binding should match state")

        // 5. Verify MainWindowView with Drawer presentation state
        let mainWindow = MainWindowView(initialSection: .canvas)
        _ = mainWindow.body

        // 6. Diagnostic summary report generation
        let summary = healthySnapshot.diagnosticSummary(appVersion: "0.1.0")
        assert(summary.contains("EasyRight Diagnostics"), "Summary should contain header")
        assert(summary.contains("Full Disk Access: granted"), "Summary should report FDA")
        assert(summary.contains("Extension Registration: enabled"), "Summary should report Extension status")

        print("✅ [Test] All Ambient Health Capsule & Diagnostic Drawer Tests PASSED!")
    }
}
