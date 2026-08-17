# menu-bar-macOS

从 OS X El Capitan (10.11) 安装镜像中提取的、与 macOS 桌面顶部菜单栏相关的系统文件。

## 来源

- 镜像：`InstallMacOSX.dmg`（OS X El Capitan 10.11.6），来自 Apple 官方下载页
  `https://support.apple.com/en-us/102662`（链接 `updates-http.cdn-apple.com/.../061-41424-.../InstallMacOSX.dmg`）。
- 提取链路：`InstallMacOSX.dmg` → (7z) → `InstallMacOSX.pkg` (xar) → `InstallESD.dmg` →
  (7z) → `BaseSystem.dmg` + `Packages/Essentials.pkg` → (xar) → `Payload` (pbzx) →
  (pbzx 解码 + cpio) → 完整系统文件树。
- pbzx 块长度字段为大端 uint64，参考 https://github.com/NiklasRosenstein/pbzx 。

## 目录结构

```
menu-bar-macOS/System/Library/
├── CoreServices/
│   ├── SystemUIServer.app   # 菜单栏右侧状态项的宿主进程 (com.apple.systemuiserver, LSUIElement)
│   └── Menu Extras/         # 23 个 .menu 包，菜单栏右侧图标组件
└── Frameworks/
    └── AppKit.framework     # 菜单栏 UI 全部 API (NSStatusBar/NSStatusItem/NSMenu/NSMenuExtra)
```

## 关键组件

### SystemUIServer.app
- `CFBundleIdentifier = com.apple.systemuiserver`，`LSUIElement = 1`（无 Dock 图标的后台 App）。
- 通过 HIToolbox 私有 C API 动态加载/卸载 Menu Extra：
  `CoreMenuExtraAddMenuExtra` / `CoreMenuExtraGetMenuExtra` / `CoreMenuExtraRemoveMenuExtra`。
- `Contents/Resources/Autoload.plist`：启动时候选自动加载的 Menu Extra 白名单
  （每项含稳定数字 id 与 `_xxxCanLoad` 判定方法，如 Clock=‑10000、Battery=‑10001、AirPort=‑10004）。
- `BundleIDMapper.plist` / `DefaultActions.plist`：Eject.menu 的媒体键/设备动作数据驱动配置。

### Menu Extras/（23 个 .menu）
每个 `.menu` 是一个 bundle，`Info.plist` 中：
- `NSPrincipalClass`：一个 `NSMenuExtra` 子类（如 Clock 的 `AppleClockExtra`）。
- `NSMenuExtraWidth`：固定像素宽度（缺失或 0 表示动态宽度）。

| .menu | bundle id | PrincipalClass | width | version |
|---|---|---|---|---|
| Clock | com.apple.menuextra.clock | AppleClockExtra | 140 | 3.1.1 |
| Volume | com.apple.menuextra.volume | AppleVolumeExtra | 25 | 6.0 |
| Battery | com.apple.menuextra.battery | BatteryExtra | 0(动态) | 6.0 |
| AirPort | com.apple.menuextra.airport | AirPortExtra | 22 | 11.0 |
| Bluetooth | com.apple.menuextra.bluetooth | AppleBluetoothExtra | 22 | 4.4.6 |
| Displays | com.apple.menuextra.airplay | DisplaysExtra | 25 | 3.0 |
| Eject | com.apple.menuextra.eject | ProcessExtra | 22 | 2.0.3 |
| TextInput | com.apple.menuextra.textinput | AppleTextInputExtra | 22 | 1.2.1 |
| User | com.apple.menuextra.appleuser | AppleUser | 22 | 8.0 |
| VPN | com.apple.menuextra.vpn | AppleVPNExtra | 22 | 1.6 |
| TimeMachine | com.apple.menuextra.TimeMachine | AppleTimeMachineExtra | 动态 | 10.9 |
| UniversalAccess | com.apple.menuextra.universalaccess | UAMenu | 动态 | 7.0 |
| Script Menu | com.apple.scriptmenu | AppleOSAScriptMenu | 22 | 1.2.7 |
| RemoteDesktop | com.apple.menuextra.remotedesktop | AppleRDExtra | 22 | 3.8.5 |
| WWAN | com.apple.menuextra.wwan | AppleWWANExtra | 动态 | 3.0.0 |
| iChat | com.apple.menuextra.iChat | AppleFezExtra | 22 | 7.0 |
| ExpressCard | com.apple.menuextra.expresscard | AppleExpressCardExtra | 22 | 2.0 |
| Fax | com.apple.menuextra.fax | AppleFaxExtra | 22 | 11.0 |
| HomeSync | com.apple.menuextra.cinch | AppleMHDExtra | 动态 | 5.0 |
| Ink | com.apple.menuextra.ink | AppleInkExtra | 22 | 10.9 |
| IrDA | com.apple.cpusw.IrDA | IrDAExtra | 20 | 1.4.5 |
| PPP | com.apple.menuextra.ppp | PPPConnectExtra | 22 | 1.9 |
| PPPoE | com.apple.menuextra.pppoe | PPPoEConnectExtra | 22 | 1.9 |

