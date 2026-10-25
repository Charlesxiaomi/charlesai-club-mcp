---
name: charlesai-sites
description: 用 CharlesAI 工作坊的托管建站 MCP（charlesai）把 HTML 页面、PPT、数据面板、落地页、文档站等静态网页发布到 <子域名>.yongxianshi.cn，拿到可分享的链接；也负责申请子域名、更新 / 回滚 / 加密码 / 删除已发布的站点。当用户说"发布网页/把这个页面发出去/生成分享链接/部署静态站/上线这个 HTML/给站点加密码/回滚到上个版本/我的站点有哪些/申请子域名"时使用。需要跑后端代码或长期服务时改用 charlesai-container。
display_name: CharlesAI 托管建站
display_name_en: CharlesAI Static Sites
description_zh: 一句话把 HTML 发布成可分享的网页，支持版本回滚和访问密码。
description_en: Publish HTML as a shareable website with versioning and password protection.
version: 1.0.0
author: CharlesAI
examples_zh:
  - 把这个 index.html 发布成网页，给我一个分享链接
  - 把 dist 目录部署成站点 q3-report，并设访问密码
  - 我的站点有哪些？把 ppt1 回滚到上一个版本
examples_en:
  - Publish this index.html and give me a share link
  - Deploy the dist folder as site q3-report with a password
---

# CharlesAI 托管建站：静态站

本技能依赖 `charlesai` MCP（`https://club.yongxianshi.cn/mcp`，Bearer token 在会员中心生成）。下面提到的 `whoami`、`deploy_site` 等都是这个 MCP 的工具；在不同客户端里它们可能显示为 `charlesai.whoami`、`mcp__charlesai__whoami` 之类，指的是同一个东西。

如果找不到这些工具，说明 MCP 还没接上：告诉用户去 https://club.yongxianshi.cn/dashboard 生成 token，并按仓库 README 里对应客户端（WorkBuddy / Codex / Claude Code）的方式配置，然后停下，不要自己猜接口去 curl。

## 第一步：永远先 whoami

每次会话第一次用之前调用 `whoami`，按返回结果分流：

| 状态 | 怎么做 |
|---|---|
| 会员到期（active=false） | 告诉用户已发布的站点仍可访问，但不能发布或修改，续费请微信联系 Charles。停止。 |
| 没有子域名 | 问用户想要的名字和用途，再调用 `request_subdomain`（见下文）。 |
| 子域名待审批 / 被驳回 / 被封禁 | 把 whoami 里的中文说明原样转告用户。待审批时不要重复提交，也不要轮询。 |
| 已批准 | 记下 `subdomain.host` 和配额余量，继续发布。 |

## 申请子域名

- 规则：2–20 位，小写字母开头，只能有小写字母、数字和中间的连字符，不能连续两个连字符，不能以 `-app` 结尾；`www`、`club`、`api`、`admin`、`mail`、`app` 等是保留名。
- 一位会员只有一个子域名，静态站和容器共用。先问清名字和一句用途；如果用户还想跑代码或服务，`want_container=true`。
- 成功后把返回的话术**原样**转告用户（大意是：已提交，请微信私信 Charles 完成审批）。审批是人工的，这次会话里就别再等了。

## 发布前整理文件

1. 入口必须是站点根目录的 `index.html`。
2. 页面里引用资源全部用**相对路径**（`css/app.css`、`./img/a.png`）。不要写 `/css/app.css` 这种以 `/` 开头的路径：站点挂在 `https://<子域名>.yongxianshi.cn/<站点名>/` 下面，`/xxx` 会指到子域名根目录，导致 404。构建工具要改 base：Vite 用 `base: './'`，Next.js 静态导出用 `basePath: '/<站点名>'` 或 `assetPrefix: './'`。
3. 不允许以 `.` 开头的文件或目录（`.env`、`.git`、`.htaccess`，`.well-known/` 除外），发布前剔除。顺手确认没把密钥、`.env` 内容写进页面。
4. 可以放一个 `404.html` 作为自定义 404 页；`a/` 会自动找 `a/index.html`。
5. 站点名规则：1–40 位，小写字母、数字和中间的连字符，字母或数字开头结尾，例如 `ppt1`、`q3-report`。用户没指定时，根据内容起一个短名并告诉用户。

## 选择发布方式

**小站点（解码后总计 ≤ 10MB）→ `deploy_site`**

- `files` 一次给全：`{path, content, encoding}`。文本用 `utf8`，图片、字体、视频等二进制用 `base64`。
- 每次发布是**完整替换**：没放进 `files` 的旧文件会消失。改一个文件也要把全部文件一起传。
- `password` 可选（4–64 字符）；不传就保持原设置。

**大站点（> 10MB 或文件多）→ 上传 tar.gz**

1. 打包，`index.html` 要在包的根目录：`tar -czf site.tar.gz -C <站点目录> .`
2. 调用 `create_upload(site)`，拿到 `upload_id` 和上传地址（15 分钟有效，只能用一次）。
3. 在本机执行它返回的 curl 命令：`curl -fsS -T site.tar.gz '<upload_url>'`，看到成功的 JSON。
4. 调用 `finalize_upload(upload_id)` 发布。
5. 包里不能有符号链接、硬链接或路径穿越；隐藏文件会被自动跳过。失败了就重新 `create_upload`。

## 发布之后

- 把返回的网址发给用户，并说明是公开的还是有密码。
- 每个站点保留最近 5 个版本。撤回发布用 `get_site` 看版本，再 `rollback_site(site, version)`。
- 加 / 改 / 取消密码用 `set_site_password`（传 `null` 取消）。密码只存哈希，提醒用户自己记好。
- 看全部站点和配额用 `list_sites`。
- `delete_site` 是永久删除且不可恢复，只有用户明确说"删除"时才调用，调用前再确认一次站点名。

## 出错时

工具返回 `isError` 时，把里面的中文说明转告用户，按说明处理（比如超配额就建议删旧站或压缩图片）。不要换着参数反复重试。每次工具调用都计入会员用量。
