# Mind Agora Flutter

Mind Agora Flutter 是一个高保真 Flutter 复刻版本：把 `mind-agora.html` 的 AI 社交媒体外壳、思想启发型聊天室、动态消息流、右侧 thinker rail、AI prompts、active conversations，以及 demo 中的 live Thinking Room 迁移成一个可继续开发的移动端 App 工程。

本项目不是把 HTML 塞进 WebView，而是用 Flutter 原生 Widget 重建 UI：cream 背景、山形底纹、拱门光晕、半透明卡片、soft shadow、圆形 thinker avatar、公共 feed、Thinking Room 三栏布局和移动端底部操作条。

## 已实现内容

### 1. AI 社交媒体首页

- 左侧 Mind Agora 导航栏：Home、Meetings、Think Room、Self-reflection、Saved、Quotes、Thinkers、Collections、Notifications、Messages
- 中间动态流：composer、For You/Following/Questions/Quotes tabs、帖子卡片、quote 卡片、thinker reply 嵌套回复
- 右侧 rail：Converse with great minds、AI prompts for you、Active conversations、Start a Thinking Room
- 响应式适配：桌面显示左侧栏和右侧栏，窄屏显示 bottom nav

### 2. Think Room 计划页

- 从 `assets/data/room_data.json` 读取 room topic、background、agenda、participants
- 支持两个聊天引擎模式切换：
  - Complex host mode：模拟 `room.py` 的 host 调度抽象
  - Single prompt mode：一次 prompt 生成完整多人对话
- Agenda preview：展示每个议题、问题和当前 active agenda
- Suggested thinkers：读取 participants 并渲染成 council 列表

### 3. Live Thinking Room

- 改进聊天室样式：接近 demo 第三张图的三栏 room UI
- 左栏：Invited Council、Session Journey、Agenda cards
- 中间：room header、topic、mode、聊天气泡流
- 右栏：Speaking now、Round、Challenge score、Engine、Memory draft
- 底部：用户输入框、发送按钮、Next/Simulate 控制按钮
- 移动端：隐藏左右 rail，保留 agenda 横向条和底部 composer

### 4. AI 调用抽象

- `OpenAiCompatibleChatClient`：调用 OpenAI-compatible `/chat/completions` endpoint
- 默认支持 Gemma endpoint 格式，只需要配置 base URL、API key、model
- 没配置 endpoint 时自动使用 `FakeChatClient`，便于本地直接看 UI 和流程

### 5. 手机端数据库方案

- Android/iOS 使用 `sqflite`，即移动端 SQLite
- Web 使用 `BrowserLocalStore`，通过 browser `localStorage` 保存 demo room、messages、settings，避免浏览器里初始化 `sqflite` 的 runtime error
- 数据库文件：`mind_agora.db`
- 表结构：
  - `rooms`：room metadata 和完整 JSON payload
  - `messages`：room transcript
  - `memories`：会话总结、标签、后续可做 collection
  - `settings`：endpoint、用户偏好、功能开关等
- 设计为 offline-first：先保存本地，再同步到远端服务

## 目录结构

```text
mind_agora_flutter/
  assets/data/room_data.json       # 复杂模式样例 room 数据
  docs/reference/                  # demo 参考图
  lib/
    main.dart
    theme/agora_theme.dart         # 颜色、字体、阴影、样式 token
    models/models.dart             # Room、Agenda、Mind、Message、Feed 模型
    data/sample_data.dart          # 首页 feed 和 rail mock 数据
    data/room_data_loader.dart     # 从 asset 载入 room_data.json
    llm/llm_client.dart            # OpenAI-compatible client 和 Fake client
    room/room_orchestrator.dart    # 两种会议引擎的调度逻辑
    room/simple_dialogue_prompt.dart
    storage/local_store.dart       # LocalStore interface
    storage/sqflite_local_store.dart
    storage/browser_local_store.dart
    storage/local_store_factory.dart
    screens/                       # App screens
    widgets/                       # 卡片、avatar、logo、chat bubble、nav 等
```

## 快速运行

```bash
cd mind_agora_flutter

# 本 ZIP 主要包含 lib、assets、README 和工程配置。
# 第一次在本机运行时，先生成 Android/iOS/Web 平台目录。
flutter create . --platforms=android,ios,web --project-name mind_agora_flutter

flutter pub get
flutter run
```

也可以运行：

```bash
./tool/bootstrap_flutter_project.sh
```

默认没有配置模型 endpoint，因此会走 `FakeChatClient`，可以直接体验首页、Think Room、两种对话模式和本地保存。

### Web 运行和自动测试

```bash
flutter build web
python3 tool/serve_web.py
```

默认端口是 `39865`，可打开：

```text
http://127.0.0.1:39865
```

浏览器自动冒烟测试：

```bash
npm install
npm run test:web
```

