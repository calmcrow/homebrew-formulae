# Calmcrow Formulae

```bash
brew tap calmcrow/formulae
brew install calmcrow/formulae/winghexexplorer2
```

## 启动

```bash
open /usr/local/opt/winghexexplorer2/WingHexExplorer2.app
```

要让 Cmd+Space (Spotlight) 能搜到，创建软链到 /Applications：

```bash
ln -s /usr/local/opt/winghexexplorer2/WingHexExplorer2.app /Applications/WingHexExplorer2.app
```

---

## winghexexplorer2

[WingHexExplorer2](https://github.com/Wing-summer/WingHexExplorer2) — 十六进制编辑器，支持 AngelScript 脚本。

### 构建方式

- **架构**: Intel x86\_64 / Apple Silicon arm64（通过 `Hardware::CPU.arm?` 自动检测并设置 LSP 的 `PKG_TARGET`，主程序由 clang 原生输出。暂未经 arm64 实机验证，如遇问题请提 [issue](https://github.com/calmcrow/homebrew-formulae/issues) 或 PR）
- **依赖**: Qt6、OpenSSL、zstd、libdwarf、pkg-config

### macOS 兼容性补丁

通过 `Formula/winghexexplorer2-macos-compat.patch` 文件统一管理。

#### 1. fileaccesscheck.cpp

- 将 `#ifdef Q_OS_LINUX` 拆分为 D-Bus 头文件（仅 Linux）和 POSIX 头文件（`#if defined(Q_OS_LINUX) || defined(Q_OS_MAC)`）
- 修正 Qt 官方宏 `Q_OS_MACOS` → `Q_OS_MAC`
- 末尾 `#else` 改为 `#elif defined(Q_OS_LINUX)`，macOS 分支用 `access()` 替代 `fork() + setuid()`
- macOS 路径使用 `QFile::encodeName()` + `::access()`，Qt 标准做法

#### 2. framelesshelper.cpp

macOS 窗口按钮模型不同，dialog 隐藏最小化/最大化按钮用 `#ifndef Q_OS_MAC` 跳过。

#### 3. framelessdialogbase.cpp / framelessmainwindow.cpp

macOS 标题栏无窗口图标，`iconButton()` 返回 `nullptr`。改为 `if (iconBtn) { ... }` 空指针判断。

#### 4. hexlineedit.cpp / qeditconfig.ui

删除 `f.setFamily("Monospace")`，macOS 无此字体别名。保留 `setStyleHint(QFont::Monospace)` + `setFixedPitch(true)`。

#### 5. 3rdparty/QHexView/qhexview.cpp

同上，删除 `f.setFamily("Monospace")`。

### 编译参数

```
-DCPPTRACE_USE_EXTERNAL_ZSTD=ON
-DCPPTRACE_USE_EXTERNAL_LIBDWARF=ON
-DCPPTRACE_FIND_LIBDWARF_WITH_PKGCONFIG=ON
```

### App 部署

- `macdeployqt` 将 Qt 框架打包进 `.app`
- `libWingPlugin.dylib` 复制到 `.app/Contents/Frameworks`，由 `macdeployqt -executable` 一并处理 Qt 路径
