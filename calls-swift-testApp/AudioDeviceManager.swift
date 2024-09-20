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
import WebRTC

#if os(iOS) && !targetEnvironment(macCatalyst)
class AudioDeviceManager : NSObject, RTCAudioSessionDelegate{
    @Service var model: Model
    let session = RTCAudioSession.sharedInstance()
    
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
            //SystemSettingsHandler.openSystemSetting(for: "microphone")
            completion(false)
            
        @unknown default:
            completion(false)
        }
    }
    
    func audioSessionDidBeginInterruption(_ ssession:RTCAudioSession){
        print("audioSessionDidBeginInterruption")
    }

    /** Called on a system notification thread when AVAudioSession ends an
     *  interruption event.
     */
    func audioSessionDidEndInterruption(_ session:RTCAudioSession, shouldResumeSession :Bool){
        print("audioSessionDidEndInterruption")
    }

    /** Called on a system notification thread when AVAudioSession changes the
     *  route.
     */
    func audioSessionDidChangeRoute(_ session:RTCAudioSession, reason:AVAudioSession.RouteChangeReason, previousRoute:AVAudioSessionRouteDescription){
        print("audioSessionDidChangeRoute")
    }

    /** Called on a system notification thread when AVAudioSession media server
     *  terminates.
     */
    func audioSessionMediaServerTerminated(_ session:RTCAudioSession){
        print("audioSessionMediaServerTerminated")
    }

    /** Called on a system notification thread when AVAudioSession media server
     *  restarts.
     */
    func audioSessionMediaServerReset(_ session:RTCAudioSession){
        print("audioSessionMediaServerReset")
    }

    // TODO(tkchin): Maybe handle SilenceSecondaryAudioHintNotification.

   func audioSession(_ session:RTCAudioSession, didChangeCanPlayOrRecord:Bool){
       print("audioSession didChangeCanPlayOrRecord \(didChangeCanPlayOrRecord)")
    }

    /** Called on a WebRTC thread when the audio device is notified to begin
     *  playback or recording.
     */
    func audioSessionDidStartPlayOrRecord(_ session:RTCAudioSession){
        print("audioSessionDidStartPlayOrRecord")
    }

    /** Called on a WebRTC thread when the audio device is notified to stop
     *  playback or recording.
     */
    func audioSessionDidStopPlayOrRecord(_ session:RTCAudioSession){
        print("audioSessionDidStopPlayOrRecord")
    }

    /** Called when the AVAudioSession output volume value changes. */
    func audioSession( _ session:RTCAudioSession, didChangeOutputVolume:Float){
        print("didChangeOutputVolume \(didChangeOutputVolume)")
    }

    /** Called when the audio device detects a playout glitch. The argument is the
     *  number of glitches detected so far in the current audio playout session.
     */
    func audioSession(_ session:RTCAudioSession,didDetectPlayoutGlitch:Int64){
        print("didDetectPlayoutGlitch \(didDetectPlayoutGlitch)")
    }

    /** Called when the audio session is about to change the active state.
     */
    func audioSession(_ session:RTCAudioSession, willSetActive:Bool){
        print("")
    }

    /** Called after the audio session sucessfully changed the active state.
     */
    func audioSession(_ session:RTCAudioSession, didSetActive:Bool){
        print("")
    }

    /** Called after the audio session failed to change the active state.
     */
    func audioSession(_ session:RTCAudioSession, failedToSetActive:Bool, error: any Error){
        print("")
    }

    func audioSession(_ session:RTCAudioSession, audioUnitStartFailedWithError:any Error){
        print("")
    }

    func setupNotifications() {
        // Get the default notification center instance.
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(handleRouteChange),
                       name: AVAudioSession.routeChangeNotification,
                       object: nil)
    }

    @objc func handleRouteChange(notification: Notification) {
        print(notification)
    }

    @MainActor
    func setup(){
        session.add(self) // delegate
        setupNotifications()
        
        requestMicrophonePermission(){ hasPermission in
            if !hasPermission{
                print("no audio permission")
            }else{
                print("audio permission granted")
            }
        }
    //AVAudioSession.sharedInstance()
        session.lockForConfiguration()
        do{
           // session.useManualAudio = true //  Why this hack?
            try session.setCategory(.playAndRecord, mode: .default, options:  [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP, .duckOthers, .mixWithOthers])
            try session.setActive(true)
           // session.useManualAudio = false // Why this hack?
        }catch{
            print(error)
        }
        session.unlockForConfiguration()
        
        // In devices
        self.model.audioInDevices.removeAll()
        for input in session.session.availableInputs!{
            var device = ADevice()
            device.id = 0
            device.name = input.portName
            device.uid = input.uid
            self.model.audioInDevices.append(device)
          //  print( "Appending to input list \(device.name)")
        }
        self.model.audioInDevice = self.model.audioInDevices.last!
        self.model.audioInName = self.model.audioInDevices.last?.name ?? ""
       // print("available inputs \(model.audioInDevices.count)")

        setInputDevice(device: self.model.audioInDevices.last!)

        // out device
        let outputs = session.currentRoute.outputs
        self.model.audioOutDevices.removeAll()
        for out in outputs{
            var device = ADevice()
            device.id = 0
            device.name = out.portName
            device.uid = out.uid
            self.model.audioOutDevices.append(device)
            print("out device \( device.name)")
        }
        print("available outputs \(model.audioOutDevices.count)")
        self.model.audioOutDevice = self.model.audioOutDevices.last?.name ?? ""
      
        //setOutputDevice(device: self.model.audioOutDevices.last!)
    }
    
    func setInputDevice(device: ADevice){
        do {
            let avSession = AVAudioSession.sharedInstance()
            guard let availableInputs = avSession.availableInputs else {
                print("No inputs available ")
                return
            }
            print("Have inputs \(availableInputs.count)")
            for d in availableInputs{
                print("testing for  available: \( d.portName) requested: \(device.name)")
                if d.portName == device.name{
                    print("Setting in Device \( d.portName)")
                    //let session = RTCAudioSession.sharedInstance()
                   // session.lockForConfiguration()
                    try avSession.setPreferredInput(d)
                    print("Preferrred device set to \(d.portName)")
                    
                    for d in RTC.factory.audioDeviceModule.inputDevices{
                        if d.deviceId == d.deviceId{
                            print("Setting Audio Device to \(d)")
                           // WebRTC_Client.factory.audioDeviceModule.inputDevice = d
                            
                            RTC.factory.audioDeviceModule.trySetInputDevice(d)
                        }
                    }
                   
                   // session.unlockForConfiguration()
                }
            }
        }
        catch {
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
    @Service var model: Model
    
    init(){

    }
    
    @MainActor
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

    @MainActor
    func setupAudio(){
        requestMicrophonePermission(){ hasPermission in
            if hasPermission{
                AudioDeviceFinder.findDevices(model:self.model)
                self.model.audioInputDefaultDevice = self.getDefaultInDevice(forScope: kAudioObjectPropertyScopeOutput)
                self.model.audioOutputDefaultDevice = self.getDefaultOutDevice(forScope: kAudioObjectPropertyScopeInput)
  
                let deviceIn = self.model.getAudioInDevice(name: self.model.audioInName)
                if(deviceIn != nil){
                    self.setInputDevice(device:deviceIn!)
                    self.model.audioInDevice = deviceIn!
                }
               
                let deviceOut = self.model.getAudioOutDevice(name: self.model.audioOutName)
                if deviceOut != nil{
                    self.setOutputDevice(device:deviceOut!)
                    self.model.audioOutDevice = deviceOut!
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
    
    static func audioInNameToDevice(name:String)->ADevice?{
        for device in Model.getInstance().audioInDevices{
            if device.name == name{
                return device
            }
        }
        return nil
    }
    
    static func audioOutNameToDevice(name:String)->ADevice?{
        for device in Model.getInstance().audioOutDevices{
            if device.name == name{
                return device
            }
        }
        return nil
    }
    
    @MainActor
    static func findDevices(model:Model) {
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
            model.audioInName = UserDefaults.standard.string(forKey: "audioIn")!
            model.audioInDevice =  audioInNameToDevice(name:model.audioInName)
            
        }else{
            if model.audioInDevices.count > 0{
                model.audioInName = model.audioInDevices[model.audioInDevices.count - 1].name
                model.audioInDevice =  audioInNameToDevice(name:model.audioInName)
            }else{
                print("There are no Audio In devices")
            }
        }
        
        if  (UserDefaults.standard.string(forKey: "audioOut") != nil){
            model.audioOutName = UserDefaults.standard.string(forKey: "audioOut")!
            model.audioOutDevice =  audioInNameToDevice(name:model.audioInName)
        }else{
            if model.audioOutDevices.count > 0{
                model.audioOutName = model.audioOutDevices[model.audioOutDevices.count - 1].name
                model.audioOutDevice =  audioInNameToDevice(name:model.audioInName)
            }else{
                print("There are no Audio Out devices")
            }
        }
    }
}
#endif
