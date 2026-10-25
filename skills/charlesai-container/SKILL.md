---
name: charlesai-container
description: 用 CharlesAI 工作坊托管建站 MCP（charlesai）的隔离容器在云端写代码、装依赖、跑后端服务，并通过 https://<子域名>-app.yongxianshi.cn 公网访问。当用户说"在服务器上跑这个项目/部署一个后端/起一个 Node 或 Python 服务/做个能公网访问的 API 或 Demo/看看容器日志/重启服务"时使用。只是发布纯静态 HTML 时改用 charlesai-sites。
display_name: CharlesAI 云端容器
display_name_en: CharlesAI Cloud Container
description_zh: 在隔离容器里跑代码和服务，自动获得公网网址。
description_en: Run code and services in an isolated container with a public URL.
version: 1.0.0
author: CharlesAI
examples_zh:
  - 在我的容器里起一个 Express 服务，返回 hello，并给我公网地址
  - 把这个 FastAPI 项目部署到容器里跑起来
  - 看看容器里服务的日志，为什么访问报 502
examples_en:
  - Start an Express server in my container and give me the public URL
  - Deploy this FastAPI project to my container
---

# CharlesAI 托管建站：云端容器

本技能依赖 `charlesai` MCP（`https://club.yongxianshi.cn/mcp`）。下面的 `exec`、`write_file` 等都是这个 MCP 的工具，在客户端里可能带前缀显示。找不到这些工具时，让用户先按仓库 README 接好 MCP，然后停下。

## 先决条件

1. 先调用 `whoami`：会员要有效，子域名要已批准，而且 `container.enabled=true`。
2. 没有子域名：按 charlesai-sites 技能里的方式用 `request_subdomain` 申请，`want_container=true`。
3. 子域名已批准但没开通容器：告诉用户容器限量开放，请微信联系 Charles 开通。停止。
4. 会员到期：容器已停机，只能用 `container_status` 查看；续费后用 `container_start` 恢复。

## 容器环境

- 文件都在 `/workspace`（HOME，唯一持久保存的目录；`/tmp` 重启后清空）。相对路径都按 `/workspace` 解析。
- 预装 Node 22（npm / pnpm / yarn）、Python 3.12、git、build-essential、sqlite3。非 root，没有 apt 和 sudo。
- npm / pip 已配国内镜像，直接 `npm i` / `pip install`；出网限速约 250KB/s，大依赖会慢。
- 默认配额约 0.5 核、512MB 内存、3GB 磁盘。别装特别重的依赖，也别在容器里做大型构建；能在本地构建好的，构建产物再传上去。
- 容器闲置 30 分钟自动休眠，访问服务网址或调用任何容器工具会自动唤醒（几秒），`autostart` 的后台进程会自动重新拉起。容器第一次被调用时自动创建。
- 容器不能访问内网和云厂商元数据地址，这是设计如此，不要尝试绕过。

## 标准流程：部署一个服务

1. **写代码**：少量文件用 `write_file`（单文件 ≤ 5MB，二进制用 base64，脚本可设 `mode="755"`）；也可以用 `exec` 配合 `git clone`。用 `list_files` / `read_file` 检查。
2. **装依赖**：耗时的安装用 `exec(command, background=true, name="install")`，再用 `logs(process="install")` 看进度。前台 `exec` 最多 280 秒。
3. **启动服务**：服务必须监听 **`0.0.0.0:3000`**（监听 `127.0.0.1` 外网访问不到）。用 `exec(command="node server.js", background=true, name="web")` 启动。
4. **拿网址**：端口是 3000 时不用调用 `expose`，网址就是 `https://<子域名>-app.yongxianshi.cn`。只有监听别的端口时才用 `expose(port)`。
5. **验证**：`logs(process="web")` 确认启动成功，再在容器里 `exec("curl -sS localhost:3000")` 自测，最后把网址给用户。

## 改代码后重启

先 `kill_process(process="web")`，再用**同一个 name** 重新 `exec(..., background=true, name="web")`。`logs` 不传参数可以列出所有后台进程及状态。

## 排错

- 访问 502 / 打不开：服务没起来，或者监听的是 127.0.0.1，或者端口不是 3000 又没 `expose`。看 `logs`。
- 内存不足被杀（日志里出现 Killed / exit 137）：减少并发、关掉 dev 模式的热更新、换用更轻的依赖。
- `container_status` 查看运行状态、CPU / 内存、磁盘用量和后台进程。
- 工具返回 `isError` 时，把中文说明转告用户，不要换参数硬试。

## 安全

- 不要把用户的密钥写进代码文件后再发布到公开网址。需要密钥时，写进 `/workspace` 下的 `.env` 并在代码里读取，并提醒用户这个服务是公网可访问的。
- `container_stop` 会结束后台进程（文件保留），一般不需要手动停。
