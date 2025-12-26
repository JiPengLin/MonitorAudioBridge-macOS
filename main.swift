import Foundation
import AVFoundation
import CoreAudio
import AppKit

class BridgeState {
    var blackHoleID: AudioDeviceID = 0
    var dellID: AudioDeviceID = 0
    var volume: Float = 0.5
    let player = AVAudioPlayerNode()
    let outputEngine = AVAudioEngine()
    let inputEngine = AVAudioEngine()
    var isBridgeActive = false
}

// 获取设备 ID（保持不变）
func getDeviceID(named name: String) -> AudioDeviceID? {
    var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var dataSize: UInt32 = 0
    AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize)
    var deviceIDs = [AudioDeviceID](repeating: 0, count: Int(dataSize) / MemoryLayout<AudioDeviceID>.size)
    AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize, &deviceIDs)
    for id in deviceIDs {
        var nameAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceNameCFString, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var nameResult: Unmanaged<CFString>?
        var nameSize = UInt32(MemoryLayout<CFString?>.size)
        if AudioObjectGetPropertyData(id, &nameAddress, 0, nil, &nameSize, &nameResult) == noErr {
            let deviceName = (nameResult?.takeRetainedValue() as String?) ?? ""
            if deviceName.localizedCaseInsensitiveContains(name) { return id }
        }
    }
    return nil
}

func getCurrentDefaultOutputDevice() -> AudioDeviceID {
    var deviceID = kAudioObjectUnknown
    var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
    var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize, &deviceID)
    return deviceID
}

// 核心：强力初始化逻辑（带重试）
func trySetupBridge(state: BridgeState) {
    state.player.stop()
    state.inputEngine.stop()
    state.outputEngine.stop()
    state.isBridgeActive = false

    // 重新扫描硬件（防止 ID 变动）
    guard let bhID = getDeviceID(named: "BlackHole"),
          let dellID = getDeviceID(named: "U2723QE") else {
        print("等待硬件上线中...")
        return
    }

    state.blackHoleID = bhID
    state.dellID = dellID

    do {
        try state.outputEngine.outputNode.auAudioUnit.setDeviceID(dellID)
        try state.inputEngine.inputNode.auAudioUnit.setDeviceID(bhID)
        
        state.outputEngine.attach(state.player)
        let outFormat = state.outputEngine.outputNode.outputFormat(forBus: 0)
        state.outputEngine.connect(state.player, to: state.outputEngine.mainMixerNode, format: outFormat)
        
        state.inputEngine.inputNode.removeTap(onBus: 0)
        state.inputEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: state.inputEngine.inputNode.inputFormat(forBus: 0)) { (buffer, time) in
            state.player.scheduleBuffer(buffer, completionHandler: nil)
        }
        
        try state.outputEngine.start()
        try state.inputEngine.start()
        state.player.play()
        state.player.volume = state.volume
        state.isBridgeActive = true
        print("✅ 桥接成功恢复！物理输出 ID: \(dellID)")
    } catch {
        print("❌ 尝试重连失败，将在下次轮询重试。")
    }
}

// 监听与定时检查
func startMonitoring(state: BridgeState) {
    // 1. 监听切换事件
    var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    let refcon = UnsafeMutableRawPointer(Unmanaged.passRetained(state).toOpaque())
    
    AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, { _, _, _, clientData in
        guard let clientData = clientData else { return noErr }
        let state = Unmanaged<BridgeState>.fromOpaque(clientData).takeUnretainedValue()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if getCurrentDefaultOutputDevice() == state.blackHoleID {
                trySetupBridge(state: state)
            }
        }
        return noErr
    }, refcon)

    // 2. 增加“心跳检查”：每 5 秒检查一次，如果选了 BlackHole 但桥接没动，就强制重连
    Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
        if getCurrentDefaultOutputDevice() == state.blackHoleID && !state.isBridgeActive {
            print("💓 心跳检查：发现 BlackHole 已选中但桥接未激活，正在尝试强制恢复...")
            trySetupBridge(state: state)
        }
    }
}

// 键盘回调保持不变 (略，请保留你之前版本中的 myEventTapCallback)...

// --- 启动逻辑 ---
let state = BridgeState()
// 必须先查找一次初始化数据
if let bh = getDeviceID(named: "BlackHole") { state.blackHoleID = bh }

startMonitoring(state: state)
// 键盘拦截逻辑 (保留之前的 CGEvent.tapCreate 代码)...

print("Dell Audio Bridge 2.0 (增强重连版) 已启动")
CFRunLoopRun()