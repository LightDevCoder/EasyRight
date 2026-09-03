import SwiftUI
import AppKit

/// Standalone test suite verifying DesignTokens and Studio Window Shell contract.
@main
struct DesignSystemTests {
    static func main() {
        print("🧪 [Test] Running Design System & Window Shell Tests...")
        
        // 1. Layout & Window Dimensions
        assert(DesignTokens.Layout.windowMinWidth == 800, "Window min width should be 800")
        assert(DesignTokens.Layout.windowMinHeight == 520, "Window min height should be 520")
        assert(DesignTokens.Layout.windowIdealWidth == 880, "Window ideal width should be 880")
        assert(DesignTokens.Layout.windowIdealHeight == 580, "Window ideal height should be 580")
        
        // 2. Row Density Standard (38-42 pt)
        assert(DesignTokens.Layout.minRowHeight == 38, "Min row height should be 38")
        assert(DesignTokens.Layout.maxRowHeight == 42, "Max row height should be 42")
        assert(DesignTokens.Layout.standardRowHeight >= 38 && DesignTokens.Layout.standardRowHeight <= 42, "Standard row height should be within 38-42 pt")
        
        // 3. Hairline Border & Corner Radius
        assert(DesignTokens.Stroke.hairline == 0.5, "Hairline stroke should be 0.5 pt")
        assert(DesignTokens.CornerRadius.window == 12, "Window corner radius should be 12 pt")
        
        // 4. Animation Spring Constants
        assert(DesignTokens.AnimationToken.durationNormal == 0.18, "Normal duration should be 0.18s")
        assert(DesignTokens.AnimationToken.springResponse == 0.22, "Spring response should be 0.22")
        assert(DesignTokens.AnimationToken.springDamping == 0.82, "Spring damping should be 0.82")
        
        // 5. Studio Section Router
        let sections = StudioSection.allCases
        assert(sections.count == 3, "StudioSection should have 3 sections")
        assert(sections.contains(.canvas), "StudioSection should contain canvas")
        assert(sections.contains(.settings), "StudioSection should contain settings")
        assert(sections.contains(.diagnostics), "StudioSection should contain diagnostics")
        for section in sections {
            assert(!section.title.isEmpty, "Section title should not be empty")
            assert(!section.iconName.isEmpty, "Section iconName should not be empty")
        }
        
        // 6. VisualEffectView Verification
        let vev = VisualEffectView()
        assert(vev.material == .underWindowBackground, "VisualEffectView material default should be .underWindowBackground")
        assert(vev.blendingMode == .behindWindow, "VisualEffectView blendingMode default should be .behindWindow")
        assert(vev.state == .active, "VisualEffectView state default should be .active")
        
        // 7. MainWindowView Instantiation
        let mainWindow = MainWindowView()
        _ = mainWindow.body
        
        print("✅ [Test] All Design System & Window Shell Tests PASSED!")
    }
}
