#!/bin/bash
# smart-cam-xiaomi.sh — 小米摄像头（客厅/云回放）取帧
# 抓取最新运动事件画面（经 HA camera_proxy，无需直连小米云）
# 输出：成功 → 图片路径 + 运动事件时间；失败 → ERROR: 开头
#
# 配置：
#   CAMERA_ENTITY — 摄像头云模式实体（默认示例，改成你自己的）
#   HA_URL / token — 同 ha.sh（~/homeassistant/ha-llt.txt）
set -u

TOKEN_FILE=~/homeassistant/ha-llt.txt
CAMERA_ENTITY="${CAMERA_ENTITY:-camera.chuangmi_ipc009_20e3_camera_control_2}"
HA_URL="${HA_URL:-http://127.0.0.1:8123}"
OUTDIR=/tmp/xiaomicam

TOKEN=$(cat "$TOKEN_FILE" 2>/dev/null)
[ -z "$TOKEN" ] && { echo "ERROR: 无 HA token"; exit 1; }

mkdir -p "$OUTDIR"
TS=$(date +%Y%m%d-%H%M%S)

STATE=$(curl -s -m 10 "$HA_URL/api/states/$CAMERA_ENTITY" -H "Authorization: Bearer $TOKEN")
AT=$(echo "$STATE" | /usr/bin/python3 -c "import json,sys
try:
    print(json.load(sys.stdin).get('attributes',{}).get('access_token',''))
except Exception:
    print('')" 2>/dev/null)
MVT=$(echo "$STATE" | /usr/bin/python3 -c "import json,sys
try:
    print(json.load(sys.stdin).get('attributes',{}).get('motion_video_time',''))
except Exception:
    print('')" 2>/dev/null)

if [ -z "$AT" ]; then
    echo "ERROR: 无法获取摄像头 access_token（实体可能 unavailable，检查云模式是否生效）"
    exit 1
fi

OUT="$OUTDIR/xiaomi-$TS.jpg"
curl -s -m 60 -o "$OUT" "$HA_URL/api/camera_proxy/$CAMERA_ENTITY?token=$AT"

if file "$OUT" 2>/dev/null | grep -q "JPEG"; then
    echo "$OUT"
    echo "motion_time: ${MVT:-未知}"
else
    echo "ERROR: 小米摄像头抓帧失败"
    rm -f "$OUT"
    exit 1
fi
