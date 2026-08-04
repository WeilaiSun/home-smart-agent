# 🧠 Home Smart Agent — 让家居设备拥有大脑

> 把 Home Assistant 变成 AI Agent 的"身体"，让 Agent 拥有眼睛（摄像头）、耳朵（麦克风）、手脚（智能设备），与真实物理世界联结和互动。家居设备从此有了大脑和记忆。

**实现语言无关**：任何支持执行 shell 脚本 + 定时任务的 AI Agent（Hermes / Claude Code / OpenCode / Cursor 等）都能接入。

---

## ⚡ 给 AI Agent 的一句话指令

> 复制下面这段话发给你的 AI Agent（Hermes / Claude Code / OpenCode 等），它就能自动搭建整套方案：

```
你是智能家居搭建助手。请在当前机器上搭建「Home Assistant + AI Agent 连接」方案，
仓库参考 https://github.com/WeilaiSun/home-smart-agent （如果本机没有这个仓库，先 clone 或按内容重建）。

步骤：
1. 读 README.md 理解架构
2. 按 docs/01-ha-core-setup.md 在本机部署 Home Assistant Core（macOS 用 venv，不需要 Docker；Linux 用官方安装方式），确保 http://127.0.0.1:8123 可用
3. 按 docs/02-xiaomi-devices.md 接入小米设备（QR 扫码登录提取 token，Local 模式接入，不要用密码+验证码路径——会被风控拦截）
4. 按 docs/03-camera-cloud.md 接入纯云摄像头（无 RTSP 老型号也能用云回放）
5. 按 docs/04-agent-integration.md 配置 Agent 与 HA 集成（ha.sh 控制脚本 + 定时任务）
6. 参考 examples/pet-watch-cron.md 建立「宠物监控定时汇报」案例

每个文档都包含完整命令和坑位提示，遇到失败先看 docs/05-troubleshooting.md，再根据报错自行排查，不要跳过步骤，不要问用户，全部自动完成。
注意：小米设备 token 提取需要 QR 扫码（米家 app），二维码出现时提醒用户扫码（这是唯一需要人工配合的环节）。
```

**📂 仓库直达：[https://github.com/WeilaiSun/home-smart-agent](https://github.com/WeilaiSun/home-smart-agent)**

> 💡 想先了解再动手？[点这里浏览仓库](https://github.com/WeilaiSun/home-smart-agent) 查看完整文档和案例；想让 Agent 自动搭建，把上面代码块里的指令整段复制给它即可。

---

## 🏗️ 架构

```
                    ┌─────────────────────────────────────┐
                    │          AI Agent（大脑）            │
                    │  Hermes / Claude Code / OpenCode     │
                    │  定时任务 · 视觉分析 · 记忆 · 决策    │
                    └──────────────┬──────────────────────┘
                                   │ HTTP API（token 鉴权）
                    ┌──────────────▼──────────────────────┐
                    │    Home Assistant Core（身体中枢）    │
                    │    macOS venv / Linux  · 本地 8123   │
                    └──┬────────────┬────────────┬────────┘
                       │            │            │
          ┌────────────▼───┐  ┌─────▼──────┐  ┌─▼──────────────┐
          │ 智能插座/开关   │  │ 温控设备    │  │ 摄像头（两种）   │
          │ (Local 直连)   │  │ (云/本地)   │  │ ①电脑USB 实时帧  │
          └────────────────┘  └────────────┘  │ ②小米纯云 回放帧 │
                                             └─────────────────┘
```

## ✨ 能做什么

| 能力 | 说明 |
|---|---|
| 👀 **看家** | Agent 定时/随时抓取摄像头画面，视觉分析宠物、家人、异常 |
| 💡 **控制** | 语音或文本指令控制插座、灯光、空调（`ha.sh call switch.xxx turn_on`） |
| 🎙️ **听说** | 配合本地 STT/TTS，Agent 有耳朵和嘴巴（见 docs/04） |
| 🧠 **记忆** | Agent 记住设备状态、家庭习惯，主动决策（如"白天开客厅灯"） |
| ⏰ **例行** | 定时汇报（宠物监控、安全巡检、能耗日报） |

## 📦 仓库结构

```
home-smart-agent/
├── README.md                  ← 你在这里
├── docs/
│   ├── 01-ha-core-setup.md    # HA Core 本地部署（macOS venv / Linux）
│   ├── 02-xiaomi-devices.md   # 小米设备接入（QR 登录 + token + Local/云模式）
│   ├── 03-camera-cloud.md     # 纯云摄像头接入（云回放 + camera_proxy 取帧）
│   ├── 04-agent-integration.md# Agent ↔ HA 集成（ha.sh + 定时任务 + 语音扩展）
│   └── 05-troubleshooting.md  # 坑位与排查
├── scripts/
│   ├── ha.sh                  # HA 控制脚本（查状态/调服务）
│   ├── smart-cam.sh           # 电脑摄像头抓帧
│   └── smart-cam-xiaomi.sh    # 小米摄像头云回放取帧
└── examples/
    └── pet-watch-cron.md      # 🐱 看筒筒案例：宠物监控定时汇报
```

## 🚀 快速开始（30 分钟版）

```bash
# 1. 部署 HA Core（macOS 示例，详见 docs/01）
git clone --depth 1 https://github.com/home-assistant/core.git ~/homeassistant/core
cd ~/homeassistant/core && python3 -m venv ~/homeassistant/venv
~/homeassistant/venv/bin/pip install -r requirements_all.txt
# 配置后启动：~/homeassistant/venv/bin/python -m homeassistant --config ~/homeassistant/config
# → http://127.0.0.1:8123

# 2. 添加设备（小米示例，详见 docs/02）
#    QR 扫码登录提取 token → HA Flow API 添加 → Local 模式接入

# 3. Agent 控制（详见 docs/04）
cp scripts/ha.sh ~/.hermes/scripts/ && chmod +x ~/.hermes/scripts/ha.sh
export HA_TOKEN="你的长令牌"   # HA 配置 → 安全 → 长期访问令牌
~/.hermes/scripts/ha.sh states   # 看所有设备状态
~/.hermes/scripts/ha.sh call switch.xxx turn_on   # 开一个设备

# 4. 摄像头 + 定时汇报（看筒筒案例，详见 examples/pet-watch-cron.md）
```

## 🐱 案例：看筒筒（宠物监控）

工作日 9/11/13/15/17 点，Agent 自动抓取卧室+客厅两个摄像头画面，视觉分析宠物在哪、在干嘛，用家人唠嗑的语气配上照片发到家庭群。完整 cron 配置见 `examples/pet-watch-cron.md`。

## 📜 许可

MIT — 自由使用、修改、分享。保留出处即可。

---

*Built with ❤️ 由大圣与 Hermes 协作完成。家居智能的下一步，是让 Agent 真正"住"进家里。*
