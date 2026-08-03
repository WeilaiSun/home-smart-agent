# 01 · Home Assistant Core 本地部署

目标：在本机跑一个常驻的 Home Assistant Core（http://127.0.0.1:8123），作为所有智能设备的中枢。**不需要 Docker**（保持零维护、开机自启）。

## macOS（venv 方式，已验证）

```bash
# 1. 依赖（Intel Mac 需要；Apple Silicon 类似）
brew install python@3.11 ffmpeg 2>/dev/null || true
# ffmpeg 是 HA 摄像头/语音功能需要的（launchd 环境找不到 ffmpeg 是个大坑，见下）

# 2. 拉源码 + 建 venv
git clone --depth 1 https://github.com/home-assistant/core.git ~/homeassistant/core
cd ~/homeassistant/core
python3.11 -m venv ~/homeassistant/venv

# 3. 安装依赖（国内可加 -i https://mirrors.aliyun.com/pypi/simple/）
~/homeassistant/venv/bin/pip install -r requirements_all.txt

# 4. 首次启动（生成配置）
mkdir -p ~/homeassistant/config
~/homeassistant/venv/bin/python -m homeassistant --config ~/homeassistant/config &
# 首次启动会创建 configuration.yaml，浏览器打开 http://127.0.0.1:8123 完成初始化（创建管理员账号）

# 5. 创建长期访问令牌
#    HA 界面 → 左下角用户名 → 安全 → 长期访问令牌 → 创建
#    保存到文件（Agent 脚本从这里读）：
echo "你的长令牌" > ~/homeassistant/ha-llt.txt && chmod 600 ~/homeassistant/ha-llt.txt
```

## launchd 开机自启（macOS）

`~/Library/LaunchAgents/com.dashen.homeassistant.plist`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.dashen.homeassistant</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/你/homeassistant/venv/bin/python</string>
        <string>-m</string>
        <string>homeassistant</string>
        <string>--config</string>
        <string>/Users/你/homeassistant/config</string>
    </array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>EnvironmentVariables</key>
    <dict>
        <!-- ⚠️ 必须显式 PATH，否则 launchd 环境找不到 ffmpeg（camera 功能隐性 broken） -->
        <key>PATH</key>
        <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
```

```bash
launchctl load ~/Library/LaunchAgents/com.dashen.homeassistant.plist
# 重启 = unload + pkill -f homeassistant + load
```

## Linux 方式

```bash
# 官方安装脚本（或手动 venv，同上）
curl -fsSL https://get.hass.io | bash
# 或直接 Docker：docker run -d --name ha --privileged -p 8123:8123 -v ~/homeassistant/config:/config ghcr.io/home-assistant/home-assistant:stable
```

## 验证

```bash
curl -s http://127.0.0.1:8123/api/ -H "Authorization: Bearer $(cat ~/homeassistant/ha-llt.txt)"
# → 返回 {"message": "API running."} 即成功
```
