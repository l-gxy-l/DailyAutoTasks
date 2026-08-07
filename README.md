本回答由 AI 生成，内容仅供参考，请仔细甄别
# DailyAutoTasks - 每日游戏日常自动化工具集

基于 Windows 批处理的任务调度脚本，可一键自动完成多款游戏的每日任务。支持原神、明日方舟、崩坏：星穹铁道、战双帕弥什、明日方舟：终末地等游戏，集成静音、亮度调节、模拟器控制、MAA 与 BetterGI 等自动化工具。

## ✨ 特性

- 🕹️ **多游戏支持**：覆盖 5 款主流手游的日常任务
- 🔇 **无弹窗静音**：利用 Core Audio API 直接控制系统静音/恢复，不弹出 OSD
- 💡 **亮度控制**：通过 WMI 调节显示器亮度，任务前后自动恢复
- 📅 **每日运行判断**：基于日期记录防止同一天重复执行
- 🔁 **智能循环调度**：内置 ABAC 分支逻辑，自动决定当日应执行的预设循环
- 📝 **详细日志**：运行日志、调试日志、音频日志分别记录，方便排查问题
- 🖥️ **模拟器后台运行**：PowerShell 最小化模拟器窗口，实现无干扰自动化
- 🔒 **管理员权限检测**：自动请求管理员权限，确保 WMI 等系统操作可用
- ⚙️ **路径可配置**：通过 `config/paths.ini` 统一管理外部工具路径

## 📂 目录结构

```text
自启动任务/
├── 自动完成日常.bat              # 主入口，调用所有游戏任务
├── tools/
│   ├── audioMute.exe             # 系统静音/恢复工具（无窗口）
│   └── GIcloud.url               # 米游社/云游戏签到快捷方式
├── config/
│   ├── BGIjudge.txt              # 原神循环状态记录（6 行）
│   ├── MFWjudge.txt              # 战双运行日期记录
│   └── paths.ini                 # 各工具路径配置文件
├── logs/
│   ├── BGI调试日志.txt
│   ├── BGI循环日志.txt
│   └── 音频日志.txt
├── tasks/
│   ├── BGI/
│   │   └── BGIAutoRun.bat        # 原神循环计算及启动 BetterGI
│   ├── EnF/
│   │   ├── startMaaEnd.bat       # 启动 MAA 执行明日方舟：终末地任务
│   │   └── endArkE.bat           # 终止明日方舟：终末地游戏进程
│   ├── HSR/
│   │   └── endHSR.bat            # 终止星穹铁道相关进程
│   └── MFW/
│       └── startMFW-FOS.bat      # 战双模拟器启动及 FOS 脚本调用
└── 测试/                         # 功能测试脚本（开发用）
···
```
## 🚀 快速开始

