# 05 · 坑位与排查

按踩坑频率排序。每个坑都有真实症状 + 解法。

## 1. HA 启动崩溃：KeyError 'discovery_keys'

手写 config_entries 时漏了字段。HA 新版要求 entry 必须带 `discovery_keys` 和 `modified_at`，否则启动直接 KeyError 崩溃循环。

**症状**：重启 HA 后起不来，日志 `KeyError: 'discovery_keys'`
**解法**：给 entry 补 `"discovery_keys": {}` 和 `"modified_at": "..."`。

## 2. 小米登录：密码+验证码必触发风控

**症状**：登录响应 `need_verify`，或者验证后拿不到 `ssecurity`
**解法**：QR 扫码登录（`q` 选项，浏览器出二维码，米家 app 扫码）。QR 路径直接下发 ssecurity。

## 3. launchd 下 HA 找不到 ffmpeg

**症状**：camera_proxy / ffmpeg 相关功能报 `[Errno 2] No such file or directory: 'ffmpeg'`，但手动跑正常
**原因**：launchd 环境默认 PATH 没有 `/usr/local/bin`
**解法**：plist 加 `EnvironmentVariables.PATH=/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin`，然后 unload → load（改 plist 必须重载才生效）。

## 4. 摄像头抓帧 401 / 无画面

- 裸 ffmpeg 拉 m3u8 会被拒（需要 UA/Cookie）→ 用 HA camera_proxy
- `camera_proxy` 需要动态 `access_token`（实体属性里取，不是 HA 长令牌）
- 确认用的是云模式实体（`_2` 后缀），本地实体（无后缀）对纯云摄像头是 unavailable
- m3u8 URL 有短有效期 → 生成后立即拉流

## 5. 实体 unavailable / 属性读取超时

- 设备离线（检查 IP 是否变化，DHCP 会换 IP → 设静态 IP 或 DHCP 保留）
- 纯云设备（chuangmi.camera.ipc009 等）本地 miOT 不支持 → 只能云模式

## 6. 视觉模型报错 / 图片打不开

- 部分视觉模型不接受任意格式 → 先转标准 RGB JPEG：
  ```bash
  python3 -c "from PIL import Image; Image.open('in.jpg').convert('RGB').save('out.jpg','JPEG',quality=90)"
  ```

## 7. Python venv 环境污染（PYTHONPATH）

多 venv 并存时，shell 的 PYTHONPATH 会污染新 venv（import 到别的环境的包）。

**症状**：加载慢 100 倍（95s vs 1s）、OMP Error #15、包版本错乱
**解法**：`env -u PYTHONPATH -u VIRTUAL_ENV python ...` 运行。

## 8. HF_HUB_OFFLINE（faster-whisper 加载随机卡死 120s）

**症状**：`WhisperModel(...)` 加载时快时慢（6s ~ 120s 随机），国内网络下尤其明显
**原因**：huggingface_hub 每次加载都检查远端（被墙超时）
**解法**：`export HF_HUB_OFFLINE=1`（在 import 之前）。

## 9. TCC 授权（macOS 麦克风/摄像头）

命令行裸二进制访问麦克风/摄像头：`requestAccess` 不弹窗、授权一直 notDetermined。

**解法**：
1. 把工具打包成 `.app`（Info.plist 声明用途 + ad-hoc 签名 `codesign --force --deep --sign -`）
2. 系统设置手动授权（隐私与安全性 → 麦克风/摄像头 → ＋ 添加）
3. **捷径**：如果宿主 GUI app（如 Hermes）已授权，其子进程直接继承，无需单独授权

## 10. macOS 语音识别（SFSpeechRecognizer）国内不可用

**症状**：授权能搞定（GUI app 弹窗），但识别永远超时/无结果
**原因**：云端识别连不上苹果服务器（国内网络）；on-device 中文语言包下载不了（系统服务不走用户代理）
**结论**：国内用云端 ASR（阿里云 paraformer / 讯飞）替代。

## 11. 其他

| 坑 | 解法 |
|---|---|
| `UID` 是只读变量（bash） | 写 cookie/脚本用 `MYUID` |
| brew 装 whisper.cpp 要编译 cmake 10-30 分钟 | 用预编译二进制或改 faster-whisper |
| GitHub API 限流 | 加 token 或等 1 小时 |
| cron 里视觉分析报错 | 先转 JPEG（见 6） |
