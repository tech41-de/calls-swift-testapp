//
//  AudioDevices.swift
//  calls-swift-testApp
//
//  Created by mat on 8/22/24.
//

import Foundation
import AVFoundation
import AudioToolbox

#if os(macOS)
class AudioDevices{
    var audioDeviceID:AudioDeviceID

    init(deviceID:AudioDeviceID) {
        self.audioDeviceID = deviceID
    }
    
    func setup(){
        
    }

    var hasInput: Bool {
        get {
            var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
                mSelector:AudioObjectPropertySelector(kAudioDevicePropertyStreamConfiguration),
                mScope:AudioObjectPropertyScope(kAudioDevicePropertyScopeInput),
                mElement:0)

            var propsize:UInt32 = UInt32(MemoryLayout<CFString?>.size);
            var result:OSStatus = AudioObjectGetPropertyDataSize(self.audioDeviceID, &address, 0, nil, &propsize);
            if (result != 0) {
                return false;
            }

            let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity:Int(propsize))
            result = AudioObjectGetPropertyData(self.audioDeviceID, &address, 0, nil, &propsize, bufferList);
            if (result != 0) {
                return false
            }

            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            for bufferNum in 0..<buffers.count {
                if buffers[bufferNum].mNumberChannels > 0 {
                    return true
                }
            }

            return false
        }
    }

    
    var hasOutput: Bool {
        get {
            var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
                mSelector:AudioObjectPropertySelector(kAudioDevicePropertyStreamConfiguration),
                mScope:AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
                mElement:0)

            var propsize:UInt32 = UInt32(MemoryLayout<CFString?>.size);
            var result:OSStatus = AudioObjectGetPropertyDataSize(self.audioDeviceID, &address, 0, nil, &propsize);
            if (result != 0) {
                return false;
            }

            let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity:Int(propsize))
            result = AudioObjectGetPropertyData(self.audioDeviceID, &address, 0, nil, &propsize, bufferList);
            if (result != 0) {
                return false
            }

            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            for bufferNum in 0..<buffers.count {
                if buffers[bufferNum].mNumberChannels > 0 {
                    return true
                }
            }

            return false
        }
    }

    var uid:String? {
        get {
            var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
                mSelector:AudioObjectPropertySelector(kAudioDevicePropertyDeviceUID),
                mScope:AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
                mElement:AudioObjectPropertyElement(kAudioObjectPropertyElementMain))

            var name:CFString? = nil
            var propsize:UInt32 = UInt32(MemoryLayout<CFString?>.size)
            let result:OSStatus = AudioObjectGetPropertyData(self.audioDeviceID, &address, 0, nil, &propsize, &name)
            if (result != 0) {
                return nil
            }
            return name as String?
        }
    }

    var name:String? {
        get {
            var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
                mSelector:AudioObjectPropertySelector(kAudioDevicePropertyDeviceNameCFString),
                mScope:AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
                mElement:AudioObjectPropertyElement(kAudioObjectPropertyElementMain))

            var name:CFString? = nil
            var propsize:UInt32 = UInt32(MemoryLayout<CFString?>.size)
            let result:OSStatus = AudioObjectGetPropertyData(self.audioDeviceID, &address, 0, nil, &propsize, &name)
            if (result != 0) {
                return nil
            }

            return name as String?
        }
    }
}

class AudioDeviceFinder {
    
    static func findDevices() {
        var propsize:UInt32 = 0

        var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
            mSelector:AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
            mScope:AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement:AudioObjectPropertyElement(kAudioObjectPropertyElementMain))

