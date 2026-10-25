# CharlesAI 托管建站 MCP · 客户端配置与 Skills

[涌现时 CharlesAI 工作坊](https://club.yongxianshi.cn/#mcp) 会员专属的托管建站 MCP，接上后你的 AI agent 可以：

- **发布静态站**：把 HTML、PPT、数据面板、落地页发布到 `https://<你的子域名>.yongxianshi.cn/<站点名>/`，马上得到分享链接。支持版本回滚和访问密码。
- **使用云端容器**：在隔离容器里写代码、装依赖、跑服务，通过 `https://<你的子域名>-app.yongxianshi.cn` 公网访问。

这个仓库提供 **WorkBuddy、Codex、Claude Code** 三个客户端的 MCP 配置，以及两个配套 Skill，教 agent 按正确流程使用这些工具。

> 本仓库只有配置和说明，不含任何 token。MCP 服务本身运行在 `https://club.yongxianshi.cn/mcp`，需要会员 token 才能调用。

## 准备：拿到 token

1. 登录 [会员中心](https://club.yongxianshi.cn/dashboard)，在「建站 MCP」里生成 token（`cai_` 开头）。
2. token 只显示一次，请保存好。泄露了随时在会员中心重置，旧 token 立即失效。会员到期后 token 自动停用，续费后恢复。

**不要把 token 提交到 Git 仓库、贴进公开文档或发给别人。** 下面的配置都尽量用环境变量或客户端的凭证表单来保存 token。

## 仓库结构

```
skills/
  charlesai-sites/        静态站：申请子域名、发布、回滚、密码、删除
  charlesai-container/    云端容器：写代码、跑服务、看日志
    agents/openai.yaml    Codex 用的元数据（声明依赖 charlesai MCP）
workbuddy/
  connector/              WorkBuddy 连接器包（mcp.json + token-schema.json + 元数据 + 图标）
  manual/mcp.json         手动配置用的 mcp.json 示例
codex/config.toml         Codex 配置片段
claude-code/.mcp.json     Claude Code 配置示例
scripts/
  install.sh              把 Skills 装到各客户端
  build-workbuddy.sh      打包 WorkBuddy 连接器（含 Skills）
```

先克隆仓库：

```bash
git clone https://github.com/Charlesxiaomi/charlesai-club-mcp.git
```

## WorkBuddy

### 方式一：手动配置（推荐，最快）

1. 打开 WorkBuddy →「技能」菜单的设置图标 → MCP →「编辑 mcp.json」（也就是 `~/.workbuddy/mcp.json`，Windows 是 `%USERPROFILE%\.workbuddy\mcp.json`）。
2. 把 [`workbuddy/manual/mcp.json`](workbuddy/manual/mcp.json) 里的 `charlesai` 一项合并进 `mcpServers`，把 `<把这里换成你的 token>` 换成你的 token：

   ```json
   {
     "mcpServers": {
       "charlesai": {
         "type": "streamableHttp",
         "url": "https://club.yongxianshi.cn/mcp",
         "headers": { "Authorization": "Bearer cai_xxxxxxxx" },
         "timeout": 300000
       }
     }
   }
   ```

   注意文件名是 `mcp.json`，不是 `.mcp.json`（带点的那个是程序自动生成的，会被覆盖）。
3. 保存后到连接器管理页，对 `charlesai` 点 **Trust**，状态灯变绿就是连上了。
4. 安装 Skills：

   ```bash
   cd charlesai-club-mcp && scripts/install.sh workbuddy
   ```

   技能会复制到 `~/.workbuddy/skills/`，重启 WorkBuddy 后生效。也可以把 `skills/charlesai-sites/SKILL.md` 直接拖进对话里安装。

如果状态灯一直是红的：先检查 JSON 括号和引号是否完整、token 前面有没有 `Bearer `，再试着把 `"type": "streamableHttp"` 改成 `"type": "http"`。

### 方式二：连接器包（带 token 表单）

[`workbuddy/connector/`](workbuddy/connector) 是按 WorkBuddy 开放平台规范做的连接器：`mcp.json` 里用 `${CHARLESAI_TOKEN}` 占位，token 由 `token-schema.json` 定义的表单让用户填写，只保存在本机。打包（会把两个 Skill 一起放进 `skills/`）：

```bash
scripts/build-workbuddy.sh
```

产物在 `dist/charlesai-club.zip`，可以提交到 WorkBuddy 开放平台审核上架。需要 WorkBuddy 4.24.0 及以上。

## Codex

1. 把 token 放进环境变量（写进 `~/.zshrc` 或 `~/.bashrc`，然后重开终端）：

   ```bash
   export CHARLESAI_TOKEN=cai_xxxxxxxx
   ```

2. 添加 MCP（二选一）：

   ```bash
   codex mcp add charlesai --url https://club.yongxianshi.cn/mcp --bearer-token-env-var CHARLESAI_TOKEN
   ```

   或者把 [`codex/config.toml`](codex/config.toml) 的内容追加到 `~/.codex/config.toml`：

   ```toml
   [mcp_servers.charlesai]
   url = "https://club.yongxianshi.cn/mcp"
   bearer_token_env_var = "CHARLESAI_TOKEN"
   tool_timeout_sec = 300
   ```

3. 安装 Skills（复制到 `~/.agents/skills/`）：

   ```bash
   scripts/install.sh codex
   ```

4. 运行 `codex mcp list` 确认 `charlesai` 已启用。在对话里可以直接说「把这个页面发布出去」，也可以用 `$charlesai-sites` 显式调用。

注意：Codex 启动时如果没有 `CHARLESAI_TOKEN` 环境变量，这个 MCP 会连接失败。从图形界面启动 Codex 时，要确保环境变量对它可见。

## Claude Code

```bash
export CHARLESAI_TOKEN=cai_xxxxxxxx
```

```bash
claude mcp add --transport http charlesai https://club.yongxianshi.cn/mcp --header "Authorization: Bearer ${CHARLESAI_TOKEN}"
```

这条命令会把展开后的 token 写进你的用户级配置（`~/.claude.json`），不会进项目仓库。如果想在项目里共享配置，就用 [`claude-code/.mcp.json`](claude-code/.mcp.json)：它用 `${CHARLESAI_TOKEN}` 引用环境变量，可以安全地提交。

安装 Skills（复制到 `~/.claude/skills/`）：

```bash
scripts/install.sh claude
```

## 两个 Skill 做什么

| Skill | 触发场景 | 要点 |
|---|---|---|
| `charlesai-sites` | 发布网页、生成分享链接、回滚、加密码、申请子域名 | 先 `whoami`；资源用相对路径；≤10MB 用 `deploy_site`，更大的走 tar.gz 上传；删除前先确认 |
| `charlesai-container` | 在云端跑 Node / Python 服务、看日志、重启 | 服务监听 `0.0.0.0:3000`，用后台 `exec` 启动；文件只在 `/workspace` 持久保存 |

## 工具一览

| 分类 | 工具 |
|---|---|
| 账号 | `whoami`、`request_subdomain` |
| 静态站 | `deploy_site`、`create_upload`、`finalize_upload`、`list_sites`、`get_site`、`rollback_site`、`set_site_password`、`delete_site` |
| 容器 | `container_status`、`container_start`、`container_stop`、`exec`、`write_file`、`read_file`、`list_files`、`logs`、`kill_process`、`expose` |
| 其他 | `ping` |

## 常见问题

- **返回 401 / 403**：token 错了、被重置了，或者会员已到期。到会员中心检查。
- **子域名一直待审批**：审批是人工的，请微信私信 Charles，备注工作坊用户名。
- **页面样式丢失 / 资源 404**：页面里用了 `/` 开头的绝对路径。改成相对路径，或者把构建工具的 base 设成 `./`。

## License

MIT
