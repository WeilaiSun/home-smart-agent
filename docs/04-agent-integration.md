# 04 · Agent ↔ HA 集成

Agent（Hermes / Claude Code / OpenCode / Cursor 等）通过 `ha.sh` 与 HA 交互，再配合定时任务、视觉分析、语音，构成完整的"大脑—身体"闭环。

## 1. 控制脚本 ha.sh

```bash
cp scripts/ha.sh ~/你的脚本目录/ha.sh && chmod +x ~/你的脚本目录/ha.sh

# 用法
ha.sh states                                # 所有设备状态
ha.sh state switch.xxx                      # 单个实体
ha.sh entity 插座                            # 按关键字找实体
ha.sh call switch.xxx turn_on               # 开
ha.sh call climate.xxx set_temperature '{"temperature":24}'  # 调温
```

脚本从 `~/homeassistant/ha-llt.txt` 读 token（环境变量 `HA_TOKEN` 可覆盖），**不要把 token 写进脚本/仓库**。

## 2. 定时任务（cron）

以 Hermes 为例（其他 Agent 用系统 crontab 同理）：

```bash
# 每天 9-17 点整点看宠物（cron 表达式）
0 9,11,13,15,17 * * 1-5
```

任务 prompt 要点（完整案例见 `examples/pet-watch-cron.md`）：
- 脚本输出**图片路径**或 `ERROR:` 前缀（Agent 据此判断成败）
- 图片先用 PIL 转标准 RGB JPEG 再交给视觉模型（很多视觉模型不吃任意格式）
- 让 Agent 用自然语气汇报，附上 MEDIA 图片路径

## 3. 视觉分析（Agent 的"眼睛"）

```bash
# 抓帧 → 分析（Agent 内置视觉能力）
bash ~/scripts/smart-cam.sh          # 电脑摄像头（USB/内置）
bash ~/scripts/smart-cam-xiaomi.sh   # 小米摄像头云回放（客厅）
# 输出：图片路径 → 交给 Agent 的 vision 工具分析
```

## 4. 语音扩展（Agent 的"耳朵/嘴巴"）

可选的语音闭环（方案取舍见下）：
- **STT（听）**：阿里云 paraformer（微信/飞书同款引擎，质量最高）；本地 faster-whisper（离线兜底）
- **TTS（说）**：macOS `say -v Tingting`（离线）或 edge-tts（免费、质量高）
- **唤醒词**：简单能量检测 + STT 转写匹配；或 Hermes 官方 Wake Word（openWakeWord "hey hermes" 本地模型）

> ⚠️ 实测结论：macOS 自带 SFSpeechRecognizer 在国内不可用（云端连不上苹果服务器、on-device 语言包下载不了）；英文唤醒词 "Hermes" 对中文 ASR 识别不可靠。语音方案建议云端 ASR（阿里云 paraformer）+ 中文唤醒词。

## 5. 进阶：Agent 主动决策

有了状态感知 + 定时任务，Agent 可以主动：
- 检测到摄像头运动事件 → 推送到家庭群（带照片）
- 定时查能耗 → 日报
- 结合天气/时间 → 建议开灯/关窗

**安全提醒**：HA 长期令牌是管理员权限，只放在本机、勿提交到仓库。
