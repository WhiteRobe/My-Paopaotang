# HD 素材制作记录

本轮使用内置 imagegen 生成全新的像素素材。输出原图复制到 `assets/hd/`，没有对原图缩放、锐化或重新绘制。`source-files.json` 记录原始生成文件与工程文件对应关系；`regions.json` 只记录裁切区域，`tools/index_hd_atlases.py` 依据透明轮廓建立索引。运行与打包后的游戏无需联网。

图集包括十四张地图主题图集、十四张背景、四张人物方向造型、八张行走图集，以及道具、怪物、任务、泡泡、坐骑、元素冲击、环境访客、正面人物动作和遥控器。应用图标原图另存 `assets/icon-v2.png`。

## 生成任务与提示词约束

地图图集使用每主题四列四行的制作任务。共同约束为精细 JRPG 像素画、深海军蓝轮廓、明确材质、清晰小像素簇、三分之四俯视、透明背景、完整孤立物件、无文字与水印。单元从左到右排列如下：

| 行 | 四个单元 |
| --- | --- |
| 第一行 | 地表 A、地表 B、不可破坏墙、普通箱 |
| 第二行 | 带轮推动箱、金属装甲箱、完整宝库、受损宝库 |
| 第三行 | 岩石、花卉或晶体、水面装饰、灯具 |
| 第四行 | 桶、主题植物、旗帜、雕像 |

各主题加入独立材质、建筑与颜色词；对应背景采用横向完整场景，保持一致视觉语言。

| 主题 | 制作任务中的主题词 |
| --- | --- |
| 海港 | 航海木码头、黄铜、锚、灯塔、海水 |
| 森林 | 苔藓、蕨类、树屋、木纹 |
| 冰雪 | 高山冰晶、雪、极光 |
| 沙漠 | 砂岩、绿洲、绿松石镶嵌 |
| 火山 | 黑曜石、熔岩、矿石 |
| 工厂 | 深蓝钢材、铜、齿轮、蒸汽 |
| 糖果 | 糖霜、薄荷糖、巧克力 |
| 星空 | 靛蓝、紫晶、天文装置 |
| 沼泽 | 萤火、青绿湿地、蘑菇 |
| 遗迹 | 符文石、棱镜、古老建筑 |
| 珊瑚 | 海玻璃、珍珠、珊瑚 |
| 云港 | 热气球码头、黄铜、红色旗帜 |
| 墨城 | 紫色石板、粉色窗光、墨潮城堡 |
| 洞窟 | 蓝灰岩石、晶体、蘑菇、火把、蝙蝠 |

人物四方向任务引用先前人物原图，要求保持角色身份、衣物和配饰，八角色分别制作正面、背面、左面、右面。行走任务分别引用人物造型，要求同一角色四方向、每方向十二阶段接触、抬脚、经过与反向摆臂，脚底对齐、真实透明背景，不使用重复站立姿势。

生成结果中部分行走图集实际提供十三或十四帧，索引按真实列数读取，全部保留。因此共有四百零八帧，而非按预计十二帧计算。道具采用七列四行，怪物四列三行，任务和泡泡四列两行，坐骑三列四方向，冲击六列四阶段，环境访客四列三行。物件任务均要求清晰独立轮廓、暖色金属、发光玻璃、材质层次，以及与人物相同的精细像素表现。

道具图集的物理槽位与游戏 ID 不同，由索引脚本明确重排。遥控器另行制作，替代原图中容易被认作时钟的图标。

## 正面动作的生成提示词

```text
Create a new transparent pixel art ACTION SPRITE ATLAS, exact 8 columns by 8 rows, no gutters labels or text. Match the eight finely detailed characters of the reference image, the columns keep that exact identity order: sailor boy in navy captain cap, white bunny girl, green frog raincoat boy, red fox adventurer, brown bear worker, purple witch girl, silver teal robot, red flame hood girl. Full body FRONT view each cell same size, feet aligned, crisp exquisite dense pixel clusters and deep navy outlines, consistent proportions with the reference. Rows 1 to 4 are four successive distinct water bubble placement action poses: anticipation, crouch with hands reaching forward, release cupping a round aqua bubble, recover standing. Rows 5 to 8 are four successive distinct being hit reaction poses: surprised bracing, recoil with arms raised, recovering bent forward, return standing. Hands legs and facial expressions must actually change each frame, seamless readable animation. NO bubble obstructing the character body, no weapons, no duplicate standstill cells, no contact sheet borders, no shadows connecting cells. True transparent alpha background. The atlas is actual usable polished game sprite artwork, all 64 sprites isolated, no mockup.
```

该任务实际输出七行：四帧放置、三帧受击，共五十六帧。运行时按实际布局使用，受击最后阶段停留在恢复姿态，不把缺失行当成已生成素材。

## 遥控器的生成提示词

