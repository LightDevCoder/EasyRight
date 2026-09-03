cask "easyright" do
  version "0.1.0"
  sha256 "12b5a6fe524d7e4134f1bdefe3f1f88706f83499835137fa81a63e7f149f553b"

  url "https://github.com/LightDevCoder/EasyRight/releases/download/v#{version}/EasyRight-v#{version}-macOS-Universal.dmg"
  name "EasyRight"
  desc "Finder right-click context menu assistant"
  homepage "https://github.com/LightDevCoder/EasyRight"

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
      brew install --cask --force LightDevCoder/easyright/easyright

    This clears only the stale Homebrew receipt. App settings are preserved.
  EOS
end
