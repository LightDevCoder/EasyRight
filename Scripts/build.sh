#!/usr/bin/env bash

# ==============================================================================
# 开源EasyRight (EasyRight) 自动化编译与打包脚本 (支持 Universal 2)
# ==============================================================================
set -euo pipefail

echo "🚀 [Build] 开始自动化编译与打包流程..."

# 1. 初始化目录
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="EasyRight"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
EXT_BUNDLE="$APP_BUNDLE/Contents/PlugIns/${APP_NAME}Extension.appex"
DMG_TEMP_DIR="$BUILD_DIR/dmg_temp"
DISTRIBUTION_ROUTE="${DISTRIBUTION_ROUTE:-website-dev}"
CODE_SIGN_IDENTITY="-"
CODESIGN_RUNTIME_ARGS=""

# 确保在脚本退出（成功、失败、被中断）时，清理临时磁盘映像挂载与临时目录
cleanup_temp_artifacts() {
    if [ -d "${DMG_TEMP_DIR:-}" ]; then
        rm -rf "$DMG_TEMP_DIR" 2>/dev/null || true
    fi
    hdiutil detach "/Volumes/EasyRight" >/dev/null 2>&1 || true
}
trap cleanup_temp_artifacts EXIT INT TERM

if [ "$DISTRIBUTION_ROUTE" = "website-release" ]; then
    if [ -z "${DEVELOPER_ID_APPLICATION:-}" ]; then
        echo "❌ [Build] website-release 需要设置 DEVELOPER_ID_APPLICATION，例如：Developer ID Application: Your Name (TEAMID)"
        exit 2
    fi
    CODE_SIGN_IDENTITY="$DEVELOPER_ID_APPLICATION"
    CODESIGN_RUNTIME_ARGS="--options runtime --timestamp"
elif [ "$DISTRIBUTION_ROUTE" = "mac-app-store" ]; then
    echo "❌ [Build] 当前仓库已确定主分发路线为官网/开源站外分发。"
    echo "❌ [Build] Mac App Store 路线需要恢复主 App sandbox、正式 App Group 与 security-scoped access 后再单独启用。"
    exit 2
elif [ "$DISTRIBUTION_ROUTE" != "website-dev" ]; then
    echo "❌ [Build] 未知 DISTRIBUTION_ROUTE=$DISTRIBUTION_ROUTE，可选：website-dev / website-release / mac-app-store"
    exit 2
fi

submit_for_notarization() {
    local target="$1"

    if [ -n "${NOTARY_PROFILE:-}" ]; then
        xcrun notarytool submit "$target" --keychain-profile "$NOTARY_PROFILE" --wait
    elif [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_TEAM_ID:-}" ] && [ -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]; then
        xcrun notarytool submit "$target" \
            --apple-id "$APPLE_ID" \
            --team-id "$APPLE_TEAM_ID" \
            --password "$APPLE_APP_SPECIFIC_PASSWORD" \
            --wait
    else
        echo "❌ [Build] website-release 需要 NOTARY_PROFILE，或 APPLE_ID + APPLE_TEAM_ID + APPLE_APP_SPECIFIC_PASSWORD"
        exit 2
    fi
}

if [ -n "${VERSION_OVERRIDE:-}" ]; then
    VERSION="$VERSION_OVERRIDE"
elif [ -f "VERSION" ]; then
    VERSION=$(tr -d '\r\n' < VERSION)
else
    VERSION="1.0.0"
fi
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ [Build] VERSION 必须是稳定语义版本，实际为: $VERSION"
    exit 2
fi
echo "🏷️ [Build] 检测到全局版本号: $VERSION"
echo "🚢 [Build] 当前分发路线: $DISTRIBUTION_ROUTE"

echo "🧹 [Build] 清理旧编译目录: $BUILD_DIR..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
touch "$BUILD_DIR/.metadata_never_index"