```text
A single exquisite high-definition pixel-art inventory icon for a cute nautical water bubble adventure game, true transparent alpha background. Small handheld water-bubble remote controller: navy-blue leather and polished brass housing, short brass antenna with round blue luminous tip, one large glowing aqua bubble-shaped activation button and one small coral switch, visible tiny screws and worn leather stitching. Charming compact chibi object, three-quarter view, strong clear silhouette, crisp dense tiny pixel clusters, deep navy outlines and warm brass highlights matching premium JRPG pixel sprites. Complete isolated object centered in square, no cast shadow, no words, no letters, no frame, no border, no backdrop. This must read as a remote-control gadget with antenna, not a stopwatch or clock.
```

## 应用图标的生成提示词

```text
Use case: stylized-concept. Create a brand new polished application icon for an original local multiplayer pixel-art water-bubble adventure game called Bubble Isles. Square 1024 x 1024 composition. Rich, exquisite high-definition pixel art with deliberate tiny crisp pixel clusters, limited but luminous cyan aqua teal ultramarine palette with pearl white and warm coral accent. Central very large perfectly round translucent aqua water bubble, beautifully shaded with dimensional refractions, small white glints, a tiny coral star suspended inside, an energetic curled ring of water splash and individually sparkling water droplets surrounding it. Bubble occupies 65 percent of canvas, simple memorable silhouette readable at 32px. Deep navy rounded square app-icon backplate with softly glowing turquoise corners and ornamental pixel wave motifs, tasteful depth. No lettering, no characters, no mockup, no outer frame, no watermark. Fill the square canvas as the actual icon artwork. Professional game launcher icon, highly detailed pixel illustration, water bubble must clearly be spherical rather than bomb.
```

打包时按 macOS 的要求生成图标尺寸，这是新图标的系统适配，不用于冒充高分辨率重绘。

## 正交地图修订

最初的四列四行主题图集在实机中纹理过密，墙与箱体带斜角视图。因此另行生成十四张 `playfield-*-hd.png`，四列两行，按地面 A、地面 B、墙、普通箱、推动箱、装甲箱、完整宝库、受损宝库排列。运行时格子和箱体使用这些正交素材，旧主题图集仅提供少量边界装饰。通道不再布置装饰图标，环境粒子数量降低，背景降低亮度。

完整十四次提示词保存于 [正交地图提示词](playfield-prompts.json)。共同约束是水平与垂直边缘对齐、禁止等距视图和四十五度视角、地面采用安静低对比色块、墙与各类箱体保持颜色差异。该修订保留像素材质，减少噪点、铆钉、花纹和过量发光饰物。


v4.5 新增 `hero-trapped-v5.png`（8×4）、`hero-death-v5.png`（8×3）、`bubble-break-v5.png`（6×2）及 `mechanisms-v5.png`（4×4）。由内置 imagegen 生成；倒地图集再次生成更宽透明间隔版本。原图路径记录于 `source-files.json`，初次生成提示词见 `v5-prompts.json`。所有 PNG 原样复制，索引只分析裁切区域。倒地三行使用实际透明间隔，避免均分高度截断人物。


### v4.6.3 箱墙体积与动画裁切

`blocks-depth-v463.png` 为内置 imagegen 原始输出，使用第 2～7 格替换墙块与箱体；墙体绘制乘以十四主题对应的色调。地面保持原主题图集。完整提示词记录在 [blocks-depth-v463-prompt.txt](blocks-depth-v463-prompt.txt)，原始路径见 source-files.json。

行走区域恢复每帧的实际尺寸，不把较矮帧向上扩展成全局高度；统一缩放比例放在 game.gd 的绘制阶段，避免采到上一行的脚和衣物。人物原图未修改。


### v4.7.0 高压核心

`pressure-core-v464.png` 为内置 imagegen 原始输出，整张用于 PVE 新道具；文件名保留制作时编号。提示词见 [pressure-core-v464-prompt.txt](pressure-core-v464-prompt.txt)，原始文件路径见 `source-files.json`。未修改生成原图像素。

本次统一遮挡由游戏绘制顺序实现，原门、人物、怪物、坐骑贴图保持不变。火把图标改为底部居中落地，避免偏向格子右侧。


### v4.7.1 全局图集裁切

只重建区域索引，不编辑或重采样原始 PNG。按每列透明间隔找到帧边界；对处于主体矩形内的少量邻帧残片记录排除矩形，在绘制阶段拆分源区域。角色主题色着色器同步排除这些像素，保持原有完整人物设计。


### v4.7.2 机关重绘

新增原创透明 4×4 图集 `mechanisms-v472.png`，涵盖地刺、闸门、传送盘、输送带、炮台、激光发射器、反射板等。原始生成 PNG 直接复制，像素未作二次修改；索引通过透明边界定位，替换旧机关图集和早期线框门。提示词保存在 `mechanisms-v472-prompt.txt`，原文件位置见 `source-files.json`。
