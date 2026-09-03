import Foundation
import EasyRightCore

@main
struct ContainerScopeVerificationTest {
    static func main() {
        print("🧪 [Test] Running ContainerScope verification suite...")

        // 1. TerminalOpenAction container availability
        let terminalAction = TerminalOpenAction(type: .terminal)
        let itermAction = TerminalOpenAction(type: .iterm2)

        let testContainerURL = URL(fileURLWithPath: "/tmp")

        // In container (blank area), terminal actions should be available if installed
        assert(terminalAction.isAvailable(for: [testContainerURL], isContainer: true) == true,
               "TerminalOpenAction MUST be available in container (blank area) when installed")
        assert(terminalAction.isAvailable(for: [], isContainer: true) == true,
               "TerminalOpenAction MUST be available in container even with empty array")

        // 2. FileManageAction.copyPath container availability
        let copyPathAction = FileManageAction(type: .copyPath)
        assert(copyPathAction.isAvailable(for: [testContainerURL], isContainer: true) == true,
               "CopyPath MUST be available in blank area to copy current folder path")

        let cutAction = FileManageAction(type: .cut)
        assert(cutAction.isAvailable(for: [testContainerURL], isContainer: true) == false,
               "Cut action must NOT be available in blank area")

        // 3. PathCopyAction shellEscaped container availability
        let shellCopyAction = PathCopyAction(kind: .shellEscaped)
        assert(shellCopyAction.isAvailable(for: [testContainerURL], isContainer: true) == true,
               "ShellEscaped copy MUST be available in blank area")

        print("🎉 All ContainerScope verification tests PASSED!")
    }
}
