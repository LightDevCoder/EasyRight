cask "easyright" do
  version "1.2.1"
  sha256 "9230f3db5684f537a00c15141e6dac746092ea4fef59e2ab37538d64dba46e37"

  url "https://github.com/easyright/EasyRight/releases/download/v#{version}/EasyRight-v#{version}-macOS-Universal.dmg"
  name "EasyRight"
  desc "Finder right-click context menu assistant"
  homepage "https://github.com/easyright/EasyRight"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :ventura

  app "EasyRight.app"

  uninstall_postflight do
    system_command "/usr/bin/osascript",
                   args: ["-l", "JavaScript", "-e", 'ObjC.import("AppKit"); $.NSUpdateDynamicServices();']
  end

  uninstall quit:  "com.easyright.app",
            trash: "~/Library/Services/EasyRightQuickActions.service"

  zap trash: [
    "~/Library/Containers/com.easyright.app",
    "~/Library/Containers/com.easyright.app.extension",
    "~/Library/Group Containers/group.com.easyright.app",
    "~/Library/Preferences/com.easyright.app.plist",
    "~/Library/Services/EasyRightQuickActions.service",
  ]

  caveats <<~EOS
    EasyRight is an Ad-hoc signed, not notarized community build.
    First try Control-click > Open, or System Settings > Privacy & Security
    > Open Anyway. If macOS still blocks this verified download, remove the
    quarantine attribute from this app only, then open it:

      sudo /usr/bin/xattr -dr com.apple.quarantine "/Applications/EasyRight.app"
      open "/Applications/EasyRight.app"

    Enter your macOS administrator password when prompted; Terminal does not
    display password characters. Do not disable Gatekeeper globally.

    If an upgrade from version 1.2.0 fails with
    "pluginkit -r com.easyright.app.extension", it is using an
    uninstall script saved by that old Cask. Run this one-time recovery:

      rm -rf "$(brew --caskroom)/easyright"
      brew install --cask --force easyright/easyright/easyright

    This clears only the stale Homebrew receipt. App settings are preserved.
  EOS
end
