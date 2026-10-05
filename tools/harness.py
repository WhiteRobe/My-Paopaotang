"""Project commands for Godot diagnostics, startup checks and local builds.

Uses Python's standard library. Logs and isolated smoke saves go to /tmp.
"""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
ERROR_LINE = re.compile(r"(?m)^\s*(?:SCRIPT ERROR:|ERROR:|Parse Error:|Shader compilation failed)")
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def engine_path(value):
    candidate = value or os.environ.get("GODOT_BIN")
    if candidate:
        path = Path(candidate).expanduser()
        found = str(path.resolve()) if path.is_file() else shutil.which(candidate)
    else:
        found = shutil.which("godot") or shutil.which("godot4")
        if not found:
            path = Path("/Applications/Godot.app/Contents/MacOS/Godot")
            found = str(path) if path.is_file() else None
    if not found:
        raise ValueError("找不到 Godot，请设置 GODOT_BIN 或传入 --godot。")
    return found


def logged(command, output, name, timeout):
    log = output / (name + ".log")
    print("执行：", " ".join(map(str, command)), flush=True)
    with log.open("w", encoding="utf-8") as stream:
        try:
            result = subprocess.run(command, cwd=ROOT, stdout=stream,
                                    stderr=subprocess.STDOUT, timeout=timeout)
        except subprocess.TimeoutExpired as exc:
            raise ValueError(f"{name} 超时，日志：{log}") from exc
    text = ANSI.sub("", log.read_text(encoding="utf-8", errors="replace"))
    if result.returncode or ERROR_LINE.search(text):
        print("\n".join(text.splitlines()[-25:]), file=sys.stderr)
        raise ValueError(f"{name} 失败，退出码 {result.returncode}，日志：{log}")
    return text.strip()


def preflight():
    errors = []
    for path in [ROOT / "project.godot", ROOT / "scenes/main.tscn"]:
        if not path.is_file():
            errors.append(f"缺少入口：{path.name}")
    sources = [*ROOT.glob("scripts/**/*.gd"), *ROOT.glob("scenes/**/*.tscn"),
               *ROOT.glob("tools/**/*.gd"), *ROOT.glob("assets/**/*.tres"),
               *ROOT.glob("assets/**/*.gdshader")]
    for path in sources:
        for resource in re.findall(r'"(res://[^"\n]+)"(?!\s*\+)', path.read_text()):
            if not (ROOT / resource[6:]).exists():
                errors.append(f"{path.relative_to(ROOT)} 引用缺失：{resource}")
    for path in ROOT.glob("locales/*.json"):
        try:
            data = json.loads(path.read_text())
            if not isinstance(data, dict) or any(not isinstance(v, str) for v in data.values()):
                errors.append(f"翻译目录格式错误：{path.name}")
        except ValueError as exc:
            errors.append(f"JSON 格式错误：{path.name}：{exc}")
    for relative in ["assets/audio/music/themes/catalog.json", "assets/audio/music/catalog.json"]:
        music = ROOT / relative
        if music.is_file():
            for entry in json.loads(music.read_text()):
                if not (music.parent / entry["file"]).is_file():
                    errors.append(f"音乐目录引用缺失：{entry['file']}")
        else:
            errors.append(f"缺少音乐目录 {relative}")
    if errors:
        raise ValueError("\n".join(errors))
    print("入口、资源引用、翻译 JSON 和音乐目录检查通过。")


