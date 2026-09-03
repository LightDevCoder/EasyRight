import SwiftUI
import AppKit

// MARK: - Design Tokens
/// Central design token system for the EasyRight Studio redesign.
/// Standardizes typography, spacing, row density, hairline borders, animations, and dynamic semantic colors.
public enum DesignTokens {

    // MARK: - Layout & Dimensions
    public enum Layout {
        /// Standard studio window dimensions (adaptive macOS layout)
        public static let windowMinWidth: CGFloat = 920
        public static let windowMinHeight: CGFloat = 560
        public static let windowIdealWidth: CGFloat = 1060
        public static let windowIdealHeight: CGFloat = 660

        /// Standard row density calibrated to 38–42 pt
        public static let minRowHeight: CGFloat = 38
        public static let standardRowHeight: CGFloat = 40
        public static let maxRowHeight: CGFloat = 42

        /// Top toolbar height
        public static let toolbarHeight: CGFloat = 48

        /// Multi-pane layout column constraints
        public static let libraryMinWidth: CGFloat = 200
        public static let libraryIdealWidth: CGFloat = 240
        public static let libraryMaxWidth: CGFloat = 280

        public static let canvasMinWidth: CGFloat = 340
        public static let livePreviewWidth: CGFloat = 270
        public static let inspectorWidth: CGFloat = 280
        public static let diagnosticDrawerWidth: CGFloat = 320
    }

    // MARK: - Spacing & Paddings
    public enum Spacing {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
        public static let xxl: CGFloat = 24
        public static let xxxl: CGFloat = 32

        // Semantic paddings
        public static let windowPadding: CGFloat = 16
        public static let toolbarHorizontal: CGFloat = 16
        public static let toolbarVertical: CGFloat = 8
        public static let cardPadding: CGFloat = 12
        public static let rowHorizontalPadding: CGFloat = 10
        public static let rowVerticalPadding: CGFloat = 6
        public static let capsulePaddingHorizontal: CGFloat = 10
        public static let capsulePaddingVertical: CGFloat = 4
    }

    // MARK: - Corner Radii
    public enum CornerRadius {
        /// Window corner radius (12 pt)
        public static let window: CGFloat = 12
        /// Cards and containers (10 pt)
        public static let card: CGFloat = 10
        /// Inner panels and sections (8 pt)
        public static let panel: CGFloat = 8
        /// Buttons and interactive controls (6 pt)
        public static let button: CGFloat = 6
        /// Pills and capsules (100 pt)
        public static let capsule: CGFloat = 100
        /// Badges and tags (4 pt)
        public static let tag: CGFloat = 4
    }

    // MARK: - Strokes & Borders
    public enum Stroke {
        /// Razor-thin hairline stroke width (0.5 pt)
        public static let hairline: CGFloat = 0.5
        public static let thin: CGFloat = 1.0
        public static let focus: CGFloat = 2.0

        /// Hairline border colors
        public static let defaultBorder = Color.primary.opacity(0.08)
        public static let separator = Color(nsColor: .separatorColor)
        public static let subtleBorder = Color.primary.opacity(0.05)
        public static let prominentBorder = Color.primary.opacity(0.15)
    }

    // MARK: - Typography
    public enum Typography {
        public static let windowTitle = Font.system(size: 14, weight: .semibold)
        public static let sectionTitle = Font.system(size: 14, weight: .semibold)
        public static let cardTitle = Font.system(size: 13, weight: .semibold)
        public static let headerTitle = Font.system(size: 16, weight: .bold)

        /// Standard body typography (13 pt)
        public static let body = Font.system(size: 13, weight: .regular)
        public static let bodyMedium = Font.system(size: 13, weight: .medium)
        public static let bodyBold = Font.system(size: 13, weight: .semibold)

        /// Standard caption typography (11 pt)
        public static let caption = Font.system(size: 11, weight: .regular)
        public static let captionMedium = Font.system(size: 11, weight: .medium)
        public static let captionBold = Font.system(size: 11, weight: .semibold)
        public static let caption2 = Font.system(size: 10, weight: .regular)

        /// Monospace typography for hotkeys, paths, hashes
        public static let monospaced = Font.system(size: 12, weight: .regular, design: .monospaced)
        public static let monospacedSmall = Font.system(size: 10, weight: .regular, design: .monospaced)
    }

    // MARK: - Icon Sizes & Rendering
    public enum Icon {
        public static let small: CGFloat = 14
        public static let standard: CGFloat = 16
        public static let medium: CGFloat = 18
        public static let large: CGFloat = 22
        public static let extraLarge: CGFloat = 32
    }

