# 开发工具

统一入口：`python3 tools/harness.py`。从项目根目录运行，使用 `--godot` 或 `GODOT_BIN` 指定引擎。

| 目录 | 工具 |
| --- | --- |
| `art/` | `index_atlases.py`：分析在用原图的透明边界，生成分类路径裁切索引，不修改原图 |
| `audio/` | `compose_themes.py`、`compose_music_expansion.py`：制作原曲和新增配乐；`create_sfx.py`、`create_bubble_audio.py`、`create_round_audio.py`：制作音效与回合音乐 |
| `i18n/` | `refresh_translations.py`：联网补充翻译；`polish_locales.py`：维护离线翻译 |
| `build/` | `build_macos.py` 和 `launcher.c`：构建 macOS 应用 |
| `checks/` | `harness_smoke.gd`：真实主场景与隔离存档启动检查，由统一入口调用 |

生成器会覆盖目标文件，运行游戏无需执行。泡泡音效重制时，先执行 `create_bubble_audio.py`，再执行 `create_round_audio.py`，保留强化破泡音效。不要在普通启动检查中批量生成素材或刷新翻译。

制作依赖与资源规格见 [资源制作](../docs/资源制作.md)，统一命令见 [harness 使用说明](../docs/harness.md)。
