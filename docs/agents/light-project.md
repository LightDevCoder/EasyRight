<!-- light-project:managed:start -->
# Light Project Configuration

- Project type: macOS Utility Application (Swift/SwiftUI/AppKit)
- Goal: Redesign MacRightClick into a polished, modern macOS Finder context-menu utility with Raycast-inspired acrylic styling and CleanShot X-style menu bar accessory architecture.
- Outputs: docs/agents/light-project.md, docs/agents/issue-tracker.md, .scratch/macrightclick-redesign/spec.md, .scratch/macrightclick-redesign/issues/, Modernized macOS host app and FinderSync extension codebase
- Preset: software
- Relevant Skills: code-review, tdd, project-review
- Issue tracker: local-markdown at .scratch/<effort>/issues
- Domain context: .scratch/macrightclick-redesign/spec.md, README.md, Sources/EasyRight/Core/MenuAction.swift, Sources/EasyRight/Core/MenuLayout.swift
- Review profile: specialist
- Acceptance strategy: Automated unit tests, Swift Package build verification, and manual AppKit/FinderSync integration checks
- Working area: .scratch
- Collaboration: default
- Constraints: Preserve working Finder context-menu functionality and FIFinderSync IPC dispatch without regression, Strictly respect macOS system sandbox and NSMenu presentation constraints, No third-party UI framework dependencies; use native SwiftUI and AppKit primitives
<!-- light-project:managed:end -->