def main():
    parser = argparse.ArgumentParser(description="泡泡糖项目工具：环境诊断、Godot 启动检查与本地构建。")
    parser.add_argument("--godot", help="Godot 可执行文件；也可设置 GODOT_BIN")
    parser.add_argument("--timeout", type=int, default=180, help="单阶段超时秒数")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("doctor", help="检查引擎、资源和可选制作工具")
    check = commands.add_parser("check", help="导入工程并运行隔离存档的启动冒烟检查")
    check.add_argument("--frames", type=int, default=120)
    commands.add_parser("run", help="交互运行游戏，使用正常玩家存档")
    commands.add_parser("editor", help="打开 Godot 编辑器")
    commands.add_parser("pack", help="导出到 /tmp 下的 game.pck 并检查导出后的启动")
    commands.add_parser("build-macos", help="调用现有脚本生成 dist 下的 macOS 应用")
    args = parser.parse_args()
    if args.timeout <= 0 or getattr(args, "frames", 120) < 2:
        parser.error("timeout 必须为正数，frames 至少为 2。")
    output = Path(tempfile.mkdtemp(prefix="paopaotang-harness-", dir="/tmp"))
    report = {"command": args.command, "project": str(ROOT),
              "output": str(output), "status": "running"}
    print("检查与日志目录：", output, flush=True)
    try:
        godot = engine_path(args.godot)
        report["godot"] = godot
        version = logged([godot, "--version"], output, "version", args.timeout)
        report["version"] = version
        if not version.startswith("4."):
            raise ValueError(f"本项目需要 Godot 4.x，当前版本：{version}")
        if args.command in ["doctor", "check", "pack", "build-macos"]:
            preflight()
        if args.command == "doctor":
            print("Godot：", version)
            for name in ["PIL", "numpy"]:
                print(f"可选 Python 依赖 {name}：", "可用" if importlib.util.find_spec(name) else "未安装")
            for name in ["ffmpeg", "clang", "iconutil", "codesign", "ditto"]:
                print(f"可选制作/打包工具 {name}：", shutil.which(name) or "未安装")
        elif args.command in ["check", "pack"]:
            logged([godot, "--headless", "--path", str(ROOT), "--editor", "--import",
                    "--quit", "--log-file", str(output / "import-engine.log")],
                   output, "import", args.timeout)
            if args.command == "check":
                startup = [godot, "--headless", "--path", str(ROOT), "--script",
                           "res://tools/checks/harness_smoke.gd", "--quit-after", str(args.frames)]
            else:
                logged([godot, "--headless", "--path", str(ROOT), "--export-pack",
                        "macOS", str(output / "game.pck"), "--log-file",
                        str(output / "pack-engine.log")], output, "pack", args.timeout)
                if not (output / "game.pck").is_file():
                    raise ValueError("引擎未生成 game.pck。")
                # Read resources from the exported pack; keep the bridge outside it.
                startup = [godot, "--headless", "--main-pack", str(output / "game.pck"),
                           "--script", str(ROOT / "tools/checks/harness_smoke.gd"),
                           "--quit-after", "120"]
            logged(startup + ["--log-file", str(output / "startup-engine.log"), "--",
                              "--harness-output=" + str(output)], output, "startup", args.timeout)
            content_file = output / "content.json"
            if not content_file.is_file():
                raise ValueError("主场景未完成初始化，未生成 content.json。")
            report["content"] = json.loads(content_file.read_text())
            if report["content"]["errors"]:
                raise ValueError("\n".join(report["content"]["errors"]))
            print("启动完成，内容概况：", json.dumps(report["content"], ensure_ascii=False))
        elif args.command in ["run", "editor"]:
            command = [godot, "--path", str(ROOT), "--log-file", str(output / "interactive.log")]
            if args.command == "editor":
                command.append("--editor")
            result = subprocess.run(command, cwd=ROOT)
            if result.returncode:
                raise ValueError(f"引擎退出码：{result.returncode}")
        else:
            if sys.platform != "darwin":
                raise ValueError("build-macos 需要在 macOS 上执行。")
            (ROOT / "dist").mkdir(exist_ok=True)
            logged([sys.executable, str(ROOT / "tools/build/build_macos.py"), godot],
                   output, "build-macos", args.timeout)
        report["status"] = "passed"
    except (OSError, ValueError, KeyError, TypeError) as exc:
        report["status"] = "failed"
        report["error"] = str(exc)
        print("失败：", exc, file=sys.stderr)
    finally:
        (output / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
        print("结果报告：", output / "report.json")
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