echo "📝 [Build] 动态创建 VFS Overlay 解决系统底层 SwiftBridging 重定义冲突..."
cat << 'EOF' > "$BUILD_DIR/empty.modulemap"
// 空的 modulemap 文件，用于通过 VFS 覆盖解决系统重定义冲突
EOF

cat << EOF > "$BUILD_DIR/overlay.yaml"
{
  'version': 0,
  'roots': [
    {
      'type': 'directory',
      'name': '/Library/Developer/CommandLineTools/usr/include/swift',
      'contents': [
        {
          'type': 'file',
          'name': 'bridging.modulemap',
          'external-contents': '$BUILD_DIR/empty.modulemap'
        }
      ]
    }
  ]
}
EOF

echo "📂 [Build] 创建 macOS App Bundle 结构..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$EXT_BUNDLE/Contents/MacOS"
mkdir -p "$EXT_BUNDLE/Contents/Resources"

# 2. 动态写入主 App 的 Info.plist (包含 CFBundleIconFile)
echo "📝 [Build] 生成主程序的 Info.plist..."
cat <<EOF > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.easyright.app</string>
    <key>CFBundleName</key>
    <string>EasyRight</string>
    <key>CFBundleDisplayName</key>
    <string>EasyRight</string>
    <key>CFBundleExecutable</key>
    <string>EasyRight</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict><key>default</key><string>EasyRight…</string></dict>
            <key>NSMessage</key><string>performFinderService</string>
            <key>NSPortName</key><string>EasyRight</string>
            <key>NSRequiredContext</key>
            <dict><key>NSTextContent</key><string>FilePath</string></dict>
            <key>NSUserData</key><string>com.easyright.service.openActionPalette</string>
            <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        </dict>
    </array>
</dict>
</plist>
EOF

# 3. 动态写入 FinderSync 扩展的 Info.plist
echo "📝 [Build] 生成访达扩展的 Info.plist..."
cat <<EOF > "$EXT_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.easyright.app.extension</string>
    <key>CFBundleName</key>
    <string>EasyRightExtension</string>
    <key>CFBundleDisplayName</key>
    <string>EasyRight 访达扩展</string>
    <key>CFBundleExecutable</key>
    <string>EasyRightExtension</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.FinderSync</string>
        <key>NSExtensionPrincipalClass</key>
        <string>FinderSync</string>
    </dict>
</dict>
</plist>
EOF

