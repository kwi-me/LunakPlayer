# Lunak Player

本地音乐播放器，iOS 16+，SwiftUI 全手写。视觉按你给的那张 Y2K 数码音响说明书风格还原：纸灰底、压缩标题、CD 盒 + 光盘、频谱、深蓝歌词卡。

- 纯本地播放，不联网、不要账号、不上传任何文件
- 曲库来自 App 沙盒（`Documents/`），支持 mp3 / m4a / flac / wav / aiff / caf
- 自动读 ID3 标题、艺术家、封面；同名 `.lrc` 自动挂载歌词，逐行高亮
- 锁屏 / 控制中心可控制，支持后台播放
- 通过 GitHub Actions 在 macOS runner 上编译**未签名 ipa**，Windows 上用 Sideloadly 自签安装

---

## 一、出 ipa（不需要 Mac）

1. 新建一个 GitHub 仓库（Private 也可以），把本目录全部内容推上去：

```bash
cd LunakPlayer
git init
git add .
git commit -m "init"
git branch -M main
git remote add origin https://github.com/<你的用户名>/<仓库名>.git
git push -u origin main
```

2. 推送完成后，仓库的 **Actions** 页会自动跑 `Build unsigned IPA`（约 3–5 分钟）。
3. 点进这次运行，页面底部 **Artifacts** 下载 `LunakPlayer-unsigned-ipa`，解压得到 `LunakPlayer-unsigned.ipa`。

> 想手动触发：Actions → 左侧 `Build unsigned IPA` → 右侧 `Run workflow`。
> 构建失败时，日志里通常是 XcodeGen 或 xcodebuild 的报错行，把那段贴给我即可。

---

## 二、装到 iPhone（Windows）

免费 Apple ID 就够，不需要 99 美元开发者账号。

1. Windows 装 [Sideloadly](https://sideloadly.io/) 和 iTunes（Sideloadly 依赖 iTunes 的驱动）。
2. iPhone 用数据线连电脑，解锁并点「信任」。
3. 把 `LunakPlayer-unsigned.ipa` 拖进 Sideloadly，`Apple ID` 填你的账号，点 Start。
4. 首次运行会提示「不受信任的开发者」：
   **设置 → 通用 → VPN与设备管理 → 开发者应用 → 信任**
5. iOS 16 以上还需要打开开发者模式：
   **设置 → 隐私与安全性 → 开发者模式 → 打开 → 重启**

**免费账号的三个限制**（不是这个 App 的问题，是所有侧载 App 的通用限制）：

| 限制 | 说明 |
|---|---|
| 7 天有效期 | 到期后 App 打不开，重新用 Sideloadly 装一次即可（不会丢文件） |
| 最多 3 个 App | 同一 Apple ID 同时最多 3 个自签 App |
| 需要重签 | 想免手动，可以装 AltStore，让电脑上的 AltServer 每 7 天自动续签 |

---

## 三、放音乐进去

三种方式，任选：

1. **App 内导入** —— 点界面下方 `LIBRARY → IMPORT AUDIO FILES`，从「文件」App 里多选音频（会自动复制进沙盒）。
2. **文件 App 拖入** —— 「文件」→ 我的 iPhone → **Lunak** 文件夹，把 mp3 拷进去。
3. **电脑拖入** —— Finder（macOS）或 iTunes（Windows）→ 设备 → 文件共享 → Lunak → 拖文件。

放完之后回到 App，进入 LIBRARY 会自动刷新。

**歌词**：把 `歌名.lrc` 和 `歌名.mp3` 放在同一目录、同名即可，UTF-8 或 GB18030 都行。

---

## 四、界面结构

```
Masthead      lunak 字标 / DIGITAL AUDIO 技术条 / 两行压缩标题 + 风格标注
PlayerWindow  ─ 标题栏 LUNAK MEDIA PLAYER
              ─ CD 区（CD 盒 + 旋转光盘）
              ─ 曲目深蓝卡（序号、标题、时间、52 段频谱、可拖动进度）
              ─ 传输控制（STOP / PREV / PLAY / NEXT + 音量）
              ─ 底栏（STEREO 44.1 KHz / LWK 编号 / 条形码）
LyricsCard    深蓝歌词卡，当前行大字 + 中文翻译，逐行滑动切换
LibraryBar    曲库入口（也可以直接点 CD 区或光盘）
```

点击播放键或光盘可以暂停/继续；暂停时光盘停转、频谱落下。

---

## 五、代码结构

```
LunakPlayer/
├─ project.yml                  XcodeGen 工程描述（不提交 .xcodeproj）
├─ .github/workflows/build-ipa.yml
├─ LunakPlayer/
│  ├─ App/LunakPlayerApp.swift
│  ├─ Core/
│  │  ├─ Theme.swift            配色、字体、MonoText/Sparkle/网格等原子组件
│  │  ├─ AudioPlayer.swift      AVAudioPlayer + 30fps 节拍（进度/频谱/唱片角度/歌词）
│  │  ├─ LibraryStore.swift     沙盒扫描、元数据读取、导入/删除
│  │  └─ LyricsParser.swift     LRC 解析（多时间戳、双语合并、GB18030 回退）
│  ├─ Models/Song.swift
│  ├─ Views/
│  │  ├─ RootView.swift         页面骨架
│  │  ├─ HeaderBlock.swift      报头
│  │  ├─ PlayerWindow.swift     窗口外壳 + 曲目卡 + 频谱 + 传输条
│  │  ├─ CDStage.swift          CD 盒、旋转光盘
│  │  ├─ LyricsCard.swift       歌词卡
│  │  ├─ LibrarySheet.swift     曲库面板 + 文件导入
│  │  └─ Backdrop.swift         纸纹背景 + 唱片纹
│  ├─ Assets.xcassets           App 图标（脚本生成）
│  └─ Info.plist                文件共享、后台音频、竖屏锁定
└─ preview/index.html           纯 HTML 版的 UI 预览（浏览器直接打开）
```

---

## 六、想改的话

| 想改的东西 | 位置 |
|---|---|
| 主色 / 纸色 / 深蓝 | `Core/Theme.swift` 的 `Ink` |
| 标题字体大小 | `HeaderBlock.swift` 里 `DisplayText(size: 54)` |
| CD 区高度 | `CDStage.swift` 的 `.frame(height: 298)` |
| 频谱条数量 | `AudioPlayer.swift` 的 `barCount`（默认 52） |
| 光盘转速 | `AudioPlayer.tick()` 里 `discAngle += 2.1` |
| App 名 / Bundle ID | `project.yml` 的 `PRODUCT_NAME`、`PRODUCT_BUNDLE_IDENTIFIER` |

改完 push，Actions 会自动重新出包。

---

## 七、已知限制

- **不是真的频谱**：用 `AVAudioPlayer.averagePower` 的整体电平 + 频段权重模拟，视觉接近但不做 FFT。想上真频谱，把 `AudioPlayer` 换成 `AVAudioEngine` + `vDSP_FFT`。
- **无法读取系统「音乐」App 的资料库**：Apple Music 的版权曲目不能导出，所以只走沙盒文件。这是 iOS 的硬限制。
- **未签名包不能上架、不能推送**，只能自签安装，仅适合自己和朋友用。
- 封面取不到时会用程序生成的蓝色渐变封面，不会崩。