### 1. 环境准备
- Windows 10/11 操作系统
- 已安装所需游戏及对应自动化工具：
  - **原神**：[BetterGI](https://github.com/babalae/better-genshin-impact)
  - **明日方舟** / **明日方舟：终末地**：MuMu 模拟器 + [MAA](https://maa.plus/)
  - **崩坏：星穹铁道**：[March7th](https://github.com/CHNZYX/HSR_March7th)
  - **战双帕弥什**：MuMu 模拟器 + MFW（FOS） 
- 模拟器（MuMu 等）已开启 ADB 调试
- 下载release （**请更改/config/paths.ini内的自动化软件路径**）

### 2. 配置文件
- 编辑 `config/paths.ini`，按实际安装位置修改各工具的路径，例如：
```ini
path_mumu=D:\Program Files\MuMu\emulator\shell\MuMuPlayer.exe
path_maa=D:\MAA\MeoAssistant.exe
path_maaend=D:\MAA\MeoAssistant.exe
path_march7th=D:\HSR_March7th\March7th Launcher.exe
path_bgi=D:\BetterGI\BetterGI.exe
path_fos=D:\FOS\FOS.exe
```
- 打开自动化软件，修改默认执行的配置
  - **BetterGI：** 需要在一条龙界面设置4种不同的预设，默认预设名称与执行顺序（ABAC刷本法）是```→循环A-循环囤体力-循环B-循环囤体力-循环A-循环囤体力-循环C-循环囤体力→```  
    ***如果需要使用其他预设，请更改```.\tasks\BGI\BGIAutoRun.bat```中最后一个代码段的内容：***
  ```
  ...
  REM 根据T5的值决定启动哪一个BGI预设
  if "!T5!" == "囤" (
  echo !date!,!time!运行了配置---囤体力 >> ".\logs\BGI循环日志.txt"
  "!PATH_BGI!" --startOneDragon 循环囤体力
  ) else if "!T5!" == "A" (
  echo !date!,!time!运行了配置---循环A >> ".\logs\BGI循环日志.txt"
  "!PATH_BGI!" --startOneDragon 循环A
  ) else if "!T5!" == "B" (
  echo !date!,!time!运行了配置---循环B >> ".\logs\BGI循环日志.txt"
  "!PATH_BGI!" --startOneDragon 循环B
  ) else if "!T5!" == "C" (
  echo !date!,!time!运行了配置---循环C >> ".\logs\BGI循环日志.txt"
  "!PATH_BGI!" --startOneDragon 循环C
  ) else (echo [ERROR]!date!,!time!:主程序执行出错，缺少可用数值的L1>> ".\logs\BGI循环日志.txt"
	set "T6=上一次主程序执行出错，算作今日未运行，最好重开这个bat文件"
  )
  ```

### 3. 运行
右键 `自动完成日常.bat` → **以管理员身份运行**。  
脚本将依次执行：
```
1. 静音并降低屏幕亮度
2. 打开网页领取云时长
3. 启动 MuMu 模拟器并执行 MAA（明日方舟）
4. 运行 BetterGI 原神循环任务
5. 启动 March7th 执行崩坏：星穹铁道任务
6. 启动明日方舟：终末地的 MAA 任务
7. 启动模拟器战双及 FOS 脚本
8. 恢复亮度和声音
```

若需无人值守，可配合 **Windows 任务计划程序** 设置定时唤醒电脑并运行。

## 🔧 工具说明

### cpp编译软件`audioMute.exe`
系统静音/恢复小工具，通过 Core Audio API 直接控制音频设备，**无弹窗提示**。

**用法：**
```batch
audioMute.exe mute      # 静音
audioMute.exe unmute    # 恢复声音
```
**返回值：**
- `0` - 静音成功
- `1` - 恢复声音成功
- `2` - 静音失败
- `3` - 恢复声音失败
- `4` - 参数无效
- `5` - 参数不足

### 配置文件`config/BGIjudge.txt`
保存原神循环调度状态，每行意义：
```
1. 当前模式：0=囤体力，1=刷副本
2. 副本循环：1-A，2-B，3-C
3. ABAC 分支：1是A→B 或 2是A→C
4. 错误信息（无错误时显示“无错误”）
5. 上一次执行的预设名（囤/A/B/C）
6. 上次运行日期（星期几）或错误信息
```

### 配置文件`config/MFWjudge.txt`
战双运行日期记录，防止同一天重复运行。

## 📜 任务流程详解

- **明日方舟**：通过 MAA 启动，需要在maa中设置“打开maa时自动运行”。
- **原神**：根据 `BGIjudge.txt` 的循环信息启动 BetterGI 对应预设（一条龙预设 A/B/C/囤体力 ），自动计算下一日应执行的循环。
- **崩坏：星穹铁道**：调用 March7th 执行日常任务，完成后自动结束游戏和软件进程（需要在March7th中设置结束任务后运行脚本）。
- **明日方舟：终末地**：通过 MaaEnd 的 `--autostart` 参数一键启动。
- **战双帕弥什**：连接 MuMu 模拟器，启动 FOS 自动化脚本，执行完毕后退出 adb 进程。

## ⚠️ 注意事项

1. **路径依赖**：自动化软件使用绝对路径，需要在.\config\paths.ini中自行设置；多数脚本使用相对路径，运行主脚本时自动切换到根目录。
2. **管理员权限**：亮度调节（WMI）和部分进程管理需要管理员权限，主脚本会自动检测并提示。
3. **模拟器 ADB**：MAA系列任务依赖 ADB 连接，请确保模拟器已开启 USB 调试，且在自动化软件内已经正确设置端口。
4. **硬件兼容性**：亮度调节仅对笔记本内置显示器有效，部分外接显示器可能不支持。
5. **日志文件**：日志会持续追加，可以定期清理 `logs` 文件夹以释放空间。

## 🛠️ 开发 & 编译

`tools/audioMute.exe` 源码为 `audioMute.cpp`，使用 Visual Studio 或 MinGW 编译：
```bash
# MSVC
cl audioMute.cpp /link /SUBSYSTEM:WINDOWS ole32.lib shell32.lib

# MinGW
g++ audioMute.cpp -o audioMute.exe -lole32 -loleaut32 -static -mwindows
```
如需更改执行流程，以```自动完成日常.bat```为主。该文件记录了所有自动化软件的执行顺序，执行时会调用```.\tasks\<游戏名简写>\```文件夹下的其他辅助bat文件。

## 📄 开源协议

本项目仅供个人学习与自动化使用，请遵守相关游戏的使用条款。代码采用 [MIT License](LICENSE) 发布。

---

*最后更新：2026年8月*
