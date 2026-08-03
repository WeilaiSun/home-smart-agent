# 03 · 纯云摄像头接入（老型号也能看）

场景：家里的摄像头是 2018 年老型号（如小米 `chuangmi.camera.ipc009`）——**没有 RTSP 实时流、不支持 miOT 属性读取**（本地只有老式 miIO 控制口）。这种"纯云摄像头"实时画面只能在米家 app 看，但**运动事件云回放**可以被 Agent 调用。

## 判断你的摄像头是否纯云

```bash
# 1. RTSP 端口探测（554 不通 = 大概率无实时流）
nc -z -w 3 <摄像头IP> 554 && echo "有 RTSP" || echo "无 RTSP"

# 2. HA 添加后本地实体是否可读（miOT get_properties 返回 user ack timeout = 不支持）
#    → Local 实体 unavailable，只能用云模式
```

## 云模式接入（三步）

### 1. 提取完整云会话（QR 登录拿 ssecurity）

用 `xiaomi-cloud-tokens-extractor` 的 `QrCodeXiaomiCloudConnector`（token_extractor.py 里），QR 登录响应直接含 `ssecurity`。保存会话：

```json
{
  "userId": "xxx",
  "ssecurity": "xxx",
  "serviceToken": "xxx",
  "cUserId": "xxx",
  "passToken": "xxx"
}
```

### 2. 写 HA config_entries（云模式 entry）

停 HA → 编辑 `~/homeassistant/config/.storage/core.config_entries` 追加 → 启 HA。

```python
entry = {
    "version": 1,
    "domain": "xiaomi_miot",
    "title": "小米云",
    "data": {
        "username": "手机号",
        "password": "占位",
        "server_country": "cn",
        "user_id": "xxx",
        "service_token": "xxx",
        "ssecurity": "xxx",
        "sid": "xiaomiio",
        "device_id": "xxx",
        "conn_mode": "auto",
        "filter_models": False,
        "config_version": 0.3,
    },
    "options": {},
    "pref_disable_new_entities": False,
    "pref_disable_polling": False,
    "source": "user",
    "unique_id": "xxx-cn-xiaomiio",
    "disabled_by": None,
    "created_at": "2026-01-01T00:00:00.000000Z",
    "modified_at": "2026-01-01T00:00:00.000000Z",
    "discovery_keys": {}   # ⚠️ 必须！否则 HA 启动 KeyError 崩溃
}
```

### 3. 重启后验证

云模式实体（后缀 `_2`）自动走云 API：状态正常、`motion_video_time` 自动刷新 = 成功。

## Agent 取帧（camera_proxy 一条命令）

HA 内置 `camera_proxy` 服务，Agent 无需直连小米云即可拿到画面：

```bash
# 1. 从实体属性拿 access_token（动态）
STATE=$(curl -s http://127.0.0.1:8123/api/states/camera.你的实体 \
  -H "Authorization: Bearer $(cat ~/homeassistant/ha-llt.txt)")
ACCESS_TOKEN=$(echo "$STATE" | python3 -c "import json,sys; print(json.load(sys.stdin)['attributes']['access_token'])")

# 2. 抓帧（输出 JPEG）
curl -s -o /tmp/snap.jpg "http://127.0.0.1:8123/api/camera_proxy/camera.你的实体?token=$ACCESS_TOKEN"
```

封装好的脚本：`scripts/smart-cam-xiaomi.sh`（自动取 token + 抓帧 + 输出最近运动事件时间）。

## 关键点

| 坑 | 说明 |
|---|---|
| m3u8 有短有效期 | 云回放 URL 生成后须立即用（脚本里已处理） |
| ffmpeg 带 UA/Cookie | 裸 ffmpeg 拉 m3u8 会 401（HA camera_proxy 已处理，用这个就行） |
| 实体 ID | `camera.xxx_control_2`（云模式）≠ `camera.xxx_control`（本地，unavailable） |
| launchd PATH | HA 在 launchd 下必须显式 PATH 含 ffmpeg（见 01 文档） |
