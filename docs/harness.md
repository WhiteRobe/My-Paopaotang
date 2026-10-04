# Harness 使用说明

harness 提供项目级命令，帮助 AI 和开发者进入工程、发现资源或脚本错误并保留检查证据。它调用真实 Godot 主场景，不增加单元测试，也不替代玩法与画面的实机验收。

## 设置引擎

```sh
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
python3 tools/harness.py doctor
```

也可以直接指定路径：

```sh
python3 tools/harness.py --godot /你的路径/Godot check
```

查找顺序为 `--godot`、`GODOT_BIN`、PATH 中的 `godot` 或 `godot4`，最后尝试 macOS 标准应用路径。必须使用 Godot 4.x 编辑器程序，导入与导出命令需要编辑器能力。Python 工具本身只依赖标准库。

## 命令范围

| 命令 | 做什么 | 输出与限制 |
| --- | --- | --- |
| `doctor` | 检查引擎版本、入口、静态资源引用、翻译 JSON、音乐目录和可选工具 | 制作依赖未安装只提示，不妨碍运行已有素材 |
| `check` | 上述预检，Godot 编辑器导入，真实主场景启动并运行默认 120 帧 | 使用临时存档，读取实际内容目录；只覆盖大厅启动 |
| `run` | 用正常显示窗口运行工程 | 使用正常玩家存档；退出后命令结束 |
| `editor` | 打开当前工程的 Godot 编辑器 | 与日常开发一致 |
| `pack` | 预检、导入、调用 macOS 预设导出 PCK，再从 PCK 启动真实主场景 | PCK 与临时启动存档写入 `/tmp`，不制作完整应用 |
| `build-macos` | 调用已有 macOS 构建脚本 | 在 macOS 上执行，完整应用和 ZIP 写入 `dist/` |

```sh
python3 tools/harness.py check
python3 tools/harness.py check --frames 240
python3 tools/harness.py --timeout 300 pack
python3 tools/harness.py run
python3 tools/harness.py editor
python3 tools/harness.py build-macos
```

`--timeout` 为每个非交互阶段的最大等待秒数，默认 180；运行游戏与编辑器不会被该超时自动关闭。检查帧数是引擎迭代数，不等于完整对局或真实秒数。

## 存档与证据

每次调用创建 `/tmp/paopaotang-harness-<随机后缀>/`，终端打印实际路径。报告为 `report.json`，包含命令、引擎路径、版本、状态、错误或内容概况。引擎日志和 stdout 日志分别保存，失败时显示日志末尾。

`check` 与 `pack` 使用 `tools/harness_smoke.gd` 作为启动桥接：实例化真实 `main.tscn`，在加入场景树、触发 `_ready()` 之前，将 `game.save_path` 设置为本次 `/tmp` 下的 `profile.json`。这样既不会读取真实玩家存档，也不会覆盖它。桥接只用于 harness，不改变正常游戏入口。`pack` 的桥接从外部文件加载，游戏资源从导出 PCK 读取；不把开发工具塞进发布包。

`content.json` 从实际加载的目录读取地图、主题、道具、人物、坐骑、剧情和语言计数，并核对地图数量、主题资源与剧情引用。`item_entries` 包含空道具和星币，`mount_entries` 包含无坐骑项，不能直接当作玩家可用种数。

检查失败时返回非零退出码；即便 Godot 退出码为零，只要日志出现 `SCRIPT ERROR:`、`ERROR:` 或解析错误，也会判失败。超过最大等待时间会停止该子进程并留下日志。不要仅看引擎是否退出。

导入仍会生成当前工程的 `.godot/`、`.import` 或缺少的 `.uid`；它们的放置遵循 Godot 机制。harness 的报告、日志和存档始终在 `/tmp`，大型发布产物在忽略的 `dist/`。

## 通过条件与边界

通过意味着入口与字面资源存在、相关 JSON 可读取、引擎导入无报错、真实大厅完成初始化并运行指定帧数、基本内容索引有效。它不会声称所有语言占位符正确、所有地图能通关、Bot 能完成全部任务或所有画面正常。

当前未加入自动对局模拟、脚本注入道具、截图基线对比、CI 或自动提交。玩法改动按 [开发与验收](开发与验收.md) 手工跑相应路径，画面改动在非 headless 渲染环境确认；需要扩大自动化范围时先明确场景与通过标准。

## 常见问题

| 情况 | 处理 |
| --- | --- |
| 找不到引擎 | 指向真正的 Godot 可执行文件，macOS 使用 `.app/Contents/MacOS/Godot` |
| 缺少资源或解析失败 | 查看本次日志，先修复首个资源或 GDScript 错误再重跑 |
| 导入成功但没有内容报告 | 主场景未完成初始化，检查 `startup.log` |
| 打包超时 | 增大 `--timeout`，检查导入、签名或导出进程状态 |
| macOS 构建失败 | 确认 Pillow、clang、iconutil、codesign、ditto 与现有构建依赖可用 |
| 无窗口检查通过但画面错误 | 使用 `run`，核对 shader、裁切、字体、昼夜与音效 |

日志保留到用户自行清理或系统清理 `/tmp`。不自动删除已有证据目录，也不把报告复制进源码仓库。
