# 泡泡糖项目工作约定

本文件适用于整个游戏目录。面向玩家的说明见 [README](README.md)，开发入口见 [docs](docs/README.md)。需求不清楚时先确认，再编程。

## 开始工作

- 先看 `git status --short`，保留已有修改。项目有独立 Git 仓库，所有 Git 操作在本目录执行。
- 阅读 [项目分析](docs/项目分析.md)，再读本次相关模块。改玩法时同时看 `game.gd` 与相应协作模块。
- 使用 `rg` 搜索源码。以实际实现为准，文档中的历史验收记录不能证明当前工作区已通过。
- 默认使用简体中文沟通、写文档和玩家界面。新增可见文字需要同步五种语言目录。
- 不编写单元测试，除非用户明确要求。使用真实 Godot 导入、启动检查和对应玩法的实机验收。
- 保持现有直接协作方式，避免增加与当前需求无关的框架、抽象层和依赖。

## 统一命令

Python 3 标准库即可运行 harness。Godot 通过 `--godot`、`GODOT_BIN` 或 PATH 指定。

```sh
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
python3 tools/harness.py doctor
python3 tools/harness.py check
python3 tools/harness.py run
python3 tools/harness.py editor
python3 tools/harness.py pack
python3 tools/harness.py build-macos
```

命令范围、通过条件和故障处理见 [harness 使用说明](docs/harness.md)。`check` 检查导入与大厅启动，不代表完整对局或画面已验收。需要实机确认的项目见 [开发与验收](docs/开发与验收.md)。

## 改动边界

- `game.gd` 持有共享状态，其他模块通过 `g` 调用它。不要独立复制地图、玩家、泡泡或掉落状态。
- 角色移动按用户要求改为连续位置 `visual` 与小脚底碰撞体；`cell` 从实际位置就近取整，用于泡泡放置、机关、伤害和拾取。不要提前把 `cell` 设为移动终点，怪物与 Bot 路由仍使用网格。
- 网格值固定为 `0` 空地、`1` 墙、`2` 箱、`3` 坍塌地块。改箱体覆盖时维护 `crates.by_cell` 与 `grid`。
- 地图、主题、道具、角色、坐骑索引由 `scripts/data/catalog.gd` 决定；剧情索引由 `scripts/data/story.gd` 决定。新增内容时检查硬编码计数、图鉴、Bot、素材图集、翻译和文档。
- 泡泡路径同时影响水柱、预警与 Bot 避险。改伤害或属性时检查 `blast_cells`、`danger_cells`、`bubble_effects.gd` 与 `adventure.gd`。
- 保持玩家一 Q、玩家二 / 的道具键；保持 1080p、本机最多四名真人、对战最多八个席位、中文可用。改变这些约定须有明确需求。
- 真实存档是 `user://profile.json`，写入采用临时文件再重命名。修改存档字段时为旧存档提供默认值，禁止重置玩家进度。
- 美术与音频生成脚本会覆盖资源，只运行本次需要的脚本，并按 [资源制作](docs/资源制作.md) 的依赖顺序执行。

## 文件放置

具体规则见 [文件与资源管理](docs/文件与资源管理.md)。

- 游戏资源放 `assets/`，原创制作脚本放 `tools/`，保留第三方授权声明。
- 临时截图、预览、运行报告、日志与检查存档放 `/tmp/paopaotang-*`。不要放项目根目录。
- `docs/screenshots/` 只保留文档实际引用、准备交付的精选图片。Godot 缓存、运行时、安装包和 `dist/` 不提交。
- 本项目按用户要求只维护 `res://` 路径引用，不维护 `.uid`。`.uid`、`.import` 与 `.godot/` 均忽略；编辑器可能重新生成。
- 不因增加检查工具而自动重制音乐、批量更新翻译、修改角色数值或重打包大型应用。

## 交付

先完成必要检查，再报告改动、检查结果、证据目录和未覆盖项。不要把“导入通过”写成“所有地图可通关”。只有明确要求提交或推送时才处理相应 Git 操作；不要把无关的已有工作区修改一起提交。

源码按职责放在 `scripts/core/`、`scripts/gameplay/`、`scripts/render/`、`scripts/ui/`、`scripts/data/`；场景放 `scenes/`，工具保持 `tools/`。禁止将游戏脚本重新平铺到根目录。
