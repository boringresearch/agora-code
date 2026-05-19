# Mind Agora Flutter Writeup

## 目标

这次迁移的目标不是做一个普通聊天 App，而是复现 demo 中的产品气质：一个披着 AI 社交媒体外壳的思想启发型系统。它既有公共动态、名人 thinker、quote、prompt、active conversation，也有一个会暂停 feed、召集 council、制定 agenda、调度对话、沉淀 memory 的 AI meetings / Think Room。

## UI 复现策略

原 HTML demo 的视觉语言非常明确：

- 背景：奶油纸张色，底部山形插画，左下角拱门光晕
- 品牌：Mind Agora 拱门 logo，中间一条金线
- 卡片：白色半透明、细金灰边框、柔和阴影
- 字体：display 风格偏圆润厚重，正文偏干净理性
- 交互外壳：像社交媒体，但按钮和文字更安静、更适合反思
- 聊天室：不像传统 IM，更像有主持人的思想圆桌

Flutter 中对应拆成了这些基础构件：

```text
AgoraBackground      # 画背景、山形、光晕、拱门
AgoraLogo            # 原生 CustomPainter logo
SoftCard             # 半透明白卡片和统一阴影
ThinkerAvatar        # 线描风 thinker 头像
AgoraChip            # 标签和 mode chip
PostCard             # 动态流帖子
ChatBubble           # Thinking Room 气泡
AgendaCard           # 议程卡
RoomMetricCard       # Speaking now、Round、Challenge score
```

这样做的好处是后续可以继续精修，而不是在每个 screen 里重复写 decoration。

## 首页信息架构

首页复刻 demo 的 AI social media shell：

1. 左侧导航是产品的“房子”：Home、Meetings、Think Room、Self-reflection 等入口。
2. 中间 feed 是“公共广场”：用户可发问题、quote、reflection；thinker 可以在动态下给出启发式回复。
3. 右侧 rail 是“召唤面板”：快速进入 thinkers、AI prompts、active conversations。
4. Active conversation 可以直接进入 Live Thinking Room，形成 feed 和 room 的循环。

社交外壳的重点不是点赞，而是让每条动态都可能被 thinker 重新解释，变成一次新的思考入口。

## Think Room 改进

原 `mind-agora.html` 的 Think Room 已有雏形，但聊天室可以更清楚地区分三层状态：

- 会话结构：agenda、journey、participants
- 实时对话：当前 speaker、round、challenge score
- 产出沉淀：memory draft、action hypothesis、可发布到 feed 的总结

因此 Flutter 版将 Live Room 做成三栏：

```text
左栏：Invited Council + Session Journey
中栏：Chat transcript + Bottom composer
右栏：Speaking now + Round + Challenge score + Engine + Memory draft
```

移动端保留核心操作：顶部 room header、agenda 横向条、聊天流、底部输入和模型按钮。左右栏收起，避免手机上信息密度爆炸。

## AI meetings 抽象

### 数据模型

`room_data.json` 映射为：

```text
RoomSession
  id
  topic
  background
  outcomeType
  runtimeMode
  agenda: List<AgendaItem>
  participants: List<MindProfile>
```

每个 participant 保留：

```text
MindProfile
  id
  name
  role
  persona
  prior
  reflection
  intent
  description
```

这些字段就是 complex mode 的 prompt fuel。persona 决定人格镜片，prior/reflection/intent 决定入场状态和当前意图。

### Complex host mode

复杂模式是主路径。它把一场 room 看成“被主持的多智能体会议”，而不是单纯 group chat。

核心概念：

- Host：控制节奏，决定下一个 speaker
- Agenda：当前讨论目标，避免跑题
- Coverage：必须覆盖的议题要点
- Drift budget：允许轻微漂移，但不能无限散开
- Transcript：最近上下文，让每个 mind 回应真实对话
- Persistence：每条消息写入 SQLite

当前实现中，speaker selection 先用 round-robin，后续可以换成真正 policy：

```text
score = agenda_need + disagreement_need + participant_silence + user_intent_match
next_speaker = argmax(score)
```

Prompt 结构：

```text
system:
  You are a participant in Mind Agora.
  SPEAKER: ...
  ROLE: ...
  room topic / background / current agenda
  required coverage / allowed drift
  persona / prior / reflection / intent
  rules

user:
  current agenda purpose
  recent transcript
  continue with one valuable turn
```

### Single prompt mode

