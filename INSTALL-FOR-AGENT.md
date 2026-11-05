# 给 AI Agent 的安装说明：DSH + 鲨猪桌宠

> 目标：在一台**全新电脑**上，装好 DeepSeek Harness（DSH），并装上带《鲨猪》角色的 dsh-pet 插件。
> 读者是 AI agent。请按顺序执行，每一步都有验证；失败时按该步骤的「降级方案」处理，不要跳步。

---

## 0. 判断环境

```bash
# Windows 用 PowerShell；macOS / Linux 用 bash
node -v          # 需要 >= 22.12.0
npm -v
git --version    # 可选
```

- Node < 22.12 或没有 Node → 先装 Node（Windows: `winget install OpenJS.NodeJS.LTS`；macOS: `brew install node`；Linux: 用 nvm 或包管理器）。装完**重开终端**再 `node -v`。
- 没有任何包管理器 → 到 https://nodejs.org 下载 LTS 安装包。

**验收**：`node -v` 输出 `v22.` 或更高。

---

## 1. 安装 DSH

```bash
npm i -g @deepseek-ai/dsh@latest --registry=https://registry.npmmirror.com
```

国内网络用上面的镜像；如果镜像 404，去掉 `--registry` 参数走官方源。

**验收**：

```bash
dsh --version     # 应输出 0.2.x 之类版本号
```

**降级**：`npm i -g @deepseek-ai/dsh@latest`（官方源）。仍失败 → 检查 npm 是否能访问网络（`npm ping`）。

---

## 2. 安装带鲨猪角色的 dsh-pet

DSH 的插件按 profile 管理，我们用默认的 `web`。

**方案 A（优先）：Release 安装包**（体积大但一次成功）

```bash
# Windows (PowerShell)
curl.exe -L -o "$env:TEMP\dsh-pet.tgz" "https://gh-proxy.com/https://github.com/Zzzdaydayup/dsh-pet/releases/download/v0.4.1-sharkpig.2/dsh-pet-0.4.1-sharkpig.2.tgz"
dsh plugin --profile web add "$env:TEMP\dsh-pet.tgz"

# macOS / Linux
curl -L -o /tmp/dsh-pet.tgz "https://gh-proxy.com/https://github.com/Zzzdaydayup/dsh-pet/releases/download/v0.4.1-sharkpig.2/dsh-pet-0.4.1-sharkpig.2.tgz"
dsh plugin --profile web add /tmp/dsh-pet.tgz
```

`gh-proxy.com` 是国内可用的 GitHub 代理；如果它失败，把 URL 换成直连：
`https://github.com/Zzzdaydayup/dsh-pet/releases/download/v0.4.1-sharkpig.2/dsh-pet-0.4.1-sharkpig.2.tgz`

**方案 B（备选）：直接从 git 装**（需要能访问 github.com）

```bash
dsh plugin --profile web add "github:Zzzdaydayup/dsh-pet#path:/dsh-pet"
```

> `#path:/dsh-pet` 不能省：仓库是 monorepo，插件在子目录。

**验收**：

```bash
dsh plugin --profile web why dsh-pet
# 或直接看：
ls "$HOME/.dsh/profiles/web/node_modules/dsh-pet/package.json"     # macOS/Linux
dir "$env:USERPROFILE\.dsh\profiles\web\node_modules\dsh-pet\package.json"   # Windows
```

应看到 `dsh-pet` 包存在。**不要**在这一步检查角色文件——角色是插件首次启动时自举安装的。

---

## 3. 启动 DSH（触发角色自举）

```bash
dsh web
```

第一次启动会创建 `~/.dsh`、解包插件、并把内置的《鲨猪》角色复制到：

```
~/.dsh/dsh-pet/pet/鲨猪-config.jsonc
~/.dsh/dsh-pet/pet/鲨猪-animation/   (32 个 .webm)
~/.dsh/dsh-pet/pet/鲨猪-memes/       (12 张 .png)
```

**验收（另开一个终端）**：

```bash
curl -s http://127.0.0.1:3080/dsh-pet-7340/config | grep -c "鲨猪"
# 输出 >= 1 即成功
```

以及：

```bash
ls ~/.dsh/dsh-pet/pet/ | grep 鲨猪
```

**失败处理**：

| 现象 | 原因 | 处理 |
|---|---|---|
| `config` 里没有"鲨猪" | 插件尚未首次启动完 | 关掉 `dsh web` 重开，等 5 秒再查 |
| 有鲨猪但没动画 | 角色目录没复制成功 | 手工：把 `profiles/web/node_modules/dsh-pet/assets/pets/鲨猪/` 整个复制到 `~/.dsh/dsh-pet/pet/` |
| 端口占用 | 已有 DSH 在跑 | 直接复用现有实例，刷新浏览器 |

---

## 4. 打开界面

浏览器访问 **http://127.0.0.1:3080**。

进入设置 → 桌宠配置 → 能看到《鲨猪》，把「显示位置」设为 `web` 或 `both`。

---

## 5. 这个版本修了什么（供排查用）

相对于官方 dsh-pet 0.4.1，本 fork 内置三处修复（源码里搜 `[sharkpig]`）：

1. **切换动画白闪**：`loadeddata` 后先静默开播、等首帧真正渲染再切前台；并取消 0.18s 交叉淡入。
2. **工作状态卡死**：非终态 60 秒无变化自动收起气泡、回落待机。
3. **点击打不断**：用户点击后 5 分钟内工作状态不抢动画。

---

## 6. 回滚 / 卸载

```bash
# 回到官方插件
dsh plugin --profile web add dsh-pet@latest

# 只卸角色
rm -rf ~/.dsh/dsh-pet/pet/鲨猪-*        # macOS/Linux
Remove-Item "$env:USERPROFILE\.dsh\dsh-pet\pet\鲨猪-*" -Recurse -Force   # Windows
```

---

## 7. 给 agent 的执行摘要（可直接照做）

```
1) node -v 必须 >= 22.12，否则先装 Node 并重开终端
2) npm i -g @deepseek-ai/dsh@latest --registry=https://registry.npmmirror.com
3) 下载 https://gh-proxy.com/https://github.com/Zzzdaydayup/dsh-pet/releases/download/v0.4.1-sharkpig.2/dsh-pet-0.4.1-sharkpig.2.tgz
4) dsh plugin --profile web add <下载下来的 tgz 路径>
5) 启动 dsh web（后台运行），等待 5 秒
6) curl http://127.0.0.1:3080/dsh-pet-7340/config 应包含「鲨猪」
7) 告诉用户：浏览器打开 http://127.0.0.1:3080，设置里把「鲨猪」的显示位置设为 web
```

任一步失败，把该步命令的完整输出贴给用户，不要自行猜测跳过。

---

## English (for non-Chinese agents)

Install Node ≥ 22.12, then `npm i -g @deepseek-ai/dsh@latest`, then install the pet plugin from the release tarball
(`https://gh-proxy.com/https://github.com/Zzzdaydayup/dsh-pet/releases/download/v0.4.1-sharkpig.2/dsh-pet-0.4.1-sharkpig.2.tgz`)
via `dsh plugin --profile web add <tgz>`, start `dsh web`, and verify `http://127.0.0.1:3080/dsh-pet-7340/config` contains `鲨猪`.
The character pack is bundled and auto-installed into `~/.dsh/dsh-pet/pet/` on first launch.
