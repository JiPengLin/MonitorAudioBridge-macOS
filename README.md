---

# U2723QE-Volume-Fix

[English](#-english) | [中文](#-中文)

---

## 🇺🇸 English

### The Problem
On macOS, when using a **Dell U2723QE** monitor via USB-C/DisplayPort, the system locks the volume control (greyed out). This is because the monitor's internal DAC (MediaTek MT9800) does not map its 3.5mm AUX gain to the DDC/CI protocol, making standard tools like *MonitorControl* ineffective for the headphone jack.

### The Solution
A lightweight Swift-based background daemon that:
1. Creates a digital bridge using **BlackHole 2ch**.
2. Intercepts keyboard media keys (Volume +/-/Mute).
3. Pumps audio buffers from the virtual card to the monitor hardware with manual gain applied.
4. **Smart Pass-through**: Automatically stops intercepting keys when you switch to other devices (like the Dell SB521A Soundbar or internal speakers).

### Features
- **Native Performance**: Written in Swift for Apple Silicon (ARM64).
- **Zero-Latency**: Manual buffer pumping for perfect sync.
- **Smart Switching**: No need to quit the app when changing output devices.
- **Minimalist**: No GUI, low CPU footprint.

### Prerequisites
- [BlackHole 2ch](https://github.com/ExistentialAudio/BlackHole) (`brew install --cask blackhole-2ch`)
- macOS 12.0+

### Setup Guide
1. **Configure**: Open `main.swift` and ensure the device name matches yours:
   ```swift
   guard let bhID = getDeviceID(named: "BlackHole"), 
         let dellID = getDeviceID(named: "U2723QE") 
   else { exit(1) }
   ```
2. **Compile**:
   ```bash
   swiftc main.swift -o DellAudioBridge
   ```
3. **Permissions**: Run `./DellAudioBridge` and grant **Accessibility** (for keys) and **Microphone** (for audio stream) permissions in System Settings.
4. **Daemonize**: Use Automator to create a "Run Shell Script" application and add it to your **Login Items**.

---

## 🇨🇳 中文

### 痛点描述
在 macOS 下通过 USB-C/DisplayPort 连接 **Dell U2723QE** 显示器时，系统音量调节会被锁死。这是由于显示器内置的联发科 MT9800 主控未将其 3.5mm 耳机孔的增益控制映射到 DDC/CI 协议，导致常规软件无法调节耳机孔音量。

### 解决方案
一个基于 Swift 编写的轻量级后台守护程序：
1. 通过 **BlackHole 2ch** 虚拟声卡建立音频桥梁。
2. 拦截键盘媒体键（音量加/减/静音）。
3. 手动搬运音频缓冲区至显示器硬件，并在此过程中实施数字增益。
4. **智能直通**：当你切回原生支持调音的设备（如 Dell SB521A 音棒或内置扬声器）时，程序自动放行按键事件，不干扰系统逻辑。

### 核心特性
- **原生性能**：专为 Apple Silicon (ARM64) 优化，极低 CPU 占用。
- **无感延迟**：采用手动缓冲区调度，确保音画同步。
- **智能切换**：切换输出设备时无需重启程序，即切即用。
- **极简设计**：无 UI 界面，完全后台化运行。

### 准备工作
- [BlackHole 2ch](https://github.com/ExistentialAudio/BlackHole) (`brew install --cask blackhole-2ch`)
- macOS 12.0 或更高版本

### 安装步骤
1. **配置名称**: 打开 `main.swift`，确认硬件搜索名称：
   ```swift
   guard let bhID = getDeviceID(named: "BlackHole"), 
         let dellID = getDeviceID(named: "U2723QE") 
   else { exit(1) }
   ```
2. **编译**:
   ```bash
   swiftc main.swift -o DellAudioBridge
   ```
3. **授权**: 运行 `./DellAudioBridge`，并在系统设置中授予 **辅助功能**（拦截按键）和 **麦克风**（读取音频流）权限。
4. **后台运行**: 使用 **自动操作 (Automator)** 封装为 App，并添加至 **登录项** 实现开机自启。

---

## 📜 License
MIT License.

---

### 项目建议
*   **仓库简介**: `macOS Volume Fix for Dell U2723QE AUX output. Background daemon with smart device switching.`
*   **标签 (Tags)**: `macOS`, `Dell`, `U2723QE`, `Volume-Control`, `CoreAudio`, `Swift`.