轻量模式用于一次性生成完整多人对话。它适合：

- demo
- 批量生成样例 room
- 没有交互时快速预演
- 降低模型调用次数

它要求模型只返回 JSON array：

```json
[
  {"speaker": "Room", "role": "Host", "text": "..."},
  {"speaker": "莫奈", "role": "Advocate", "text": "..."}
]
```

解析后仍然进入同一套 chat bubble 渲染。也就是说，两种 AI 引擎共享一套 UI 和本地存储。

## OpenAI-compatible Gemma 接入

`OpenAiCompatibleChatClient` 只依赖 `/chat/completions` 格式，因此可接：

- 自托管 Gemma OpenAI-compatible server
- vLLM OpenAI-compatible endpoint
- llama.cpp server OpenAI-compatible endpoint
- 其他兼容 Chat Completions 的网关

配置方式：

```bash
--dart-define=GEMMA_BASE_URL=https://your-endpoint/v1
--dart-define=GEMMA_API_KEY=...
--dart-define=GEMMA_MODEL=gemma-3-27b-it
```

没有配置时走 `FakeChatClient`，保证 UI 演示和本地开发不断电。

## 移动端数据库选择

我选择 `sqflite`，原因是这个产品的数据天然是关系型的：

- 一个 room 有多个 message
- 一个 room 会生成多个 memory
- message 需要按时间排序、分页、索引
- settings 需要本地读写
- 后续要做云同步和冲突解决

当前 schema：

```text
rooms(id, topic, background, payload, created_at, updated_at)
messages(id, room_id, payload, created_at)
memories(id, room_id, title, body, tags, created_at)
settings(key, value, updated_at)
```

为什么不是只用 Hive 或 SharedPreferences：

- SharedPreferences 适合小型 key-value，不适合 transcript
- Hive 很适合对象缓存，但复杂查询、索引、同步状态演进不如 SQLite 直观
- SQLite 在 iOS/Android 上稳定，适合长期保存聊天和会议产物

生产版可继续扩展：

- 消息分页
- 表迁移
- SQLCipher 加密
- 多端同步状态
- memory embedding 索引引用

Web 端做了平台分流：`main.dart` 通过 `createLocalStore()` 创建 store，Android/iOS 走 `SqfliteLocalStore`，Web 走 `BrowserLocalStore`。这样浏览器打开不会再触发 `databaseFactory not initialized`，同时仍能保存 demo room、messages、settings 到当前浏览器的 `localStorage`。如果生产 Web 版需要更高容量和查询能力，可以把同一个 `LocalStore` interface 替换成 IndexedDB 或 sqlite-wasm 实现。

## 自动验证

除了 `flutter test` 和 `flutter build web`，项目增加了 Playwright web smoke test：

```bash
npm install
flutter build web
python3 tool/serve_web.py
npm run test:web
```

测试覆盖：

- desktop 首页打开，无 console error / pageerror / 本地资源 4xx
- desktop 从 Home 进入 Think Room planner，再进入 Live Room
- mobile viewport 打开首页并进入 Think Room planner
- 每一步保存截图，并用 PNG 像素检查避免空白页误判

## 设计取舍

### 没有做 WebView

WebView 可以更快贴近 HTML，但会牺牲：

- 原生滚动和触控细节
- SQLite 离线存储
- 推送和 deep link
- Flutter 层的状态管理
- 后续跨平台组件复用

因此本版本走原生 Widget 复刻。

### 没有把所有 HTML 功能都迁移

原 HTML 里有大量 demo 交互、modal、picker、notification panel。Flutter 版优先实现主线：Home feed、Think Room planner、Live Room、AI engine、local persistence。其他页面先做占位，便于继续增量开发。

### 没有内置真实密钥

模型 endpoint 需要用户自己配置。工程提供 `.env.example` 和 `--dart-define` 用法，不包含任何真实 key。

## 下一步优先级

1. Endpoint settings screen：在 App 内填写 base URL、key、model。
2. Host policy：从 round-robin 升级为 agenda coverage + conflict + silence balancing。
3. Streaming output：支持 SSE，让 thinker 逐字出现。
4. Memory generation：模型自动生成 summary、tags、action hypothesis，写入 `memories`。
5. Feed publish flow：把 memory 变成 reflection post。
6. Thinker library：persona、prior、style examples、story bank 独立管理。
7. Cloud sync：本地 SQLite + 后端 API + 冲突解决。
