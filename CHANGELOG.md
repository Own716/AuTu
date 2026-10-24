# Changelog

All notable changes to the AuTu project will be documented in this file.

## [v1.0.10] - 2026-10-24 (AuTu 1.0.10 预览版)

### 内核升级 (Mihomo v1.19.33) 与安全修复
- **安全漏洞修复**：修复 `crypto/tls` 的安全漏洞 **CVE-2026-97031**。
- **协议与传输优化**：TUN 模式支持 `dns-mode`；重构优化 Sudoku 传输混淆与多路复用并提高性能；Wireguard 网络栈改为延迟初始化（Lazy Init）。
- **性能算法重构**：重构 `dialer-proxy` 循环检测算法，时间复杂度由 $O(n^2)$ 降为 $O(n)$，极大降低代理链场景下的 CPU 与内存占用；修复极速节点测速误判为失败的 Bug。
- **DNS 即时刷新**：支持主动与网络切换时即时刷新清空 DNS 缓存（`clearDnsCache`），避免旧 IP 残留与连接挂死。
- **底层依赖库升级**：`mieru` 升至 v3.38.1、`sing-tun` 升至 v0.4.28、`metacubex/tls` 升至 v0.1.9。

### FlClash v0.9.2 新特性合入与 Android 深度优化
- **后台 VPN 复用防断流**：优化 Android 启动逻辑，打开 App 时直接复用正在后台运行的 VPN 实例，不再重复重载断流。
- **全屏边到边沉浸式页面**：页面滚动延伸至 Android 底部导航栏下方，带来现代 Edge-to-Edge 沉浸视觉体验。
- **iOS 风格弹性开关与现代组件**：引入全新的平滑流体开关组件与页面设置菜单，停靠式搜索栏与悬停微抬升按钮。
- **节点添加到本地代理**：长按节点菜单新增“添加到本地代理组”快捷入口，与 AuTu 独家 4 线程下载 / 2 线程上传测速、出站 IP 查询完美融合。
- **可调节延迟测试超时**：支持在代理设置中自定义配置延迟测试超时时间。
- **配置二维码与多端互联**：新增配置二维码展示，支持手机通过二维码直接将订阅配置传递给电视端或另一台设备。
- **控制台 IP 质量结果 3 天缓存**：IP 风险质量检测结果本地缓存 3 天，精简仪表盘并避免频繁请求被风控。
- **大文本配置编辑性能提升**：大配置文件编辑器将重计算隔离在 UI Isolate 之外，避免大文件卡顿掉帧。
- **严格锁定品牌与图标**：完整保留 AuTu 品牌标识、桌面图标及刚刚在 v1.0.9 优化完成的 81.3% 高度黄金比例灵动岛/状态栏通知图标。

## [v1.0.9] - 2026-10-24 (AuTu 1.0.9 预览版)

### 状态栏与灵动岛 Logo 图标比例优化
- **重构状态栏与灵动岛通知图标规范**：将通知图标（`ic_service`）的有效图形高度占比从 40.6% 提升至 81.3%，裁剪去除多余透明留白边距，使灵动岛收起折叠态（胶囊）中的 `a` 图标高度从 ~9.6dp 提升至 ~19.5dp，与右侧地区文本（如“日本”）视觉重量 1:1 协调平衡。
- **展开卡片 Logo 视觉饱满化**：展开实况通知窗右上角的原生 Logo 同步放大，彻底消除微弱小白点感，保持清晰饱满。
- **全套通知与磁贴资源同步**：同步更新 `ic_service.png`、`ic_service_dark.png`、`ic_service_light.png` 及下拉磁贴 `ic.png`，同时完整保留桌面启动图标。

## [v1.0.8] - 2026-10-23 (AuTu 1.0.8 预览版)

### 彻底解决下载测速 4B/5B 异常与测速源限流问题
- **切换至高带宽无风控测速源**：默认下载测速源全面切换为 Google 官方高带宽 CDN（`https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg`），彻底告别 Cloudflare 接口高频压测触发 HTTP 429 限流封锁与 403 挑战；具备自动双向回退能力。
- **严格校验 HTTP 响应状态码**：增加 HTTP 2xx 状态码校验，杜绝错误响应体（如 429 报错内容）被误计入下载字节导致的“4B、5B”严重错误，确保数据统计真实精准。
- **伪装真实浏览器环境**：请求头伪装为 Android 14 现代 Chrome 移动浏览器 User-Agent，规避各类 CDN 的自动化爬虫和脚本拦截策略。

## [v1.0.7] - 2026-10-23 (AuTu 1.0.7 预览版)

