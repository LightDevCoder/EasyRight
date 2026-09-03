#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "📦 [Install] 开始安装 EasyRight..."

# 1. 检查构建产物，不存在则自动构建
if [ ! -d "build/EasyRight.app" ]; then
    echo "🛠️ [Install] 未检测到 build/EasyRight.app，正在自动编译..."
    ./Scripts/build.sh
fi

# 2. 终止旧实例
echo "🛑 [Install] 终止旧的 EasyRight 进程..."
killall EasyRight 2>/dev/null || true
sleep 1

# 3. 安装到 /Applications
echo "📂 [Install] 复制 EasyRight.app 到 /Applications/..."
rm -rf "/Applications/EasyRight.app"
cp -R "build/EasyRight.app" "/Applications/"

# 4. 移除 quarantine 隔离属性
xattr -dr com.apple.quarantine "/Applications/EasyRight.app" 2>/dev/null || true

# 5. 注册与激活访达扩展
echo "🔌 [Install] 注册并激活 EasyRight 访达扩展..."
pluginkit -a "/Applications/EasyRight.app/Contents/PlugIns/EasyRightExtension.appex"
pluginkit -e use -i com.easyright.app.extension

# 6. 重启访达并启动主程序
echo "🔄 [Install] 刷新访达并启动 EasyRight..."
killall Finder 2>/dev/null || true
open "/Applications/EasyRight.app"

sleep 1.5

# 7. 检查运行状态
if pgrep -x "EasyRight" >/dev/null; then
    echo "🟢 [Install] EasyRight 主程序已成功启动 (PID: $(pgrep -x EasyRight | head -n 1))"
else
    echo "⚠️ [Install] 提示: EasyRight 进程未检测到，请手动运行 open /Applications/EasyRight.app"
fi

echo "=============================================================================="
echo "🎉 [Install] EasyRight 安装与激活成功！"
echo "👉 请在屏幕右上角菜单栏查看 EasyRight 图标，或在访达中右键体验右键菜单动作。"
echo "=============================================================================="