# 4. 转换并打包 AppIcon
if [ -f "Resources/AppIcon.png" ]; then
    echo "🎨 [Build] 检测到 Resources/AppIcon.png，开始转换为系统级 AppIcon.icns..."
    ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
    mkdir -p "$ICONSET_DIR"
    
    # 缩放切图
    sips -z 16 16     "Resources/AppIcon.png" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null 2>&1 || true
    sips -z 32 32     "Resources/AppIcon.png" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null 2>&1 || true
    sips -z 32 32     "Resources/AppIcon.png" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null 2>&1 || true
    sips -z 64 64     "Resources/AppIcon.png" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null 2>&1 || true
    sips -z 128 128   "Resources/AppIcon.png" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null 2>&1 || true
    sips -z 256 256   "Resources/AppIcon.png" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null 2>&1 || true
    sips -z 256 256   "Resources/AppIcon.png" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null 2>&1 || true
    sips -z 512 512   "Resources/AppIcon.png" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null 2>&1 || true
    sips -z 512 512   "Resources/AppIcon.png" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null 2>&1 || true
    sips -z 1024 1024 "Resources/AppIcon.png" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null 2>&1 || true

    if command -v zopflipng >/dev/null; then
        echo "🗜️ [Build] 使用 zopflipng 优化 AppIcon.iconset 体积..."
        for icon_png in "$ICONSET_DIR"/*.png; do
            zopflipng -y -m --lossy_transparent "$icon_png" "$icon_png" >/dev/null 2>&1 || true
        done
    fi
    
    if command -v iconutil >/dev/null; then
        iconutil -c icns "$ICONSET_DIR" -o "$BUILD_DIR/AppIcon.icns"
        cp "$BUILD_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
        echo "🟢 [Build] 成功合成并注入 AppIcon.icns 至打包！"
    else
        echo "⚠️ [Build] 未找到 iconutil 工具，使用 AppIcon.png 直接降级拷贝..."
        cp "Resources/AppIcon.png" "$APP_BUNDLE/Contents/Resources/AppIcon.png"
    fi
else
    echo "⚠️ [Build] 未找到 Resources/AppIcon.png 资源，跳过图标打包。"
fi

# 拷贝 Office 三件套最小骨架到 .app/Contents/Resources/Templates/
if [ -d "Resources/Templates" ]; then
    mkdir -p "$APP_BUNDLE/Contents/Resources/Templates"
    cp -R Resources/Templates/. "$APP_BUNDLE/Contents/Resources/Templates/"
    echo "📄 [Build] 已拷贝 Office 模板到 .app/Contents/Resources/Templates/"
fi

# 5. 源码列表定义
HOST_SOURCES="
    Sources/EasyRight/AppDelegate.swift \
    Sources/EasyRight/MenuBarController.swift \
    Sources/EasyRight/FinderServicesProvider.swift \
    Sources/EasyRight/FinderQuickServiceManager.swift \
    Sources/EasyRight/Views/ContentView.swift \
    Sources/EasyRight/Views/GeneralSettingsView.swift \
    Sources/EasyRight/Views/ActionsSettingsView.swift \
    Sources/EasyRight/Views/FinderSettingsView.swift \
    Sources/EasyRight/Views/DiagnosticsSettingsView.swift \
    Sources/EasyRight/Views/AdvancedSettingsView.swift \
    Sources/EasyRight/Views/SettingsComponents.swift \
    Sources/EasyRight/Views/FinderServicePaletteView.swift \
    Sources/EasyRight/Views/DesignTokens.swift \
    Sources/EasyRight/Views/VisualEffectView.swift \
    Sources/EasyRight/Views/MainWindowView.swift \
    Sources/EasyRight/Views/AmbientHealthCapsule.swift \
    Sources/EasyRight/Views/DiagnosticDrawerView.swift \
    Sources/EasyRight/Views/AppMenuStateCoordinator.swift \
    Sources/EasyRight/Views/ActionLibraryView.swift \
    Sources/EasyRight/Views/ActiveMenuCanvasView.swift \
    Sources/EasyRight/Views/LiveMenuMockupView.swift \
    Sources/EasyRight/Views/ActionInspectorView.swift \
    Sources/EasyRight/Views/OnboardingView.swift \
    Sources/EasyRight/Views/PresetSelectionSheet.swift \
    Sources/EasyRight/Views/CustomAppsSettingsView.swift \
    Sources/EasyRight/Core/AppLanguageManager.swift \
    Sources/EasyRight/Core/MenuAction.swift \
    Sources/EasyRight/Core/MenuCanvasItem.swift \
    Sources/EasyRight/Core/ActionTagMapper.swift \
    Sources/EasyRight/Core/ActionProfile.swift \
    Sources/EasyRight/Core/DefaultActionRegistry.swift \
    Sources/EasyRight/Core/MenuLayout.swift \
    Sources/EasyRight/Core/SharedStorageManager.swift \
    Sources/EasyRight/Core/SharedFolderMonitor.swift \
    Sources/EasyRight/Core/ActionDispatcher.swift \
    Sources/EasyRight/Core/SharedHUDManager.swift \
    Sources/EasyRight/Core/FullDiskAccessChecker.swift \
    Sources/EasyRight/Core/LaunchServiceManager.swift \
    Sources/EasyRight/Core/LaunchPresentationPolicy.swift \
    Sources/EasyRight/Core/FinderExtensionDiagnostics.swift \
    Sources/EasyRight/Core/FinderServiceCatalog.swift \
    Sources/EasyRight/Core/FinderQuickActions.swift \
    Sources/EasyRight/Core/FinderQuickServiceProtocol.swift \
    Sources/EasyRight/Core/ExtensionHeartbeat.swift \
    Sources/EasyRight/Core/SystemReloader.swift \
    Sources/EasyRight/Core/PermissionRefreshCoordinator.swift \
    Sources/EasyRight/Core/ExternalToolManager.swift \
    Sources/EasyRight/Core/AppUpdateChecker.swift \
    Sources/EasyRight/Core/Actions/NewFileAction.swift \
    Sources/EasyRight/Core/Actions/FileManageAction.swift \
    Sources/EasyRight/Core/Actions/PathCopyService.swift \
    Sources/EasyRight/Core/Actions/PathCopyAction.swift \
    Sources/EasyRight/Core/Actions/ConfirmationPresenter.swift \
    Sources/EasyRight/Core/Actions/DeletionRequestCoordinator.swift \
    Sources/EasyRight/Core/Actions/InteractiveActionRunner.swift \
    Sources/EasyRight/Core/Actions/BackgroundActionRunner.swift \
    Sources/EasyRight/Core/Actions/TerminalOpenAction.swift \
    Sources/EasyRight/Core/Actions/CustomAppAction.swift \
    Sources/EasyRight/Core/Actions/UtilityAction.swift \
    Sources/EasyRight/Core/FileHashCalculator.swift \
    Sources/EasyRight/Core/Logging/AppLog.swift \
    Sources/EasyRight/Core/Distribution.swift \
    Sources/EasyRight/Core/ActionConfigCache.swift \
    Sources/EasyRight/Core/InstalledAppRegistry.swift \
    Sources/EasyRight/Core/Actions/QRCodePanel.swift
"

EXT_SOURCES="
    Sources/EasyRightExtension/FinderSync.swift \
    Sources/EasyRight/Core/AppLanguageManager.swift \
    Sources/EasyRight/Core/MenuAction.swift \
    Sources/EasyRight/Core/MenuCanvasItem.swift \
    Sources/EasyRight/Core/ActionTagMapper.swift \
    Sources/EasyRight/Core/ActionProfile.swift \
    Sources/EasyRight/Core/DefaultActionRegistry.swift \
    Sources/EasyRight/Core/MenuLayout.swift \
    Sources/EasyRight/Core/SharedStorageManager.swift \
    Sources/EasyRight/Core/ActionDispatcher.swift \
    Sources/EasyRight/Core/SharedHUDManager.swift \
    Sources/EasyRight/Core/FullDiskAccessChecker.swift \
    Sources/EasyRight/Core/LaunchPresentationPolicy.swift \
    Sources/EasyRight/Core/ExtensionHeartbeat.swift \
    Sources/EasyRight/Core/Actions/NewFileAction.swift \
    Sources/EasyRight/Core/Actions/FileManageAction.swift \
    Sources/EasyRight/Core/Actions/PathCopyService.swift \
    Sources/EasyRight/Core/Actions/PathCopyAction.swift \
    Sources/EasyRight/Core/Actions/ConfirmationPresenter.swift \
    Sources/EasyRight/Core/Actions/DeletionRequestCoordinator.swift \
    Sources/EasyRight/Core/Actions/InteractiveActionRunner.swift \
    Sources/EasyRight/Core/Actions/BackgroundActionRunner.swift \
    Sources/EasyRight/Core/Actions/TerminalOpenAction.swift \
    Sources/EasyRight/Core/Actions/CustomAppAction.swift \
    Sources/EasyRight/Core/Actions/UtilityAction.swift \
    Sources/EasyRight/Core/FileHashCalculator.swift \
    Sources/EasyRight/Core/Logging/AppLog.swift \
    Sources/EasyRight/Core/Distribution.swift \
    Sources/EasyRight/Core/ActionConfigCache.swift \
    Sources/EasyRight/Core/InstalledAppRegistry.swift \
    Sources/EasyRight/Core/Actions/QRCodePanel.swift
"

SDK_PATH=$(xcrun --show-sdk-path)
COMMON_FLAGS="-Onone -parse-as-library -sdk $SDK_PATH -vfsoverlay $BUILD_DIR/overlay.yaml"

# 按分发路线注入编译期常量，供 Sources/EasyRight/Core/Distribution.swift 读取
case "$DISTRIBUTION_ROUTE" in
    website-dev)     COMMON_FLAGS="$COMMON_FLAGS -D WEBSITE_DEV" ;;
    website-release) COMMON_FLAGS="$COMMON_FLAGS -D WEBSITE_RELEASE" ;;
    mac-app-store)   COMMON_FLAGS="$COMMON_FLAGS -D MAC_APP_STORE" ;;
esac

# 优化级：dev 默认保留 -Onone，便于回放崩溃栈与排查；release / MAS 改用 -O。
# 用 ${VAR/old/new} 替换而非追加，避免 swiftc 同时收到 -Onone 与 -O 两档。
case "$DISTRIBUTION_ROUTE" in
    website-release|mac-app-store)
        COMMON_FLAGS="${COMMON_FLAGS/-Onone/-O}"
        ;;
esac

# 6. 编译宿主主程序 (arm64 与 x86_64)
echo "🛠️ [Build] 编译宿主主程序 (arm64)..."
swiftc $COMMON_FLAGS -target arm64-apple-macosx13.0 $HOST_SOURCES -o "$BUILD_DIR/EasyRight_arm64"

echo "🛠️ [Build] 编译宿主主程序 (x86_64)..."
swiftc $COMMON_FLAGS -target x86_64-apple-macosx13.0 $HOST_SOURCES -o "$BUILD_DIR/EasyRight_x86_64"

echo "🔗 [Build] 使用 lipo 创建宿主主程序的 Universal 胖二进制文件..."
lipo -create -output "$APP_BUNDLE/Contents/MacOS/EasyRight" "$BUILD_DIR/EasyRight_arm64" "$BUILD_DIR/EasyRight_x86_64"

# 动态 .service 的微型转发 helper，不包含动作引擎或设置逻辑。
echo "🛠️ [Build] 编译 Finder 快捷服务 helper (Universal)..."
QUICK_SERVICE_SOURCES="
    Sources/EasyRightQuickService/main.swift \
    Sources/EasyRight/Core/FinderQuickServiceProtocol.swift
"
swiftc -Onone -sdk "$SDK_PATH" -vfsoverlay "$BUILD_DIR/overlay.yaml" \
    -target arm64-apple-macosx13.0 $QUICK_SERVICE_SOURCES \
    -o "$BUILD_DIR/EasyRightQuickService_arm64"
swiftc -Onone -sdk "$SDK_PATH" -vfsoverlay "$BUILD_DIR/overlay.yaml" \
    -target x86_64-apple-macosx13.0 $QUICK_SERVICE_SOURCES \
    -o "$BUILD_DIR/EasyRightQuickService_x86_64"
lipo -create \
    -output "$APP_BUNDLE/Contents/Resources/EasyRightQuickService" \
    "$BUILD_DIR/EasyRightQuickService_arm64" \
    "$BUILD_DIR/EasyRightQuickService_x86_64"


# 7. 编译 Finder Sync 插件 (arm64 与 x86_64)
echo "🛠️ [Build] 编译 Finder Sync 扩展插件 (arm64)..."
swiftc $COMMON_FLAGS -target arm64-apple-macosx13.0 $EXT_SOURCES -o "$BUILD_DIR/EasyRightExtension_arm64"

echo "🛠️ [Build] 编译 Finder Sync 扩展插件 (x86_64)..."
swiftc $COMMON_FLAGS -target x86_64-apple-macosx13.0 $EXT_SOURCES -o "$BUILD_DIR/EasyRightExtension_x86_64"

echo "🔗 [Build] 使用 lipo 创建扩展插件的 Universal 胖二进制文件..."
lipo -create -output "$EXT_BUNDLE/Contents/MacOS/EasyRightExtension" "$BUILD_DIR/EasyRightExtension_arm64" "$BUILD_DIR/EasyRightExtension_x86_64"


# 8. 编译 ActionVerifier 工具 (arm64 与 x86_64)
echo "🛠️ [Build] 编译 ActionVerifier 校验程序 (arm64)..."
swiftc -Onone -parse-as-library -sdk $SDK_PATH -vfsoverlay "$BUILD_DIR/overlay.yaml" -target arm64-apple-macosx13.0 Sources/ActionVerifier/ActionVerifier.swift -o "$BUILD_DIR/ActionVerifier_arm64"

echo "🛠️ [Build] 编译 ActionVerifier 校验程序 (x86_64)..."
swiftc -Onone -parse-as-library -sdk $SDK_PATH -vfsoverlay "$BUILD_DIR/overlay.yaml" -target x86_64-apple-macosx13.0 Sources/ActionVerifier/ActionVerifier.swift -o "$BUILD_DIR/ActionVerifier_x86_64"

echo "🔗 [Build] 使用 lipo 创建 ActionVerifier 的 Universal 胖二进制文件..."
lipo -create -output "ActionVerifier_bin" "$BUILD_DIR/ActionVerifier_arm64" "$BUILD_DIR/ActionVerifier_x86_64"


# 9. 对生成的程序和扩展进行签名
echo "🔐 [Build] 选取 Entitlements 模板（按 DISTRIBUTION_ROUTE）..."
# 模板外置在 entitlements/ 目录下，便于审计与版本对比；不再走 here-doc 动态生成。
# 三个文件 source-of-truth：
#   entitlements/website.host.entitlements  → website-dev / website-release
#   entitlements/mas.host.entitlements      → mac-app-store（本轮 build.sh 未启用，仅占位）
#   entitlements/extension.entitlements     → 三条路线共用（FinderSync 必须 sandbox + AppGroup）
case "$DISTRIBUTION_ROUTE" in
    website-dev|website-release)
        HOST_ENTITLEMENTS="entitlements/website.host.entitlements"
        ;;
    mac-app-store)
        HOST_ENTITLEMENTS="entitlements/mas.host.entitlements"
        ;;
    *)
        echo "❌ [Build] 未识别的 DISTRIBUTION_ROUTE=$DISTRIBUTION_ROUTE，无法定位 host entitlements 模板"
        exit 2
        ;;
esac
EXT_ENTITLEMENTS="entitlements/extension.entitlements"

for f in "$HOST_ENTITLEMENTS" "$EXT_ENTITLEMENTS"; do
    if [ ! -f "$f" ]; then
        echo "❌ [Build] 找不到 entitlements 模板: $f"
        exit 2
    fi
done

cp "$HOST_ENTITLEMENTS" "$BUILD_DIR/EasyRight.entitlements"
cp "$EXT_ENTITLEMENTS"  "$BUILD_DIR/EasyRightExtension.entitlements"

echo "🔐 [Build] 自动进行嵌套签名..."
# A. 先签名最内层插件的二进制与整个 XPC 插件 bundle
codesign --force --sign "$CODE_SIGN_IDENTITY" $CODESIGN_RUNTIME_ARGS --entitlements "$BUILD_DIR/EasyRightExtension.entitlements" "$EXT_BUNDLE/Contents/MacOS/EasyRightExtension"
codesign --force --sign "$CODE_SIGN_IDENTITY" $CODESIGN_RUNTIME_ARGS --entitlements "$BUILD_DIR/EasyRightExtension.entitlements" "$EXT_BUNDLE"
codesign --force --sign "$CODE_SIGN_IDENTITY" $CODESIGN_RUNTIME_ARGS "$APP_BUNDLE/Contents/Resources/EasyRightQuickService"

# B. 再签名主程序二进制。官网分发路线保持主 App 非沙盒，并在 website-release 下启用 hardened runtime。
# B. 主 App 二进制 + 整个 .app Bundle 都用 host entitlements 模板。
#    历史上这两行都漏了 --entitlements，导致主 App 实际是 adhoc 无 entitlements；
#    本轮 build.sh 重构后必须显式传入，否则 application-groups 不生效，
#    SharedStorageManager 与 FinderSync 之间的 cross-container 物理路径访问会被
#    macOS 13+ Hidden Subsystem Block 拦截。
codesign --force --sign "$CODE_SIGN_IDENTITY" $CODESIGN_RUNTIME_ARGS --entitlements "$BUILD_DIR/EasyRight.entitlements" "$APP_BUNDLE/Contents/MacOS/EasyRight"
codesign --force --sign "$CODE_SIGN_IDENTITY" $CODESIGN_RUNTIME_ARGS --entitlements "$BUILD_DIR/EasyRight.entitlements" "$APP_BUNDLE"

# D. 签名自检程序
codesign --force --sign "$CODE_SIGN_IDENTITY" $CODESIGN_RUNTIME_ARGS "ActionVerifier_bin"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
codesign --verify --strict --verbose=2 "$APP_BUNDLE/Contents/Resources/EasyRightQuickService"

if [ "$DISTRIBUTION_ROUTE" = "website-release" ]; then
    echo "🧾 [Build] 提交 App 到 Apple notary service 并 stapler 附票..."
    NOTARY_ZIP="$BUILD_DIR/EasyRight-notary.zip"
    rm -f "$NOTARY_ZIP"
    ditto -c -k --keepParent "$APP_BUNDLE" "$NOTARY_ZIP"
    submit_for_notarization "$NOTARY_ZIP"
    xcrun stapler staple "$APP_BUNDLE"
    xcrun stapler validate "$APP_BUNDLE"
    rm -f "$NOTARY_ZIP"
fi

# 10. 打包压缩为 Distribution 压缩包与 DMG 磁盘映像
echo "📦 [Build] 正在打包压缩为 distributable .zip 绿色免安装版..."
(cd "$BUILD_DIR" && zip -r -q "EasyRight.zip" "$APP_NAME.app")

echo "📦 [Build] 开始构建 Drag-to-Install DMG 磁盘映像..."
DMG_TEMP_DIR="$BUILD_DIR/dmg_temp"
rm -rf "$DMG_TEMP_DIR"
mkdir -p "$DMG_TEMP_DIR"
touch "$DMG_TEMP_DIR/.metadata_never_index"

# A. 拷贝 App 以及 Applications 快捷方式
cp -R "$APP_BUNDLE" "$DMG_TEMP_DIR/"
ln -s /Applications "$DMG_TEMP_DIR/Applications"
if [ -f "$BUILD_DIR/AppIcon.icns" ]; then
    cp "$BUILD_DIR/AppIcon.icns" "$DMG_TEMP_DIR/.VolumeIcon.icns"
fi

# B. 创建原始可写 DMG (UDRW 格式)
RAW_DMG="$BUILD_DIR/EasyRight_raw.dmg"
echo "⚡ [Build] 清理前次 CI 残留的 DMG 挂载..."
hdiutil detach "/Volumes/EasyRight" >/dev/null 2>&1 || true
rm -f "$RAW_DMG"
for attempt in 1 2 3; do
    if hdiutil create -volname "EasyRight" -srcfolder "$DMG_TEMP_DIR" -ov -format UDRW "$RAW_DMG" >/dev/null 2>&1; then
        break
    fi
    echo "⚠️ [Build] hdiutil create 失败（attempt $attempt/3），重试..."
    sleep 2
done
if [ ! -f "$RAW_DMG" ]; then
    echo "❌ [Build] hdiutil create 三次重试均失败，退出。"
    exit 1
fi

# C. 静默挂载原始 DMG 以便调用 AppleScript 写入 Finder 窗口对称排版元数据
echo "🎨 [Build] 静默挂载临时磁盘映像并启动 Finder 视觉排版排布..."
device=$(hdiutil attach -nobrowse -readwrite "$RAW_DMG" 2>/dev/null | egrep '/Volumes/' | awk '{print $1}' || true)
if [ -n "$device" ]; then
    sleep 1
    if [ -f "$BUILD_DIR/AppIcon.icns" ] && [ -d "/Volumes/EasyRight" ]; then
        cp "$BUILD_DIR/AppIcon.icns" "/Volumes/EasyRight/.VolumeIcon.icns" 2>/dev/null || true
        SetFile -c icnC "/Volumes/EasyRight/.VolumeIcon.icns" 2>/dev/null || true
        SetFile -a C "/Volumes/EasyRight" 2>/dev/null || true
        SetFile -a V "/Volumes/EasyRight/.VolumeIcon.icns" 2>/dev/null || true
    fi
    osascript -e '
    tell application "Finder"
        try
            tell disk "EasyRight"
                open
                delay 0.5
                set containerWindow to container window of disk "EasyRight"
                set current view of containerWindow to icon view
                set toolbar visible of containerWindow to false
                set statusbar visible of containerWindow to false
                set the bounds of containerWindow to {400, 200, 950, 560}
                set icon size of icon view options of containerWindow to 128
                set arrangement of icon view options of containerWindow to not arranged
                set position of item "EasyRight.app" to {150, 180}
                set position of item "Applications" to {400, 180}
                delay 0.5
                close containerWindow
            end tell
        end try
    end tell
    ' 2>/dev/null || true
    sync
    hdiutil detach "/Volumes/EasyRight" -force >/dev/null 2>&1 || true
    hdiutil detach "$device" -force >/dev/null 2>&1 || true
fi
sync
for i in {1..10}; do
    if [ ! -d "/Volumes/EasyRight" ]; then
        break
    fi
    hdiutil detach "/Volumes/EasyRight" -force >/dev/null 2>&1 || true
    sleep 0.5
done
sleep 1

# D. 转换为正式发布版只读高压缩 DMG (UDZO 格式)
FINAL_DMG="$BUILD_DIR/EasyRight.dmg"
rm -f "$FINAL_DMG"
echo "⚡ [Build] 正在将原始映像转换为只读高压缩分发级 DMG..."
hdiutil convert "$RAW_DMG" -format UDZO -o "$FINAL_DMG" >/dev/null

if [ "$DISTRIBUTION_ROUTE" = "website-release" ]; then
    echo "🧾 [Build] 提交 DMG 到 Apple notary service 并 stapler 附票..."
    submit_for_notarization "$FINAL_DMG"
    xcrun stapler staple "$FINAL_DMG"
    xcrun stapler validate "$FINAL_DMG"
fi

# E. 清理临时过渡资源
rm -f "$RAW_DMG"
rm -rf "$DMG_TEMP_DIR"

echo "=============================================================================="
echo "🎉 [Build] 成功！应用已成功编译并完成双格式打包分发。"
echo "📍 宿主应用路径: $APP_BUNDLE"
echo "📦 绿色免安装版: $BUILD_DIR/EasyRight.zip"
echo "📀 拖拽式安装版: $BUILD_DIR/EasyRight.dmg"
echo "🧪 校验程序路径: ./ActionVerifier_bin"
echo "=============================================================================="
