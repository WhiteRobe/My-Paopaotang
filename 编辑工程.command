#!/bin/zsh
cd -- "$(dirname -- "$0")"
exec "dist/泡泡糖.app/Contents/MacOS/PaopaoTangEngine" --editor --path "$PWD"