    // MARK: - Animation Constants
    public enum AnimationToken {
        public static let durationFast: Double = 0.12
        public static let durationNormal: Double = 0.18
        public static let durationSlow: Double = 0.28

        /// Micro-animation spring token (response: 0.22, dampingFraction: 0.82)
        public static let springResponse: Double = 0.22
        public static let springDamping: Double = 0.82

        public static let standardSpring = Animation.spring(
            response: springResponse,
            dampingFraction: springDamping
        )

        public static let quickSpring = Animation.spring(
            response: 0.18,
            dampingFraction: 0.85
        )

        public static let smoothEase = Animation.easeInOut(duration: durationNormal)
    }

    /// Spring animation for reordering and micro-interactions
    public static let springTransition = AnimationToken.quickSpring

    // MARK: - Dynamic Semantic Colors
    public enum Colors {
        // Surface & Backgrounds (Dark/Light mode adaptive)
        public static let windowBackground = Color(nsColor: .windowBackgroundColor)
        public static let controlBackground = Color(nsColor: .controlBackgroundColor)
        public static let underWindowBackground = Color(nsColor: .underPageBackgroundColor)

        public static let cardBackground = Color(nsColor: .controlBackgroundColor).opacity(0.65)
        public static let cardBackgroundHover = Color(nsColor: .selectedControlColor).opacity(0.10)
        public static let cardBackgroundSelected = Color(nsColor: .selectedControlColor).opacity(0.18)

        public static let subtleFill = Color.primary.opacity(0.04)
        public static let activeFill = Color.primary.opacity(0.08)
        public static let hoverFill = Color.primary.opacity(0.06)

        // Text & Foreground
        public static let primaryText = Color(nsColor: .labelColor)
        public static let secondaryText = Color(nsColor: .secondaryLabelColor)
        public static let tertiaryText = Color(nsColor: .tertiaryLabelColor)
        public static let quaternaryText = Color(nsColor: .quaternaryLabelColor)

        // Borders & Separators
        public static let separator = Color(nsColor: .separatorColor)
        public static let border = Color.primary.opacity(0.08)
        public static let borderSubtle = Color.primary.opacity(0.04)
        public static let borderProminent = Color.primary.opacity(0.16)

        // Brand & Accents
        public static let accent = Color.accentColor
        public static let accentSubdued = Color.accentColor.opacity(0.15)

        // Status Colors (Healthy / Warning / Error / Info)
        public static let statusGreen = Color.green
        public static let statusGreenBackground = Color.green.opacity(0.14)
        public static let statusGreenBorder = Color.green.opacity(0.30)

        public static let statusAmber = Color.orange
        public static let statusAmberBackground = Color.orange.opacity(0.14)
        public static let statusAmberBorder = Color.orange.opacity(0.30)

        public static let statusRed = Color.red
        public static let statusRedBackground = Color.red.opacity(0.14)
        public static let statusRedBorder = Color.red.opacity(0.30)

        public static let statusBlue = Color.blue
        public static let statusBlueBackground = Color.blue.opacity(0.14)
        public static let statusBlueBorder = Color.blue.opacity(0.30)
    }
}

// MARK: - View Modifiers & Extensions

public extension View {
    /// Applies standard hairline border stroke
    func studioHairlineBorder(
        color: Color = DesignTokens.Stroke.defaultBorder,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.card
    ) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(color, lineWidth: DesignTokens.Stroke.hairline)
        )
    }

    /// Wraps content in a standardized translucent studio card
    func studioCard(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.card,
        padding: CGFloat = DesignTokens.Spacing.cardPadding
    ) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(DesignTokens.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
            )
    }

    /// Standard row density frame modifier (38–42 pt)
    func studioRowDensity(
        height: CGFloat = DesignTokens.Layout.standardRowHeight,
        horizontalPadding: CGFloat = DesignTokens.Spacing.rowHorizontalPadding
    ) -> some View {
        self
            .padding(.horizontal, horizontalPadding)
            .frame(minHeight: DesignTokens.Layout.minRowHeight, maxHeight: DesignTokens.Layout.maxRowHeight)
            .frame(height: height)
    }

    /// Renders SF Symbol with hierarchical monochrome shading
    func studioIcon(
        size: CGFloat = DesignTokens.Icon.standard,
        color: Color = DesignTokens.Colors.primaryText
    ) -> some View {
        self
            .font(.system(size: size))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
    }
}
