#!/bin/bash

# ==============================================================================
# 开源EasyRight (EasyRight) 卸载与旧进程清理工具
# ==============================================================================
set -e

echo "🧹 [Uninstall] 开始卸载EasyRight并清理旧进程..."

# 1. 物理注销和反注册所有的 FinderSync 插件 (包括旧 org.antigravity 和新 guyue)
echo "🔌 [Uninstall] 1. 反注册和卸载系统中的 FinderSync 插件..."
pluginkit -r com.easyright.app.extension 2>/dev/null || true
pluginkit -r org.antigravity.EasyRight.Extension 2>/dev/null || true
pluginkit -r "/Applications/EasyRight.app/Contents/PlugIns/EasyRightExtension.appex" 2>/dev/null || true
pluginkit -r "build/EasyRight.app/Contents/PlugIns/EasyRightExtension.appex" 2>/dev/null || true
pluginkit -e ignore -i com.easyright.app.extension 2>/dev/null || true

# 2. 终止常驻的主宿主 App 进程与扩展插件
echo "🛑 [Uninstall] 2. 终止常驻保活的主程序与扩展进程..."
killall EasyRight 2>/dev/null || true
killall EasyRightExtension 2>/dev/null || true

# 3. 删除动态系统服务与快捷操作，注销 LaunchServices
echo "🧩 [Uninstall] 3. 清除动态系统服务与注销 LaunchServices..."
SERVICE_PATH="$HOME/Library/Services/EasyRightQuickActions.service"
if [ -e "$SERVICE_PATH" ]; then
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$SERVICE_PATH" 2>/dev/null || true
    rm -rf "$SERVICE_PATH"
fi
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "/Applications/EasyRight.app" 2>/dev/null || true
killall pbs 2>/dev/null || true
/usr/bin/osascript -l JavaScript \
  -e 'ObjC.import("AppKit"); $.NSUpdateDynamicServices();' 2>/dev/null || true

# 4. 删除主 App 部署包
echo "🗑️ [Uninstall] 4. 清除 /Applications 目录下的主程序..."
rm -rf "/Applications/EasyRight.app"

# 5. 清理共享中介目录、持久化配置与 UserDefaults
echo "📂 [Uninstall] 5. 清除持久化配置、UserDefaults 与容器缓存..."
defaults delete com.easyright.app 2>/dev/null || true
defaults delete group.com.easyright.app 2>/dev/null || true
rm -rf "$HOME/Library/Application Support/EasyRight" 2>/dev/null || true
rm -rf "$HOME/Library/Caches/com.easyright.app" 2>/dev/null || true
rm -f "$HOME/Library/Preferences/com.easyright.app.plist" 2>/dev/null || true

# 注意：macOS 限制直接 rm -rf Data 根目录，只清理其内部文件与子目录
if [ -d "$HOME/Library/Containers/com.easyright.app.extension/Data" ]; then
    find "$HOME/Library/Containers/com.easyright.app.extension/Data" -mindepth 1 -maxdepth 1 -not -name "Library" -not -name "SystemData" -not -name ".com.apple.*" -exec rm -rf {} + 2>/dev/null || true
    rm -rf "$HOME/Library/Containers/com.easyright.app.extension/Data/Library/Application Support/EasyRight" 2>/dev/null || true
fi
if [ -d "$HOME/Library/Containers/org.antigravity.EasyRight.Extension/Data" ]; then
    find "$HOME/Library/Containers/org.antigravity.EasyRight.Extension/Data" -mindepth 1 -maxdepth 1 -not -name "Library" -not -name "SystemData" -not -name ".com.apple.*" -exec rm -rf {} + 2>/dev/null || true
fi
if [ -d "$HOME/Library/Group Containers/group.com.easyright.app" ]; then
    find "$HOME/Library/Group Containers/group.com.easyright.app" -mindepth 1 -maxdepth 1 -not -name ".com.apple.*" -exec rm -rf {} + 2>/dev/null || true
fi

# 6. 重启访达 (Finder)，释放扩展 XPC 会话
echo "🔄 [Uninstall] 6. 重启访达进程以释放扩展缓存..."
killall Finder 2>/dev/null || true

echo "=============================================================================="
echo "🟢 [Uninstall] 卸载与缓存清理完成。"
echo "=============================================================================="
