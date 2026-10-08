"""Build a self-contained macOS application from the official Godot binary."""
import argparse, plistlib, shutil, subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('godot', help='Path to Godot.app/Contents/MacOS/Godot')
a = p.parse_args()
godot = Path(a.godot).resolve()
subprocess.run([str(godot), '--headless', '--path', str(ROOT), '--editor', '--import', '--quit'], check=True)
subprocess.run([str(godot), '--headless', '--path', str(ROOT), '--export-pack', 'macOS', str(ROOT/'dist/game.pck')], check=True)
app = ROOT/'dist/泡泡糖.app'
mac = app/'Contents/MacOS'
res = app/'Contents/Resources'
mac.mkdir(parents=True, exist_ok=True)
res.mkdir(parents=True, exist_ok=True)
shutil.copy2(godot, mac/'PaopaoTangEngine')
shutil.copy2(ROOT/'dist/game.pck', res/'game.pck')
subprocess.run(['clang', '-O2', '-arch', 'arm64', '-arch', 'x86_64', str(ROOT/'tools/build/launcher.c'), '-o', str(mac/'PaopaoTang')],check=True)
iconset = ROOT/'dist/icon.iconset'
iconset.mkdir(exist_ok=True)
from PIL import Image
im=Image.open(ROOT/'assets/art/ui/icon.png')
for size in [16,32,128,256,512]:
    for factor,suffix in [(1,''),(2,'@2x')]:
        im.resize((size*factor,size*factor), Image.Resampling.NEAREST).save(iconset/f'icon_{size}x{size}{suffix}.png')
subprocess.run(['iconutil','-c','icns',str(iconset),'-o',str(res/'Game.icns')],check=True)
info = dict(CFBundleExecutable='PaopaoTang', CFBundleName='泡泡糖', CFBundleDisplayName='泡泡糖', CFBundleIdentifier='local.paopaotang.splashduel', CFBundlePackageType='APPL', CFBundleShortVersionString='4.9.0', CFBundleVersion='4.9.0', CFBundleIconFile='Game.icns', CFBundleDevelopmentRegion='zh_CN', LSMinimumSystemVersion='10.13', LSApplicationCategoryType='public.app-category.games', NSHighResolutionCapable=True, NSSupportsAutomaticGraphicsSwitching=True)
with (app/'Contents/Info.plist').open('wb') as f: plistlib.dump(info,f)
shutil.copytree(ROOT/'licenses',res/'licenses',dirs_exist_ok=True)
subprocess.run(['codesign','--force','--deep','--sign','-',str(app)],check=True)
subprocess.run(['ditto','-c','-k','--keepParent',str(app),str(ROOT/'dist/泡泡糖-macOS.zip')],check=True)
print(f'Built {app}')
