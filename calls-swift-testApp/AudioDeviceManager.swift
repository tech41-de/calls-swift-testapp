//
//  AudioDevices.swift
//  calls-swift-testApp
//
//  Created by mat on 8/22/24.
//

import Foundation
import AVFoundation
import AudioToolbox
import CoreAudio


#if os(iOS) && !targetEnvironment(macCatalyst)
class AudioDeviceManager{
    
    let model:Model
    
    init(model:Model){
        self.model = model
    }
    
    func setup(){
        let session = AVAudioSession.sharedInstance()
        session.requestRecordPermission(){ ok in
            if !ok{
                return
            }
            do{
                try session.setCategory(.playAndRecord, mode:.videoChat , policy:.default , options: [.mixWithOthers, .allowBluetooth])
                try session.setActive(true, options: .notifyOthersOnDeactivation)
                try session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            }catch{
                print(error)
            }
        }
        
        guard let availableInputs = AVAudioSession.sharedInstance().availableInputs else {
           print("No inputs available ")
           return
       }
        
        DispatchQueue.main.async {
            self.model.audioInDevices.removeAll()
            for input in availableInputs{
                var device = ADevice()
                device.id = 0
                device.name = input.portName
                device.uid = input.uid
                self.model.audioInDevices.append(device)
            }
        }
        
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        DispatchQueue.main.async {
            self.model.audioOutDevices.removeAll()
            for out in outputs{
                var device = ADevice()
                device.id = 0
                device.name = out.portName
                device.uid = out.uid
                self.model.audioOutDevices.append(device)
            }
        }
        self.model.audioInDevice = AVAudioSession.sharedInstance().availableInputs?[0].portName ?? ""
        self.model.audioOutDevice = AVAudioSession.sharedInstance().currentRoute.outputs[0].portName
    }
    
    func setInputDevice(device: ADevice){
        do {
            guard let availableInputs = AVAudioSession.sharedInstance().availableInputs else {
               print("No inputs available ")
               return
           }
            for d in availableInputs{
                if d.portName == device.name{
                    try AVAudioSession.sharedInstance().setPreferredInput(d)
                }
            }
           
            } catch {
                print("Unable to set the built-in mic as the preferred input.")
        }
    }
    
    func setOutputDevice(device: ADevice){
        print("output device \(device.name)")
    }
}

#endif


#if  os(macOS) || targetEnvironment(macCatalyst)
class AudioDeviceManager{
    
    let model:Model
    
    init(model:Model){
        self.model = model
    }
    
    func setup(){
        
        #if targetEnvironment(macCatalyst)
        let session = AVAudioSession.sharedInstance()
        session.requestRecordPermission(){ ok in
            if !ok{
                return
            }
            do{
                try session.setCategory(.playAndRecord, mode:.videoChat , policy:.default , options: [.mixWithOthers, .allowBluetooth])
                try session.setActive(true, options: .notifyOthersOnDeactivation)
                try session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            }catch{
                print(error)
            }
        }
        #endif
        
        setupAudio()
    }

    func setupAudio(){
        requestMicrophonePermission(){ hasPermission in
            if hasPermission{
                AudioDeviceFinder.findDevices(model:self.model)
                self.model.audioInputDefaultDevice = self.getDefaultInDevice(forScope: kAudioObjectPropertyScopeOutput)
                self.model.audioOutputDefaultDevice = self.getDefaultOutDevice(forScope: kAudioObjectPropertyScopeInput)
                
                let deviceIn = self.model.getAudioInDevice(name: self.model.audioInDevice)
                if(deviceIn != nil){
                    self.setInputDevice(device:deviceIn!)
                }
               
                let deviceOut = self.model.getAudioOutDevice(name: self.model.audioOutDevice)
                if deviceOut != nil{
                    self.setOutputDevice(device:deviceOut!)
                }
            }
        }
    }
    
    func setDefaultDeviceOutput(device:ADevice, forScope scope: AudioObjectPropertyScope) {
        var deviceID = device.id
        
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
    
    func setDefaultDeviceInput(device:ADevice, forScope scope: AudioObjectPropertyScope) {
        var deviceID = device.id
        
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
    
    func setInputDevice(device:ADevice){
        setDefaultDeviceInput(device:device, forScope: kAudioObjectPropertyScopeInput)
    }
    
    func setOutputDevice(device:ADevice){
        setDefaultDeviceOutput(device:device, forScope: kAudioObjectPropertyScopeOutput)
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
        let device = model.getAudioInDevice(name:name)
        let engine = AVAudioEngine()
        var inputDeviceID: AudioDeviceID = device!.id
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
            completion(true)
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    completion(granted)
                } else {
                    completion(granted)
                }
            }
            
        case .denied, .restricted:
            SystemSettingsHandler.openSystemSetting(for: "microphone")
            completion(false)
            
        @unknown default:
            completion(false)
        }
    }
}
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

            var name:CFString?
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

            var name:CFString?
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
    
    let model:Model
    
    init(model:Model){
        self.model = model
    }
    
    static func findDevices(model:Model) {
        DispatchQueue.main.async {
            var propsize:UInt32 = 0
            
            var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
                mSelector:AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
                mScope:AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
                mElement:AudioObjectPropertyElement(kAudioObjectPropertyElementMain))
            
            var result:OSStatus = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, UInt32(MemoryLayout<AudioObjectPropertyAddress>.size), nil, &propsize)
            
            if (result != 0) {
                return
            }
            
            let numDevices = Int(propsize / UInt32(MemoryLayout<AudioDeviceID>.size))
            
            var devids = [AudioDeviceID]()
            for _ in 0..<numDevices {
                devids.append(AudioDeviceID())
            }
            
            result = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propsize, &devids);
            if (result != 0) {
                return
            }
            
            model.audioInDevices.removeAll()
            model.audioOutDevices.removeAll()
            for i in 0..<numDevices {
                let audioDevice = AudioDevices(deviceID:devids[i])
                if (audioDevice.hasInput) {
                    guard let name = audioDevice.name else{
                        continue
                    }
                    model.audioInDevices.append(ADevice(uid:audioDevice.uid!, name:name, id:audioDevice.audioDeviceID))
                }
                if (audioDevice.hasOutput) {
                    guard let name = audioDevice.name else{
                        continue
                    }
                    model.audioOutDevices.append(ADevice(uid:audioDevice.uid! , name:name, id:audioDevice.audioDeviceID))
                }
            }
            // set defaullts if we have any
            if  (UserDefaults.standard.string(forKey: "audioIn") != nil){
                model.audioInDevice = UserDefaults.standard.string(forKey: "audioIn")!
                
            }else{
                if model.audioInDevices.count > 0{
                    model.audioInDevice = model.audioInDevices[model.audioInDevices.count - 1].name
                }else{
                    print("There are no Audio In devices")
                }
            }
            
            if  (UserDefaults.standard.string(forKey: "audioOut") != nil){
                model.audioOutDevice = UserDefaults.standard.string(forKey: "audioOut")!
            }else{
                if model.audioOutDevices.count > 0{
                    model.audioOutDevice = model.audioOutDevices[model.audioOutDevices.count - 1].name
                }else{
                    print("There are no Audio Out devices")
                }
            }
        }
    }
}
#endif