### 测速引擎性能大跃升 (4 线程并发压测)
- **4 线程并发下载压测**：彻底升级单节点测速引擎为 4 线程并发下载（4-Stream 并行拉取），突破跨国代理网络 TCP 慢启动与单连接拥塞窗口带宽限制，跑满节点 30~50 MB/s 乃至数百兆真实下行带宽。
- **2 线程并发上传压测**：上行测速升级为 2 线程并行上传，真实展现节点的上行能力。
- **聚合瞬时峰值采集**：引入 200ms 高频滑动窗口聚合采集器，实时将所有并发流的瞬时吞吐量汇总，准确记录最高峰值速率（Peak Speed）。
- **测速源升级与缓冲区扩容**：默认下载包扩容至 100MB（`bytes=100000000`），读写缓冲区提升至 128KB，测速有效时间延长至 3.5 秒。

## [v1.0.6] - 2026-10-23 (AuTu 1.0.6 预览版)

### 修复
- **修复节点卡片测速文本格式化错误**：彻底修复测速结果误展示为对象调试字符串 `TrafficShow(value: ..., unit: ...)` 的问题，正确格式化为清晰规范的 `↓ 2.6 MB/s`、`↑ 1.2 MB/s`。
- **防止小屏卡片文本截断与溢出**：测速行采用 `FittedBox` 动态自适应缩放，确保在任意屏幕尺寸和字号下上下行测速完整展现。

## [v1.0.5] - 2026-10-23 (AuTu 1.0.5 预览版)

### 节点卡片测速显示与布局优化
- **专属测速行呈现**：测速结果独立置于协议名称上方，测速中显示“测速中...”与加载动画；测速完成后以 `↓`（下行跑满最高速度）与 `↑`（上行跑满最高速度）清晰展示，彻底解决卡片空间狭小导致的重叠、残缺和乱码问题。
- **协议与延迟布局解耦**：协议名称（如 VLESS）居左，延迟（如 150 ms 或 ⚡）居右，各得其所，互不挤压。
- **长按菜单精简**：删除“导出剪贴板”选项，保持菜单聚焦于测速、延迟测试与节点详情。

### 测速引擎与响应机制改进
- **滑动窗口峰值采集**：引入 300ms 滑动窗口速率采集器，精确记录并展示测试期间跑满的最高速度（Peak Speed）。
- **3 节点并发工作池**：一键测所有节点速度采用并发调度，大幅缩短整体测速时间，各节点即测即刷新。
- **快速失败防卡死**：单个节点连接建立超时缩短至 2.5 秒，无效/虚拟节点快速跳过，彻底解决全组测速看似无响应的问题。

### 新增设置项
- **测速链接自定义**：在基础设置中新增“测下载速度、上传速度的测速链接”选项，支持自定义测速 URL 并持久化保存。

## [v1.0.4] - 2026-10-22 (AuTu 1.0.4 预览版)

### 节点长按操作菜单 (Proxy Card Context Menu)
- **卡片长按手势与触感反馈**：代理节点卡片支持长按手势（`onLongPress`），触发轻微触感振动反馈（`HapticFeedback.mediumImpact`）。
- **上下文菜单与功能集成**：
  - **测试当前节点速度**：支持快捷测试单个节点的速度，提供“测试上行+下行”、“测试上行”、“测试下行”三项子菜单。
  - **URLTEST (延迟测试)**：一键执行单个节点的网络延迟测试。
  - **查看节点详情**：弹窗展示节点名称、协议类型、延迟及上下行测速速率。
  - **导出剪贴板**：支持一键复制节点分享链接或节点名称到系统剪贴板。
- **卡片实时速率呈现**：测速完成后，节点卡片原有延迟区域自动动态展示测速结果（例如：`184 ms · ↓24.5 M/s ↑3.2 M/s`）。

### 策略组头部速度测试按钮 (Group Header Speed Test)
- **汽车油门仪表盘样式按钮**：在策略组操作栏最左侧新增汽车速度仪表盘图标按钮（`AppGlyphs.speed`）。
- **一键批量测速**：点击按钮弹出浮动菜单，支持 3 种批量测速模式：
  1. 测试上行+下行
  2. 测试上行
  3. 测试下行
- **测速状态动效**：测速过程中图标自动切换为旋转加载指示器，测速完成后恢复并即时同步各节点速率。

### 核心测速引擎 (Core Speed Test Engine)
- **专有出站拨号**：Go 核心层通过目标节点专属 `proxy.DialContext` 建立独立连接，实现无需切换当前全局/活动代理的定向测速。
- **流量节约保护**：测速时间窗口限制在 4 秒以内，下行采用流式丢弃计数，上行采用零拷贝流式载荷，杜绝内存堆积与流量浪费。
- **双层兼容降级**：客户端提供基于 `CoreMethod.speedTest` 与 `probe` 的双层兼容策略，确保各平台各版本环境下的高可用性。

