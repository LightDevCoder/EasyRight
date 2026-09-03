import SwiftUI
import AppKit

/// An NSViewRepresentable wrapper around AppKit's NSVisualEffectView,
/// providing modern acrylic translucency with `.behindWindow` blending.
public struct VisualEffectView: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State
    public var isEmphasized: Bool

    public init(
        material: NSVisualEffectView.Material = .underWindowBackground,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active,
        isEmphasized: Bool = false
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
        self.isEmphasized = isEmphasized
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.isEmphasized = isEmphasized
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        nsView.isEmphasized = isEmphasized
    }
}

// MARK: - Acrylic Window Background & Modifier
public struct AcrylicWindowBackground: View {
    public var cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = DesignTokens.CornerRadius.window) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        VisualEffectView(
            material: .underWindowBackground,
            blendingMode: .behindWindow,
            state: .active
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
        )
        .ignoresSafeArea()
    }
}

public extension View {
    /// Clips the view and renders an acrylic backdrop with a 12pt corner radius and hairline border.
    func acrylicWindowBackground(cornerRadius: CGFloat = DesignTokens.CornerRadius.window) -> some View {
        self.background(AcrylicWindowBackground(cornerRadius: cornerRadius))
    }
}

// MARK: - Window Drag Area
/// An NSViewRepresentable wrapper that initiates AppKit window dragging on mouse down.
/// Used in custom titlebar / toolbar regions so the window can be moved by dragging its top toolbar,
/// without setting `isMovableByWindowBackground = true` on the NSWindow (which causes AppKit to hijack
/// list and canvas drag-and-drop gestures).
public struct WindowDragArea: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> WindowDragView {
        WindowDragView()
    }

    public func updateNSView(_ nsView: WindowDragView, context: Context) {}
}

public final class WindowDragView: NSView {
    public override var mouseDownCanMoveWindow: Bool {
        true
    }

    public override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            window?.zoom(nil)
        } else {
            window?.performDrag(with: event)
        }
    }
}

