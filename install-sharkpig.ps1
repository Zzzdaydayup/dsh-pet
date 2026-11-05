# 鲨猪桌宠一键安装（Windows PowerShell）
#
# 做四件事：装 Node 依赖检查 → 装 DSH → 装带鲨猪的 dsh-pet → 启动并自检
# 用法：
#   powershell -ExecutionPolicy Bypass -File .\install-sharkpig.ps1
#   powershell -ExecutionPolicy Bypass -File .\install-sharkpig.ps1 -NoStart   # 只装不启动
#
# 可重复运行（幂等）。

param(
  [string]$Tag = "v0.4.1-sharkpig.2",
  [switch]$NoStart
)

$ErrorActionPreference = "Stop"
$pkgName = "dsh-pet-$($Tag -replace '^v','')".Replace("dsh-pet-", "dsh-pet-")
function Info($m) { Write-Host "[鲨猪] $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "[鲨猪] $m" -ForegroundColor Yellow }
function Fail($m) { Write-Host "[鲨猪] $m" -ForegroundColor Red; exit 1 }

# ---------- 1) Node ----------
Info "检查 Node.js ..."
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) { Fail "没有 Node.js。请先安装 https://nodejs.org （LTS），重开终端后再运行。" }
$ver = (& node -v).Trim().TrimStart("v")
$major = [int]($ver -split "\.")[0]
$minor = [int](($ver -split "\.")[1])
if ($major -lt 22 -or ($major -eq 22 -and $minor -lt 12)) {
  Fail "Node $ver 太旧，需要 >= 22.12.0（DSH 要求）。升级后重开终端再运行。"
}
Info "Node 版本 OK：$ver"

# ---------- 2) DSH ----------
Info "检查 DSH ..."
$dsh = Get-Command dsh -ErrorAction SilentlyContinue
if (-not $dsh) {
  Info "安装 @deepseek-ai/dsh ..."
  & npm i -g "@deepseek-ai/dsh@latest" --registry=https://registry.npmmirror.com 2>&1 | Select-Object -Last 3
  if ($LASTEXITCODE -ne 0) {
    Warn "镜像安装失败，改用官方源重试"
    & npm i -g "@deepseek-ai/dsh@latest" 2>&1 | Select-Object -Last 3
  }
  $dsh = Get-Command dsh -ErrorAction SilentlyContinue
  if (-not $dsh) { Fail "DSH 安装失败：dsh 命令仍不可用" }
}
Info ("DSH 版本：" + ((& dsh --version) 2>&1 | Select-Object -First 1))

# ---------- 3) 插件 ----------
$profileDir = Join-Path $env:USERPROFILE ".dsh\profiles\web"
$pkgJson = Join-Path $profileDir "node_modules\dsh-pet\package.json"
if (Test-Path $pkgJson) {
  $v = (Get-Content $pkgJson -Raw | ConvertFrom-Json).version
  if ($v -like "*sharkpig*") { Info "已安装带修复的 dsh-pet $v（跳过）" ; $installed = $true }
  else { Warn "已存在官方 dsh-pet $v，将覆盖为修复版" }
}

if (-not $installed) {
  $tgz = Join-Path $env:TEMP "dsh-pet-$Tag.tgz"
  $urls = @(
    "https://gh-proxy.com/https://github.com/Zzzdaydayup/dsh-pet/releases/download/$Tag/dsh-pet-$($Tag -replace '^v','').tgz",
    "https://github.com/Zzzdaydayup/dsh-pet/releases/download/$Tag/dsh-pet-$($Tag -replace '^v','').tgz"
  )
  $ok = $false
  foreach ($u in $urls) {
    try {
      Info "下载安装包：$u"
      & curl.exe -L --fail --max-time 900 -o $tgz $u 2>&1 | Out-Null
      if ($LASTEXITCODE -eq 0 -and (Test-Path $tgz) -and (Get-Item $tgz).Length -gt 10MB) { $ok = $true; break }
    } catch { }
  }
  if ($ok) {
    Info "安装插件（本地 tgz）..."
    & dsh plugin --profile web add $tgz 2>&1 | Select-Object -Last 3
  } else {
    Warn "安装包下载失败，改用 git 源安装（需要能访问 github.com）"
    & dsh plugin --profile web add "github:Zzzdaydayup/dsh-pet#path:/dsh-pet" 2>&1 | Select-Object -Last 3
  }
  if ($LASTEXITCODE -ne 0) { Fail "插件安装失败。可手动执行：dsh plugin --profile web add <tgz 路径>" }
}

# ---------- 4) 启动 + 自检 ----------
if ($NoStart) {
  Info "已跳过启动（-NoStart）。手动运行：dsh web"
  exit 0
}

Info "启动 DSH（后台）..."
Start-Process -FilePath "dsh" -ArgumentList @("web") -WindowStyle Hidden | Out-Null
for ($i = 0; $i -lt 20; $i++) {
  Start-Sleep -Seconds 2
  try {
    $r = Invoke-WebRequest "http://127.0.0.1:3080/dsh-pet-7340/config" -UseBasicParsing -TimeoutSec 5
    if ($r.Content -match "鲨猪") {
      Info "自检通过：DSH 已启动，配置里能看到「鲨猪」"
      Info "浏览器打开 http://127.0.0.1:3080 ，设置 → 桌宠配置 → 把「鲨猪」显示位置设为 web 或 both"
      exit 0
    }
  } catch { }
}
Warn "DSH 已在后台启动，但还没检测到「鲨猪」。请等 10 秒后重试："
Warn '  curl http://127.0.0.1:3080/dsh-pet-7340/config'
Warn "若仍没有，检查角色目录：$env:USERPROFILE\.dsh\dsh-pet\pet\"
exit 0