        var result:OSStatus = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, UInt32(MemoryLayout<AudioObjectPropertyAddress>.size), nil, &propsize)

        if (result != 0) {
            print("Error \(result) from AudioObjectGetPropertyDataSize")
            return
        }

        let numDevices = Int(propsize / UInt32(MemoryLayout<AudioDeviceID>.size))

        var devids = [AudioDeviceID]()
        for _ in 0..<numDevices {
            devids.append(AudioDeviceID())
        }

        result = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propsize, &devids);
        if (result != 0) {
            print("Error \(result) from AudioObjectGetPropertyData")
            return
        }

        let m = Model.shared
        m.audioInDevices.removeAll()
        m.audioOutDevices.removeAll()
        for i in 0..<numDevices {
            let audioDevice = AudioDevices(deviceID:devids[i])
            if (audioDevice.hasInput) {
                m.audioInDevices.append(ADevice(id:audioDevice.uid ?? "", name:audioDevice.name ?? "", uid:audioDevice.audioDeviceID))
                print("Audio in \(String(describing: audioDevice.name)) \(String(describing: audioDevice.uid))")
            }
            if (audioDevice.hasOutput) {
                m.audioOutDevices.append(ADevice(id:audioDevice.uid ?? "", name:audioDevice.name ?? "", uid:audioDevice.audioDeviceID))
                print("Audio out \(String(describing: audioDevice.name)) \(String(describing: audioDevice.uid))")
           }
        }
        // set defaullts if we have any
        if  (UserDefaults.standard.string(forKey: "audioIn") != nil){
            m.audioInDevice = UserDefaults.standard.string(forKey: "audioIn")!
           
        }else{
            if m.audioInDevices.count > 0{
                m.audioInDevice = m.audioInDevices[m.audioInDevices.count - 1].name
            }else{
                print("There are no Audio In devices")
            }
        }
        
        if  (UserDefaults.standard.string(forKey: "audioOut") != nil){
            m.audioOutDevice = UserDefaults.standard.string(forKey: "audioOut")!
        }else{
            if m.audioOutDevices.count > 0{
                m.audioOutDevice = m.audioOutDevices[m.audioOutDevices.count - 1].name
            }else{
                print("There are no Audio Out devices")
            }
        }
    }
}

class AudioDeviceManager{
    
    func setup(){
        
    }

    func setupAudio(){
        requestMicrophonePermission(){ hasPermission in
            if hasPermission{
                AudioDeviceFinder.findDevices()
                Model.shared.audioInputDefaultDevice = self.getDefaultInDevice(forScope: kAudioObjectPropertyScopeOutput)
                Model.shared.audioOutputDefaultDevice = self.getDefaultOutDevice(forScope: kAudioObjectPropertyScopeInput)
                
                let input = Model.shared.getAudioInDevice(name: Model.shared.audioInDevice)
                self.setInputDevice(uid:input!.uid)
                
                let output = Model.shared.getAudioOutDevice(name: Model.shared.audioOutDevice)
                self.setOutputDevice(uid:output!.uid)
            }
        }
    }
    
