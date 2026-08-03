#!/bin/bash
# ha.sh — Agent 控制 Home Assistant 的快捷脚本
# 用法:
#   ha.sh states                          # 所有实体状态
#   ha.sh state <entity_id>               # 单个实体状态
#   ha.sh call <domain> <service> <entity_id> [参数JSON]   # 调用服务
#   ha.sh entity <关键字>                  # 按关键字查找实体
# 示例:
#   ha.sh call climate.xxx set_temperature {"temperature":24}
#   ha.sh call switch.xxx turn_on
#
# 配置：HA_URL 环境变量（默认本机 8123）；token 从 ~/homeassistant/ha-llt.txt 读（或用 HA_TOKEN 覆盖）

HA_URL="${HA_URL:-http://127.0.0.1:8123}"
HA_TOKEN="${HA_TOKEN:-$(cat ~/homeassistant/ha-llt.txt 2>/dev/null)}"
AUTH="Authorization: Bearer $HA_TOKEN"

[ -z "$HA_TOKEN" ] && { echo "ERROR: 无 HA token（请配置 ~/homeassistant/ha-llt.txt 或 HA_TOKEN）"; exit 1; }

case "$1" in
  states)
    curl -s --max-time 15 -H "$AUTH" "$HA_URL/api/states" | python3 -c "
import sys, json
states = json.load(sys.stdin)
for s in sorted(states, key=lambda x: x['entity_id']):
    attrs = s.get('attributes', {})
    name = attrs.get('friendly_name', '')
    print(f\"{s['entity_id']} | {s['state']} | {name}\")
"
    ;;
  state)
    curl -s --max-time 15 -H "$AUTH" "$HA_URL/api/states/$2" | python3 -m json.tool 2>/dev/null || echo "实体不存在"
    ;;
  call)
    # ha.sh call <domain> <service> <entity_id> [json]
    shift
    domain="$1"; service="$2"; entity="$3"; extra="${4:-}"
    body="{\"entity_id\": \"$entity\""
    [ -n "$extra" ] && body="$body, $extra"
    body="$body}"
    curl -s --max-time 15 -X POST -H "$AUTH" -H "Content-Type: application/json" \
      -d "$body" "$HA_URL/api/services/$domain/$service" | python3 -m json.tool 2>/dev/null | head -30
    ;;
  entity)
    curl -s --max-time 15 -H "$AUTH" "$HA_URL/api/states" | python3 -c "
import sys, json
kw = '$2'.lower()
states = json.load(sys.stdin)
for s in sorted(states, key=lambda x: x['entity_id']):
    if kw in s['entity_id'].lower() or kw in s.get('attributes', {}).get('friendly_name', '').lower():
        print(f\"{s['entity_id']} | {s['state']} | {s.get('attributes', {}).get('friendly_name', '')}\")
"
    ;;
  *)
    echo "用法: ha.sh {states|state|call|entity} ..."
    ;;
esac
