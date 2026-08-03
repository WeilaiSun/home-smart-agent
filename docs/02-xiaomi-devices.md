# 02 · 小米设备接入（QR 登录 + token + 接入 HA）

小米设备（米家生态）接入 HA 的两条路：
- **Local 模式**（推荐）：提取设备局域网 token → HA 直接连设备（毫秒级、不依赖小米云）
- **云模式**：用小米云 API 控制/回放（摄像头等纯云设备必需）

## ⚠️ 最重要的坑：登录风控

小米账号**密码+短信验证码路径必触发风控**（`need_verify` 且拿不到 API 签名密钥 `ssecurity`），死路。

**正解 = QR 扫码登录**：QR 路径（longPolling）登录响应直接下发 `ssecurity`，绕开一切风控。已验证可行。

## 提取设备 token（QR 扫码）

使用社区工具 [PiotrMachowski/Xiaomi-cloud-tokens-extractor](https://github.com/PiotrMachowski/Xiaomi-cloud-tokens-extractor)：

```bash
git clone https://github.com/PiotrMachowski/Xiaomi-cloud-tokens-extractor.git /tmp/xiaomi-token-extractor
cd /tmp/xiaomi-token-extractor
python3 -m venv venv && venv/bin/pip install -r requirements.txt
# 交互式运行（PTY 终端）：
venv/bin/python token_extractor.py --host 127.0.0.1
# 输入 q → 浏览器打开 http://127.0.0.1:31415 出二维码 → 米家 app 扫码授权
# 输入 cn（中国服务器）→ 输出账号下所有设备的 token
```

输出示例（保存到 `~/homeassistant/config/xiaomi-tokens.json`）：
```json
{
  "devices": [
    {"name": "智能插座", "model": "giot.plug.v7icw", "ip": "192.168.2.21", "token": "xxx"},
    {"name": "摄像头", "model": "chuangmi.camera.ipc009", "ip": "192.168.2.11", "token": "yyy"}
  ]
}
```

> 备用方案：也可以用 [xiaomi-cloud-tokens-extractor 网页版](https://github.com/PiotrMachowski/Xiaomi-cloud-tokens-extractor)（浏览器登录小米账号自动列出 token）。

## 预检 token 有效性

```bash
pip install python-miio
python3 -c "from miio import Device; print(Device('192.168.2.21', 'token').info())"
# 能打印设备信息 = token 有效
```

## 接入 HA（Local 模式，Flow API 免 UI）

HA 的集成添加可以用 REST API 完成（不需要点界面）：

```bash
# 1. 开始 flow
curl -X POST http://127.0.0.1:8123/api/config/config_entries/flow \
  -H "Authorization: Bearer $(cat ~/homeassistant/ha-llt.txt)" \
  -H "Content-Type: application/json" \
  -d '{"handler":"xiaomi_miot","show_advanced_options":false}'
# → 返回 flow_id + step_id（token）

# 2. 提交 token（用自己的 IP/token/名称）
curl -X POST http://127.0.0.1:8123/api/config/config_entries/flow/{flow_id} \
  -H "Authorization: Bearer $(cat ~/homeassistant/ha-llt.txt)" \
  -H "Content-Type: application/json" \
  -d '{"host":"192.168.2.21","token":"xxx","name":"智能插座"}'
# → 返回 entry 创建成功
```

实体示例：`switch.giot_v7icw_acb4_switch`（开关）、`button.giot_v7icw_acb4_info`。

**验证控制**：
```bash
# 开 / 关
curl -X POST http://127.0.0.1:8123/api/services/switch/turn_off \
  -H "Authorization: Bearer $(cat ~/homeassistant/ha-llt.txt)" \
  -H "Content-Type: application/json" -d '{"entity_id":"switch.giot_v7icw_acb4_switch"}'
```

## 云模式（摄像头等纯云设备）

纯云设备（无本地协议）需要云模式接入：
1. 用 QR 登录拿完整会话（ssecurity + serviceToken + userId + passToken）
2. 写进 HA 的 `config_entries`（云模式 entry，unique_id=`{user_id}-cn-xiaomiio`）
3. 手写 entry **必须带 `discovery_keys:{}` 和 `modified_at`**（否则 HA 启动 KeyError 崩溃循环）

详见 `03-camera-cloud.md`（摄像头云回放完整流程）。

## 其他品牌

- **海尔空调**：国内用 [banto6/haier](https://github.com/banto6/haier) 集成（hon 只支持海外 hOn 云，不支持国内海尔智家）；认证 = 抓包海尔智家小程序拿 `client_id + refresh_token`（appId/appKey 已内置源码）。⚠️ 部分海尔型号配网需要手机红外。