    func setDefaultDeviceOutput(_ deviceID: AudioDeviceID, forScope scope: AudioObjectPropertyScope) {
        var deviceID = deviceID
        let propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            propertySize,
            &deviceID
        )
        if status != noErr {
            print("Error setting default device: \(status)")
        }
    }
    
    func setDefaultDeviceInput(_ deviceID: AudioDeviceID, forScope scope: AudioObjectPropertyScope) {
        var deviceID = deviceID
        let propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            propertySize,
            &deviceID
        )
        if status != noErr {
            print("Error setting default device: \(status)")
        }
    }
    
    func setInputDevice(uid:AudioDeviceID){
        setDefaultDeviceInput(uid, forScope: kAudioObjectPropertyScopeInput)
    }
    
    func setOutputDevice(uid:AudioDeviceID){
        setDefaultDeviceOutput(uid, forScope: kAudioObjectPropertyScopeOutput)
    }
    
    func getDefaultInDevice(forScope scope: AudioObjectPropertyScope) -> AudioDeviceID {
        var defaultDeviceID = kAudioObjectUnknown
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize,
            &defaultDeviceID
        )
        if status != noErr {
            print("Error getting default device ID: \(status)")
        }
        return defaultDeviceID
    }
    
    func getDefaultOutDevice(forScope scope: AudioObjectPropertyScope) -> AudioDeviceID {
        var defaultDeviceID = kAudioObjectUnknown
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain //kAudioObjectPropertyElementMaster
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize,
            &defaultDeviceID
        )
        
        if status != noErr {
            print("Error getting default device ID: \(status)")
        }
        return defaultDeviceID
    }
    
    func setInput(name:String){
        let device = Model.shared.getAudioInDevice(name:name)
        let engine = AVAudioEngine()
        var inputDeviceID: AudioDeviceID = device!.uid
        let sizeOfAudioDevId = UInt32(MemoryLayout<AudioDeviceID>.size)
        let error = AudioUnitSetProperty(engine.inputNode.audioUnit!, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &inputDeviceID, sizeOfAudioDevId)
        if error > 0{
            print(error)
            return
        }

        let inputNode = engine.inputNode
        engine.connect(inputNode, to: engine.mainMixerNode, format: nil)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: nil)
        engine.prepare()
        do
        {
            try engine.start()
        }
        catch{
            print("Failed to start the audio input engine: \(error)")
        }
    }
    
    struct SystemSettingsHandler {
        static func openSystemSetting(for type: String) {
            guard type == "microphone" || type == "screen" else {
                return
            }
            
            let microphoneURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
            let screenURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
            let urlString = type == "microphone" ? microphoneURL : screenURL
            if let url = URL(string: urlString) {
                //NSWorkspace.shared.open(url)
            }
        }
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            print("authorized")
            completion(true)
            
        case .notDetermined:
            print("notDetermined")
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    completion(granted)
                } else {
                    completion(granted)
                }
            }
            
        case .denied, .restricted:
            print("denied")
            SystemSettingsHandler.openSystemSetting(for: "microphone")
            completion(false)
            
        @unknown default:
            print("unknown")
            completion(false)
        }
    }
}
#else
// ios version
class AudioDeviceManager{
    
    let session = AVAudioSession.sharedInstance()

    func setInputDevice(name:String){
        let availableInputs = self.session.currentRoute.inputs
        for device in availableInputs{
            if device.portName == name{
                do{
                    try self.session.setPreferredInput(device)
                }
                catch{
                    print(error)
                }
            }
        }
    }

    func setOutputDevice(name:String){
        let availableOutputs = self.session.currentRoute.outputs
        for device in availableOutputs{
            if device.portName == name{
                do{
                   // TODO
                }
                catch{
                    print(error)
                }
            }
        }
    }
    
    func setSpeacker(on:Bool){
        do{
            if on{
                try self.session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            }else{
                try self.session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            }
        }
        catch{
            print(error)
        }
    }
    
    func setup(){
        session.requestRecordPermission(){ ok in
            print("Audio Permission given \(ok)")
            if !ok{
                return
            }
            do{
                try self.session.setCategory(.playAndRecord, mode:.videoChat , policy:.default , options: [.mixWithOthers, .allowBluetooth])
                try self.session.setActive(true, options: .notifyOthersOnDeactivation)
                try self.session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
                // Inputs
                let availableInputs = self.session.currentRoute.inputs
                
                DispatchQueue.main.async {
                    Model.shared.audioInDevices.removeAll()
                    for device in availableInputs{
                        print(device.portName)
                        Model.shared.audioInDevices.append(ADevice(uid:device.uid, name: device.portName))
                    }
                    Model.shared.audioInDevice = Model.shared.audioInDevices[0].name
                    
                    // Inputs
                    let availableOutputs = self.session.currentRoute.outputs
                    Model.shared.audioOutDevices.removeAll()
                    for device in availableOutputs{
                        print(device.portName)
                        Model.shared.audioOutDevices.append(ADevice(uid:device.uid, name: device.portName))
                    }
                    Model.shared.audioOutDevice = Model.shared.audioOutDevices[0].name
                }
            }catch{
                print(error)
            }
        }
    }
}

#endif
