#!/usr/bin/env bash
# 鲨猪桌宠一键安装（macOS / Linux）
#
# 做四件事：检查 Node → 装 DSH → 装带鲨猪的 dsh-pet → 启动并自检
# 用法：
#   bash install-sharkpig.sh
#   bash install-sharkpig.sh --no-start
# 幂等，可重复运行。

set -euo pipefail

TAG="${TAG:-v0.4.1-sharkpig.2}"
NO_START=0
for a in "$@"; do [ "$a" = "--no-start" ] && NO_START=1; done

info() { printf '\033[36m[鲨猪]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[鲨猪]\033[0m %s\n' "$*"; }
fail() { printf '\033[31m[鲨猪]\033[0m %s\n' "$*"; exit 1; }

# ---------- 1) Node ----------
info "检查 Node.js ..."
command -v node >/dev/null 2>&1 || fail "没有 Node.js。请先安装 https://nodejs.org （LTS）后重跑。"
NODE_V="$(node -v | tr -d 'v')"
MAJOR="${NODE_V%%.*}"; REST="${NODE_V#*.}"; MINOR="${REST%%.*}"
if [ "$MAJOR" -lt 22 ] || { [ "$MAJOR" -eq 22 ] && [ "$MINOR" -lt 12 ]; }; then
  fail "Node $NODE_V 太旧，需要 >= 22.12.0"
fi
info "Node 版本 OK：$NODE_V"

# ---------- 2) DSH ----------
if ! command -v dsh >/dev/null 2>&1; then
  info "安装 @deepseek-ai/dsh ..."
  npm i -g "@deepseek-ai/dsh@latest" --registry=https://registry.npmmirror.com \
    || npm i -g "@deepseek-ai/dsh@latest"
  command -v dsh >/dev/null 2>&1 || fail "DSH 安装失败：dsh 命令仍不可用"
fi
info "DSH 版本：$(dsh --version 2>/dev/null | head -n1)"

# ---------- 3) 插件 ----------
PROFILE_DIR="$HOME/.dsh/profiles/web"
PKG_JSON="$PROFILE_DIR/node_modules/dsh-pet/package.json"
INSTALLED=0
if [ -f "$PKG_JSON" ]; then
  V="$(node -e "process.stdout.write(require('$PKG_JSON').version||'')" 2>/dev/null || true)"
  case "$V" in
    *sharkpig*) info "已安装带修复的 dsh-pet $V（跳过）"; INSTALLED=1 ;;
    "") : ;;
    *) warn "已存在官方 dsh-pet $V，将覆盖为修复版" ;;
  esac
fi

if [ "$INSTALLED" -eq 0 ]; then
  TMP_TGZ="$(mktemp -t dshpet.XXXXXX).tgz"
  FILE="dsh-pet-${TAG#v}.tgz"
  URLS=(
    "https://gh-proxy.com/https://github.com/Zzzdaydayup/dsh-pet/releases/download/$TAG/$FILE"
    "https://github.com/Zzzdaydayup/dsh-pet/releases/download/$TAG/$FILE"
  )
  OK=0
  for u in "${URLS[@]}"; do
    info "下载安装包：$u"
    if curl -fL --max-time 900 -o "$TMP_TGZ" "$u" 2>/dev/null && [ -s "$TMP_TGZ" ]; then OK=1; break; fi
  done
  if [ "$OK" -eq 1 ]; then
    info "安装插件（本地 tgz）..."
    dsh plugin --profile web add "$TMP_TGZ"
  else
    warn "安装包下载失败，改用 git 源安装（需要能访问 github.com）"
    dsh plugin --profile web add "github:Zzzdaydayup/dsh-pet#path:/dsh-pet"
  fi
fi

# ---------- 4) 启动 + 自检 ----------
if [ "$NO_START" -eq 1 ]; then
  info "已跳过启动（--no-start）。手动运行：dsh web"
  exit 0
fi

info "启动 DSH（后台）..."
nohup dsh web >/tmp/dsh-web.log 2>&1 &
for _ in $(seq 1 20); do
  sleep 2
  if curl -fsS --max-time 5 http://127.0.0.1:3080/dsh-pet-7340/config 2>/dev/null | grep -q "鲨猪"; then
    info "自检通过：DSH 已启动，配置里能看到「鲨猪」"
    info "浏览器打开 http://127.0.0.1:3080 ，设置 → 桌宠配置 → 把「鲨猪」显示位置设为 web 或 both"
    exit 0
  fi
done

warn "DSH 已在后台启动，但还没检测到「鲨猪」。等 10 秒后重试："
warn "  curl http://127.0.0.1:3080/dsh-pet-7340/config"
warn "若仍没有，检查角色目录：$HOME/.dsh/dsh-pet/pet/"
exit 0