该测试会用 Playwright 打开 release web build，检查页面标题、4xx 资源请求、console error、Dart page error，并保存 desktop/mobile/Home/Think Room/Live Room 截图到 `test-results/web-smoke/`。

## 连接 Gemma OpenAI-compatible endpoint

推荐用 `--dart-define` 注入配置，不要把真实 key 写进仓库。

```bash
flutter run \
  --dart-define=GEMMA_BASE_URL=https://your-gemma-endpoint.example.com/v1 \
  --dart-define=GEMMA_API_KEY=replace-me \
  --dart-define=GEMMA_MODEL=gemma-3-27b-it
```

`OpenAiCompatibleChatClient` 会请求：

```text
POST {GEMMA_BASE_URL}/chat/completions
Authorization: Bearer {GEMMA_API_KEY}
Content-Type: application/json
```

请求体格式：

```json
{
  "model": "gemma-3-27b-it",
  "messages": [
    {"role": "system", "content": "..."},
    {"role": "user", "content": "..."}
  ],
  "temperature": 0.72,
  "max_tokens": 900
}
```

本地或内网部署的 Gemma 服务没有鉴权时，可以不传 `GEMMA_API_KEY`。

## 两种聊天模式

### Complex host mode

复杂模式的目标是接近 `room.py` 的抽象：Room host 不是简单聊天机器人，而是会管理会话结构。

流程：

1. 读取 `RoomSession`：topic、background、outcomeType、agenda、participants
2. 根据当前 transcript 和 agenda 选择下一位 mind
3. 构造 system prompt：包含 speaker、role、persona、prior、reflection、intent、agenda coverage
4. 构造 user prompt：包含最近 transcript 和当前 agenda purpose
5. 调用 OpenAI-compatible endpoint
6. 把返回内容写入 `messages` 表并渲染成 chat bubble
7. 每隔若干轮推进 agenda index

核心文件：

```text
lib/room/room_orchestrator.dart
lib/llm/llm_client.dart
lib/screens/room_screen.dart
```

### Single prompt mode

轻量模式适合快速生成一整段多人对话，尤其适合 demo、低成本生成、弱交互场景。

流程：

1. 读取同一份 `RoomSession`
2. 把 participants 和 agenda 写入一个完整 prompt
3. 要求模型返回 JSON array：`speaker`、`role`、`text`
4. 解析 JSON
5. 仍然用 Live Thinking Room 的 chat UI 渲染

核心文件：

```text
lib/room/simple_dialogue_prompt.dart
lib/room/room_orchestrator.dart
```

## 数据库设计说明

移动端建议优先使用 SQLite，而不是只用内存或 SharedPreferences。原因：

- transcript 会增长，需要分页和索引
- room、message、memory 之间有清晰关系
- iOS/Android 支持成熟
- 支持离线读取和后续同步
- 可以用迁移脚本演进 schema

当前 schema 在 `SqfliteLocalStore.init()` 中创建。后续生产化可以扩展：

- `sync_state` 字段：pending、synced、failed
- `remote_id` 字段：和云端 room/message 对齐
- `embedding_ref` 字段：连接向量库或端侧 embedding cache
- `deleted_at` 字段：软删除和多端同步
- 数据库加密：可替换为 SQLCipher 方案

Web 端不能直接使用 `sqflite`，因此当前 demo 使用 `BrowserLocalStore` 做平台分流。生产 Web 版如果也需要更强持久化，可以替换为 IndexedDB 或 sqlite-wasm；移动端仍保持 SQLite/offline-first。

## 后续开发建议

1. 增加 endpoint settings 页面，让用户在 App 内配置 Gemma base URL 和 model。
2. 把 `room_data.json` 的 persona 拆成独立 thinker library，并加入搜索、收藏、邀请。
3. 给 complex mode 增加真正的 host policy：覆盖度检测、drift budget、冲突度、总结触发。
4. 为 simple prompt mode 增加 JSON schema 校验和自动修复。
5. 将 memory draft 从静态卡片改成模型总结，并写入 `memories` 表。
6. 做云端同步：移动端 SQLite 作为 offline cache，后端提供 rooms、messages、memories API。

## 常见问题

### 为什么没有直接复用 HTML 或 CSS？

Flutter App 需要原生布局、触控、离线存储和移动端数据库。用 WebView 可以快，但后续很难把本地消息、模型流式输出、推送、离线缓存和移动端交互做扎实。

### 没有模型 endpoint 能运行吗？

可以。未配置 `GEMMA_BASE_URL` 时会自动启用 `FakeChatClient`，用于演示 UI、导航、本地数据库写入和两种会议流程。

### 当前 UI 是不是完全像 demo？

重点视觉 token 和信息结构已经复刻：cream 背景、拱门 logo、山形底纹、半透明卡片、左右 rail、公共 feed、Thinking Room 三栏、chat bubble、challenge score 和 memory card。Flutter 的字体渲染、阴影和间距会与浏览器有细微差别，后续可以继续做逐像素调参。