### AppKit.framework
菜单栏 UI 全部 API：
- 公开：`NSStatusBar`（`systemStatusBar`/`statusItemWithLength:`/`removeStatusItem:`/`thickness`）、
  `NSStatusItem`、`NSMenu`（`+menuBarHeight`/`+menuBarVisible`/`+setMenuBarVisible:`）。
- 私有：`NSStatusBarWindow`、`NSStatusBarButton`/`NSStatusBarButtonCell`、
  `NSStatusBar(NSStatusBarCGS)`（`_CGSinsertWindow:withPriority:withSpaceID:withDisplayID:withFlags:`，按 Space/Display 优先级插入）、
  `NSStatusBar(NSStatusBar_Appearance)`（`_placement`/`_direction`/`_createStatusItemWindow`）、
  `NSStatusItemReplicant`（跨屏复制）、`NSExitFullScreenStatusItem`、
  `NSAccessibilityMenuExtrasMenuBar`。
- HIToolbox C 层：`_HIMenuGetMenuBarHeight`、`GetThemeMenuBarHeight`、`_HIMenuBarSetAutoHideHeight`、
  `_HIMenuBarPositionLock/Unlock`、`_HIMenuBarRequestVisibility`、`IsMenuBarVisible`。

## 菜单栏架构

桌面顶部菜单栏分左右两部分，由不同进程/框架负责：

- 左侧（应用菜单条，Apple 菜单 + 当前 App 菜单）：由 AppKit 在每个应用进程内绘制
  （`NSMenu` + `NSMenuView`），高度缓存于 `NSScreen._cachedMenuBarHeight`。
- 右侧（系统状态项 / Menu Extras，时钟、音量、电池、WiFi 等）：由独立进程
  SystemUIServer 承载，用 `CoreMenuExtra*` 加载 .menu 包为 `NSMenuExtra` 子类，
  由 `NSStatusBar` 统一布局、按 priority/space/display 插入，与 WindowServer 经
  `_CGSMenuBarExists` 等交互。

## 跨平台开发参考要点

1. macOS 菜单栏不在窗口内，而是全局顶部条由当前 key app 的 AppKit 绘制；
   跨平台框架想"贴近原生 macOS 体验"，菜单应通过 `NSMenu`/`NSApplication` 主菜单贡献。
2. 右侧状态项不是各自绘制，而是被 SystemUIServer 统一聚合。跨平台"托盘图标"
   在 macOS 上应映射到公开稳定的 `NSStatusItem`，而非模仿 .menu 私有机制。
3. 宽度：`NSStatusItem` 用 `NSVariableStatusItemLength`（动态）或固定像素；
   `NSMenuExtraWidth` 是 .menu 的固定宽度声明。
4. 多屏/多 Space：状态项可按 Space/Display 选择性显示
   （`_CGSinsertWindow...withSpaceID:withDisplayID:`、`NSStatusItemReplicant`）。
5. 主题/透明度适配：菜单栏有 `_menuBarThemeDidChange:` / `_menuBarTranslucencyDidChange:` 通知，
   状态项图标需适配深浅色与透明背景。
6. 自动隐藏：`NSApplicationPresentationAutoHideMenuBar`，对应 `_HIMenuBarSetAutoHideHeight`。

## 法律说明
本目录包含的文件为 Apple Inc. 拥有的 macOS 系统二进制/资源，源自 Apple 官方分发渠道，
仅用于互操作性研究与跨平台菜单栏开发参考。版权归 Apple Inc. 所有。
