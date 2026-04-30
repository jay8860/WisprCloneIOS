import Foundation
import CoreAudio

enum AudioInputDeviceManager {
    struct InputDevice: Hashable {
        let id: AudioDeviceID
        let uid: String
        let name: String
    }

    static func listInputDevices() -> [InputDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let system = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &dataSize) == noErr else {
            return []
        }

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = Array(repeating: AudioDeviceID(0), count: count)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &dataSize, &deviceIDs) == noErr else {
            return []
        }

        var devices: [InputDevice] = []
        devices.reserveCapacity(deviceIDs.count)
        for id in deviceIDs {
            guard isInputDevice(id) else { continue }
            guard let uid = getStringProperty(id, selector: kAudioDevicePropertyDeviceUID),
                  let name = getStringProperty(id, selector: kAudioObjectPropertyName) else {
                continue
            }
            devices.append(InputDevice(id: id, uid: uid, name: name))
        }

        return devices.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func currentDefaultInputDevice() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(0)
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        let system = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &dataSize, &deviceID) == noErr else {
            return nil
        }
        return deviceID
    }

    static func setDefaultInputDevice(uid: String) -> AudioDeviceID? {
        guard let target = listInputDevices().first(where: { $0.uid == uid }) else {
            return nil
        }

        let previous = currentDefaultInputDevice()

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = target.id
        let dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        let system = AudioObjectID(kAudioObjectSystemObject)
        let status = AudioObjectSetPropertyData(system, &address, 0, nil, dataSize, &deviceID)
        guard status == noErr else {
            return nil
        }
        return previous
    }

    static func restoreDefaultInputDevice(_ deviceID: AudioDeviceID) {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var id = deviceID
        let dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        let system = AudioObjectID(kAudioObjectSystemObject)
        _ = AudioObjectSetPropertyData(system, &address, 0, nil, dataSize, &id)
    }

    private static func isInputDevice(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize)
        if status != noErr {
            return false
        }
        return dataSize > 0
    }

    private static func getStringProperty(_ objectID: AudioObjectID, selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var cfString: CFString?
        var dataSize = UInt32(MemoryLayout<CFString?>.size)
        let status: OSStatus = withUnsafeMutablePointer(to: &cfString) { ptr in
            ptr.withMemoryRebound(to: UInt8.self, capacity: Int(dataSize)) { rawPtr in
                AudioObjectGetPropertyData(objectID, &address, 0, nil, &dataSize, rawPtr)
            }
        }
        guard status == noErr, let value = cfString else { return nil }
        return value as String
    }
}