## [v1.0.3] - 2026-10-21 (AuTu 1.0.3 预览版)

### 超级岛 (Live Updates Capsule / Super Island)
- **Android 16 原生实况规范适配**：深度接入 Google Android 16 Rich Ongoing Notifications (Live Updates) 规范，通过 `requestPromotedOngoing` 与 `shortCriticalText` 在挖孔屏旁极简常驻显示。
- **主流 ROM 实况胶囊兼容**：全面兼容 OriginOS 原子岛、HyperOS 焦点通知、Flyme 灵动胶囊及 ColorOS 流体云协议。
- **智能地区提炼引擎 (`RegionExtractor`)**：内置 29+ 个国家与主要地区规则库，自动根据当前选中的代理节点提炼纯净的 2~4 字地区标签（如“香港”、“日本”、“新加坡”、“美国”）。
- **原生极简视觉规范**：移除彩色大圆盘底色，保持通透的原生 Logo 质感，清空 `subText` 避免系统强行穿插挤压排版。

### 通知中心 (Notification Center) 重构
- **节点名称智能联动**：通知标题动态同步显示选中的代理节点名称（`AuTu · [节点名称]`），节点变更实时生效。
- **双行精细化排版 (`BigTextStyle`)**：
  - 折叠态：极简单行实时上下行网速（`↑X.X KB/s  ↓X.X MB/s`）。
  - 展开态：双行精细化呈现，第一行实时速率，第二行累计已用流量（`Core.getTotalTraffic`）。
- **彻底杜绝幽灵残影**：优化生命周期销毁机制，停止 VPN 服务时显式取消前台通知与状态栏胶囊，彻底杜绝通知残影或白条。
- **息屏节能机制**：屏幕熄灭时自动挂起轮询刷新，屏幕点亮时每秒精准采集并进行差异比对，未发生变化不触发无谓重绘。

## [v1.0.2] - 2026-10-20 (AuTu 1.0.2 预览版)

### Icon Scaling Refinement
- **Balanced Logo Proportions**: Reduced center logo size to ~61% of visible circle diameter (~41% of adaptive canvas), providing generous, harmonious padding around the motif matching reference standard (FlClash) without being overly small.
- **Updated Full Asset Suite**: Synchronized the refined logo proportion across all density mipmaps (`mipmap-mdpi` through `mipmap-xxxhdpi`), night mipmaps, Android TV banner, notification drawables, and multi-size ICO/PNG desktop assets.

## [v1.0.1] - 2026-10-20 (AuTu 1.0.1 预览版)

### Icon & Adaptive Launcher Fixes
- **Fixed Launcher Icon Zoom/Crop Issue**: Re-engineered all Android adaptive icon foregrounds into density-specific mipmap buckets (`mipmap-mdpi` through `mipmap-xxxhdpi`), eliminating abnormal 400% zoom caused by unqualified drawable dimensions.
- **Enhanced Safe Zone & Aspect Ratio**: Motif is now precisely centered within the 72dp adaptive safe zone with clean 18dp padding, ensuring pristine rendering across all Android launchers (circle, squircle, round rectangle).
- **Seamless System Auto-Follow & Night Mode**:
  - Added dedicated `mipmap-night-anydpi-v26/` resource tree so launcher icons automatically switch between light and dark modes according to the phone's system settings.
  - Added full atomic component switching on Android 13+ via `setComponentEnabledSettings` to prevent launcher caching issues or icon flickering.
- **Refined Notification & TV Assets**: Fully synchronized notification drawables and Android TV banner with the new motif geometry.

## [v1.0.0] - 2026-10-18 (AuTu 1.0.0 预览版)

### Branding & Visuals
- **New Brand Identity**: Completely rebranded from OuTo to **AuTu**.
- **Dynamic Dual Icons**:
  - Introduced new brand icons featuring light mode (white background, black motif) and dark mode (black background, white motif).
  - **Desktop Launcher**: Switches dynamically between light and dark launcher icons, or automatically follows system night mode.
  - **Notification Center**: Notification badge and service icon seamlessly adjust between light and dark themes to match in-app and system modes.
  - **Auto Follow System**: Fully respects Android system-wide dark/light settings.

### Core & Stability
- **Fixed Android Startup Crash**: Resolved class stripping caused by stale R8 ProGuard rules; all Kotlin components, plugins, and state models are fully preserved.
- **Unified Release Signing**: Integrated unified, permanent release signing keys managed via GitHub Actions Secrets, guaranteeing zero signature mismatches across upgrades.
- **Mihomo (Clash.Meta) Core**: High-performance TUN proxy, multi-protocol splitting, and low latency routing.
- **Pure & Clean**: 100% open source, ad-free, and privacy-first.
