# Changelog

All notable changes to the AuTu project will be documented in this file.

## [v1.0.11] - 2026-10-28 (AuTu v1.0.11 Preview)

### 全面升级为 Bettbox (Another Better Network Toolbox) 现代客户端底座
- **底座换骨与体验重构**：全面接入 Bettbox 现代轻量跨平台客户端底座，在保留 AuTu 品牌的同时带来质的体验飞跃。
- **全新“无界”视觉风格**：引入现代卡片式仪表盘设计、流畅动画转场、Material You 动态取色、悬浮侧边栏与精细化主题调节。
- **全功能网络调试工具箱**：
  - **iPerf3 测速**：内置全平台原生 iPerf3 测速模块，完美兼容官方网络带宽测速标准协议。
  - **DNS 诊断查询**：支持多服务器、多类型的图形化 DNS 调试与即时解析比对。
  - **本地 ICMP Ping**：提供低延迟、高精度的本地与远程网络延迟追踪。
  - **STUN NAT 测试**：快速探测当前网络 NAT 类型（Full Cone, Restricted Cone, Port Restricted, Symmetric）。
  - **流媒体解锁检测**：优化主流流媒体平台（Netflix、YouTube Premium、Disney+ 等）解锁状态批量探测。
- **WebDAV 云端加密自动备份**：支持配置通过 WebDAV 协议进行 AES 强加密自动云端同步与多端备份。
- **Android 16KB Page Size 原生支持**：底层 CGO / C++ 与动态链接库全面启用 `-Wl,-z,max-page-size=16384`，原生完美兼容 Android 15+ 全新内存对齐架构。
- **严格锁定品牌与图标资产**：
  - 应用名称严格保持 **AuTu**；
  - Android 应用包名严格维持 **`com.outo.app`**（统一签名证书与密钥，支持从旧版平滑覆盖更新）；
  - 100% 继承 AuTu 专属的 **81.3% 高度黄金比例灵动岛/状态栏图标**与全套桌面图标；
  - 移除非必要冗余选项，保持开源、纯净、无广告。

## [v1.0.10] - 2026-10-24 (AuTu v1.0.10 Preview)

### 内核升级 (Mihomo v1.19.33) 与安全修复
- **安全漏洞修复**：修复 `crypto/tls` 的安全漏洞 **CVE-2026-97031**。
- **协议与传输优化**：TUN 模式支持 `dns-mode`；重构优化 Sudoku 传输混淆与多路复用并提高性能；Wireguard 网络栈改为延迟初始化（Lazy Init）。
- **性能算法重构**：重构 `dialer-proxy` 循环检测算法，时间复杂度由 $O(n^2)$ 降为 $O(n)$，极大降低代理链场景下的 CPU 与内存占用；修复极速节点测速误判为失败的 Bug。
- **DNS 即时刷新**：支持主动与网络切换时即时刷新清空 DNS 缓存（`clearDnsCache`），避免旧 IP 残留与连接挂死。
- **底层依赖库升级**：`mieru` 升至 v3.38.1、`sing-tun` 升至 v0.4.28、`metacubex/tls` 升至 v0.1.9。

## [v1.0.9] - 2026-10-24 (AuTu v1.0.9 Preview)

### 状态栏与灵动岛 Logo 图标比例优化
- **重构状态栏与灵动岛通知图标规范**：将通知图标（`ic_service`）的有效图形高度占比从 40.6% 提升至 81.3%，裁剪去除多余透明留白边距，使灵动岛收起折叠态（胶囊）中的 `a` 图标高度从 ~9.6dp 提升至 ~19.5dp，与右侧地区文本（如“日本”）视觉重量 1:1 协调平衡。
- **展开卡片 Logo 视觉饱满化**：展开实况通知窗右上角的原生 Logo 同步放大，彻底消除微弱小白点感，保持清晰饱满。
- **全套通知与磁贴资源同步**：同步更新 `ic_service.png`、`ic_service_dark.png`、`ic_service_light.png` 及下拉磁贴 `ic.png`，同时完整保留桌面启动图标。
