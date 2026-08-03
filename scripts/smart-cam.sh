#!/bin/bash
# smart-cam.sh — 电脑摄像头（USB/内置）抓帧
# 触发本机摄像头抓帧 app，等待最新帧生成
# 输出：成功 → 图片路径；失败 → ERROR: 开头
#
# 依赖：一个能"打开即抓一帧到 /tmp/petcam/latest.jpg"的摄像头 app
# 参考 https://github.com/WeilaiSun/pet-cam-agent 有现成实现（PetCam.app，Swift 零依赖）

PETCAM_APP="${PETCAM_APP:-$HOME/.hermes/scripts/petcam/PetCam.app}"
OUTDIR=/tmp/petcam

mkdir -p "$OUTDIR"
rm -f "$OUTDIR/latest.jpg" "$OUTDIR/error.txt"

[ -d "$PETCAM_APP" ] || { echo "ERROR: 摄像头 app 不存在（$PETCAM_APP）"; exit 1; }

open "$PETCAM_APP"

for i in $(seq 1 12); do
  sleep 5
  [ -f "$OUTDIR/latest.jpg" ] && break
  [ -f "$OUTDIR/error.txt" ] && break
done

if [ -f "$OUTDIR/latest.jpg" ]; then
  echo "$OUTDIR/latest.jpg"
else
  echo "ERROR: camera capture failed"
fi
