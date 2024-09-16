//
//  WebRTC_Client.swift
//  calls-swift-testApp
//
//  Created by mat on 8/24/24.
//

import Foundation
import AVFoundation
import WebRTC
import Calls_Swift

extension RTC {
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd receiver: RTCRtpReceiver, streams: [RTCMediaStream]) {
        let initalize = RTCRtpTransceiverInit()
        initalize.direction = .recvOnly
        if let videoTrack = receiver.track as? RTCVideoTrack {
            self.remoteVideoTrack = videoTrack as RTCVideoTrack
            self.remoteVideoTrack!.add(Model.getInstance().youView)
            return
        }

        if let audioTrack = receiver.track as? RTCAudioTrack {
            self.remoteAudioTrack = audioTrack as RTCAudioTrack
            return
        }
    }
}

class RTC :NSObject, RTCPeerConnectionDelegate, RTCDataChannelDelegate{
    
    var model : Model?
    var controller : Controller?
    
    private var localAudioTrack: RTCAudioTrack?
    private var localVideoTrack: RTCVideoTrack?
    private var localDataChannel: RTCDataChannel?

    private var remoteAudioTrack: RTCAudioTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    private var remoteDataChannel: RTCDataChannel?
 
    var transceiverAudio : RTCRtpTransceiver?
    var transceiverVideo : RTCRtpTransceiver?
    var transceiverData : RTCRtpTransceiver?

    private var videoCapturer: RTCCameraVideoCapturer? //RTCVideoCapturer?
    
    private var dataRemoteDelegate : ChannelDataReceiver?
    private var peerConnection: RTCPeerConnection?
    private var videoLocalId = ""
    
    private let constraint = RTCMediaConstraints(mandatoryConstraints: nil,optionalConstraints:nil)

    private static var preProcessor =  AudioPreProcessor()
    private static var postProcessor = AudioPostProcessor()
    private static var audioProcessingModule : RTCDefaultAudioProcessingModule = .init()
    
    static let videoSenderCapabilites = factory.rtpSenderCapabilities(forKind: kRTCMediaStreamTrackKindVideo)
    static let audioSenderCapabilites = factory.rtpSenderCapabilities(forKind: kRTCMediaStreamTrackKindAudio)
    
    static var audioDeviceModule:RTCAudioDeviceModule{
        factory.audioDeviceModule
    }
    
    static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(bypassVoiceProcessing:true,
                                        encoderFactory: videoEncoderFactory,
                                        decoderFactory: videoDecoderFactory,
                                        audioProcessingModule: audioProcessingModule)
    }()
    
    static func createPeerConnection(_ configuration: RTCConfiguration,
                                         constraints: RTCMediaConstraints) -> RTCPeerConnection?
        {
            DispatchQueue.WebRTCQueue.sync { factory.peerConnection(with: configuration,
                                                                                    constraints: constraints,
                                                                                    delegate: nil) }
        }
    
    static func createSessionDescription(type: RTCSdpType, sdp: String) -> RTCSessionDescription {
        DispatchQueue.WebRTCQueue.sync { RTCSessionDescription(type: type, sdp: sdp) }
    }
    
    static func createVideoCapturer() -> RTCVideoCapturer {
        DispatchQueue.WebRTCQueue.sync { RTCVideoCapturer() }
    }
    
    static func createVideoSource(forScreenShare: Bool) -> RTCVideoSource {
           DispatchQueue.WebRTCQueue.sync { factory.videoSource(forScreenCast: forScreenShare) }
       }

   static func createVideoTrack(source: RTCVideoSource) -> RTCVideoTrack {
       DispatchQueue.WebRTCQueue.sync { factory.videoTrack(with: source, trackId: "v_" + UUID().uuidString) }
   }
    
    static func createAudioSource(_ constraints: RTCMediaConstraints?) -> RTCAudioSource {
        DispatchQueue.WebRTCQueue.sync { factory.audioSource(with: constraints) }
    }

    static func createAudioTrack(source: RTCAudioSource) -> RTCAudioTrack {
        DispatchQueue.WebRTCQueue.sync { factory.audioTrack(with: source, trackId: "a_" + UUID().uuidString) }
    }

    static func createDataChannelConfiguration(ordered: Bool = true, maxRetransmits: Int32 = -1) -> RTCDataChannelConfiguration{
        let result = DispatchQueue.WebRTCQueue.sync { RTCDataChannelConfiguration() }
        result.isOrdered = ordered
        result.maxRetransmits = maxRetransmits
        return result
    }

    static func createDataBuffer(data: Data) -> RTCDataBuffer {
        DispatchQueue.WebRTCQueue.sync { RTCDataBuffer(data: data, isBinary: true) }
    }
    
    override init(){
        super.init()
    }
    
    func setup(model:Model,  controller:Controller){
        self.model = model
        self.controller = controller
        self.dataRemoteDelegate = ChannelDataReceiver(controller: controller)
    }
    
    /*
     RTCPeerConnectionDelegate ================================================
     */
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {

    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {

    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        if peerConnection.iceConnectionState == .connected{
            DispatchQueue.main.async {
                self.model!.isConnected = true
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {

    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {

    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {

    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {

    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {

    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd receiver: RTCRtpReceiver){

    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {

    }
    // End of RTCPeerConnectionDelegate
    
    // RTCPDataChannelDelegate
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {

    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {

    }
    // End of RTCPDataChannelDelegate
    
    func sendData(_ data: Data) {
        let buffer = RTCDataBuffer(data: data, isBinary: true)
        self.localDataChannel?.sendData(buffer)
    }
    
    func sendText(json: String) {
        let data = Data(json.utf8)
        let buffer = RTCDataBuffer(data: data, isBinary: false)
        self.localDataChannel?.sendData(buffer)
    }
    
    @MainActor
    func switchAudio(name:String){
        if peerConnection == nil{
            return
        }

        guard let device = model!.getAudioInDevice(name: name)else{
            return
        }
        model!.audioInName = name
        model!.audioInDevice = device
        UserDefaults.standard.set(name, forKey: "audioIn")
        
        let senders = peerConnection!.senders
        for s in senders{
            if s.track?.kind == "audio"{
                s.track!.isEnabled = false
                #if os(iOS)
                AudioDeviceManager().setInputDevice(device:device)
                #else
                AudioDeviceManager().setInputDevice(device:device)
                #endif
                //setupAudio()
                let audioSource = RTC.createAudioSource(getRTCMediaAudioInConstraints())
                replaceAudioTrack(peerConnection: peerConnection!, newAudioSource: audioSource)
               // s.track = localAudioTrack
               // s.track!.isEnabled = true
                print("localAudioTrack reset")
            }
        }
    }
    
    func switchVideo(){
        Task{
         await setupStream()
            if peerConnection == nil{
                return
            }
            let senders = peerConnection!.senders
            for s in senders{
                if s.track?.kind == "video"{
                    s.track?.isEnabled = false
                    s.track = localVideoTrack
                    s.track?.isEnabled = true
                }
            }
        }
    }
    
    func getDefaultConstraints() ->RTCMediaConstraints{
        let constrain  = RTCMediaConstraints(mandatoryConstraints: [:],
         optionalConstraints: [
            "DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue
         ])
       return constrain
    }
   
    
    func getRTCMediaAudioInConstraints() ->RTCMediaConstraints{
        let constrain  = RTCMediaConstraints(mandatoryConstraints: [
            "offerToReceiveAudio": "true",
            "echoCancellation": "false",
            "autoGainControl": "false",
            "googEchoCancellation": "false",
            "noiseSuppression":"false",
            "channelCount":"2",
            "sampleRate":"48000",
            "sampleSize":"16",
            "latency":"0",
            "volume":"1.0"
        ],
         optionalConstraints: [
            "DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue
         ])
       return constrain
    }
    
    func getRTCMediaAudioOutConstraints() ->RTCMediaConstraints{
        let constrain  = RTCMediaConstraints(mandatoryConstraints: [
            "deviceId":model!.audioOutDevice,
            "offerToReceiveAudio": "true",
            "echoCancellation": "false",
            "autoGainControl": "false",
            "googEchoCancellation": "false",
            "noiseSuppression":"false",
            "channelCount":"2",
            "sampleRate":"48000",
            "sampleSize":"16",
            "latency":"0",
            "volume":"1.0"
        ],
         optionalConstraints: [
            "DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue
         ])
       return constrain
    }
    
    @MainActor
    func setupAudio(){
        // opus/48000/2
        // https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints
        let audioSource = RTC.createAudioSource(getRTCMediaAudioInConstraints())
        audioSource.volume = 10
        localAudioTrack = RTC.createAudioTrack(source: audioSource)
    }
    
    func setupStream() async{
        let videoSource = RTC.createVideoSource(forScreenShare: false)
        localVideoTrack = RTC.createVideoTrack(source: videoSource)
        videoLocalId = localVideoTrack!.trackId
        
        let dm = VideoDeviceManager(model:model!)
        let camera = dm.getDevice(name: model!.camera)
        let (format,fps) = dm.chooseFormat(device:camera!, width:640,fps: 30)
        if format == nil{
            DispatchQueue.main.async {
                self.model!.disableVideo = true
            }
            return
        }

        let capturer = RTCCameraVideoCapturer(delegate: videoSource)
        do{
            try await capturer.startCapture(with: camera!, format: format!, fps: fps)
            if videoCapturer != nil{
                await videoCapturer?.stopCapture()
            }
            videoCapturer = capturer
        }catch{
            print(error)
        }
        localVideoTrack!.add(model!.meView)
    }
    
    func setupPeer() async{
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.cloudflare.com:3478"])]
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        config.bundlePolicy = .maxBundle
        
        guard let peerConnection = RTC.createPeerConnection(config, constraints: getDefaultConstraints()) else {
            fatalError("Could not create new RTCPeerConnection")
        }

        self.peerConnection = peerConnection
        peerConnection.delegate = self
        
        // Start an inactive audio session as required by Cloudflare Calls
        let initalize = RTCRtpTransceiverInit()
        initalize.direction = .inactive
        peerConnection.addTransceiver(of: .audio, init: initalize)

        do{
 
            let sdp = try await peerConnection.offer(for: getRTCMediaAudioInConstraints())
            try await peerConnection.setLocalDescription(sdp)
            DispatchQueue.main.async {
                self.model!.hasSDPLocal = "✅"
                self.model!.exec(state: .NEW_SESSION)
            }
        }
        catch{
            print(error)
        }
    }
    
    /*========================================================================
     Session
     ========================================================================*/
    func newSession() async{
        let c = RTCMediaConstraints(mandatoryConstraints: nil,optionalConstraints:nil)
        do{
            let sdpMe = try await peerConnection!.offer(for: c)
            try await self.peerConnection!.setLocalDescription(sdpMe);
          
            await model!.api.newSession(sdp: sdpMe.sdp){ [self] sessionId, sdp, error in
                if error.count > 0{
                    print("Error \(error) creating new Session, are the Cloudflare Calls Credentials correct?")
                    print("Does the server URl have a slash (/) at the end?")
                    return
                }
                let desc = RTCSessionDescription(type: .answer , sdp: sdp)
          
                Task{
                    do{
                        try await peerConnection!.setRemoteDescription(desc);
                        Task{
                            var counter = 15
                            while(model!.isConnected && counter > 0 ){
                                try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
                                counter -= 1
                            }
                            if counter > 0{
                                DispatchQueue.main.async {
                                    self.model!.sessionId = sessionId
                                    self.model!.hasSDPRemote = "✅"
                                    self.model!.exec(state: .NEW_LOCAL_TRACKS)
                                }
                            }else{
                                print("timeout conneting to STUN, check Internet connection")
                            }
                        }
                    }catch{
                        print(error)
                    }
                }
            }
        }catch{
            print(error)
        }
    }
    
    /*========================================================================
    Track remove
     ========================================================================*/
    func removeTrack(mid:String) async{
        if peerConnection == nil{
            return
        }
        for transceiver in peerConnection!.transceivers{
            if transceiver.mid == mid{
                peerConnection?.removeTrack(transceiver.sender)
            }
        }
    }
    
    // Assuming you have a valid RTCPeerConnection and RTCAudioSource objects
    func replaceAudioTrack(peerConnection: RTCPeerConnection, newAudioSource: RTCAudioSource) {
        // Create a new audio track from the new audio source
        let newAudioTrack = RTC.factory.audioTrack(with: newAudioSource, trackId: model!.localAudioTrackId)
        
        // Get the existing audio sender from the peer connection
        if let audioSender = peerConnection.senders.first(where: { $0.track?.kind == "audio" }) {
            // Replace the existing audio track with the new one
            audioSender.track = newAudioTrack
            
            /*
            audioSender.replaceTrack(newAudioTrack) { error in
                if let error = error {
                    print("Error replacing audio track: \(error.localizedDescription)")
                } else {
                    print("Audio track replaced successfully.")
                }
            }
             */
        } else {
            print("No audio sender found to replace the track.")
        }
    }

    /*========================================================================
     Local Tracks
     ========================================================================*/
    func localTracks() async{
        Task { @MainActor in
             setupAudio()
            
            // buildl tranceivers
            let initalize = RTCRtpTransceiverInit()
            initalize.direction = .sendOnly
            transceiverAudio = peerConnection!.addTransceiver(with: localAudioTrack!, init: initalize)
            transceiverVideo = peerConnection!.addTransceiver(with: localVideoTrack!, init: initalize)

            do{
                let sdp = try await peerConnection!.offer(for: constraint)
                try await peerConnection!.setLocalDescription(sdp)
                
                // call API Local Tracks
                var localTracks = [Calls.LocalTrack]()
                let trAudio = Calls.LocalTrack(location: "local", mid: transceiverAudio!.mid, trackName:transceiverAudio!.sender.track!.trackId)
                let trVideo = Calls.LocalTrack(location: "local", mid: transceiverVideo!.mid, trackName:transceiverVideo!.sender.track!.trackId)
                let dataChannelName = "d_" + UUID().uuidString
                // update UI
                DispatchQueue.main.async {
                    self.model!.localAudioTrackId = self.localAudioTrack!.trackId
                    self.model!.localVideoTrackId = self.localVideoTrack!.trackId
                    self.model!.dataChannelNameLocal = dataChannelName
                    self.model!.localVideoMid = self.transceiverVideo!.mid
                    
                    var tracks = [Track]()
                    tracks.append(Track(trackId: self.transceiverAudio!.sender.track!.trackId, mid: self.transceiverAudio!.mid, type: "local", kind:"audio"))
                    tracks.append(Track(trackId: self.transceiverVideo!.sender.track!.trackId, mid: self.transceiverVideo!.mid, type: "local", kind:"video"))
                    tracks.append(Track(trackId:dataChannelName, mid: "0", type: "local", kind:"data"))
                    self.model!.tracks = tracks
                }
                
                localTracks.append(trAudio)
                localTracks.append(trVideo)
                var sdpEdited = sdp.sdp
                if sdpEdited.contains("useinbandfec=1"){
                    sdpEdited = sdpEdited.replacingOccurrences(of: "useinbandfec=1", with: "useinbandfec=1; stereo=1; maxaveragebitrate=510000")
                    print("useinbandfec=1 replaced in SDP")
                    print(sdpEdited)
                }else{
                    print("useinbandfec=1 not found in SDP")
                }
                let desc = Calls.SessionDescription( type:"offer",  sdp:sdpEdited)
                let req =  Calls.NewTracksLocal(sessionDescription: desc, tracks:localTracks)
                
                // New Track API Request!
                await model!.api.newLocalTracks(sessionId: model!.sessionId, newTracks: req){newTracksResponse, error in
                    if(error.count > 0)
                    {
                        print(error)
                        return
                    }
                    guard let sdpStr = newTracksResponse?.sessionDescription.sdp else{
                        return
                    }
                    print(sdpStr)
                    let sdp = RTCSessionDescription(type: .answer, sdp: sdpStr)
                   // print(sdp.sdp)
                    self.peerConnection!.setRemoteDescription(sdp){ error in
                        print(error ?? "")
                    }
                    Task{
                        let dataChannel = Calls.DataChannelLocal(location:"local", dataChannelName:dataChannelName)
                        let dataReq = Calls.DataChannelLocalReq(dataChannels:[dataChannel])
                        await self.model!.api.newDataChannel(sessionId: self.model!.sessionId, dataChannelReq: dataReq){dataChannelRes, error in
                            if error != nil && error!.count > 0{
                                print(error ?? "")
                                return
                            }
                            
                            DispatchQueue.main.async { [self] in
                                model!.dataChannelIdLocal = dataChannelRes!.dataChannels.first!.id
                                model!.dataChannelIdRemote = dataChannelRes!.dataChannels.first!.id
                                
                                let dataChannelConfig = RTCDataChannelConfiguration()
                                dataChannelConfig.channelId = Int32( model!.dataChannelIdLocal)
                                dataChannelConfig.isOrdered = true
                                dataChannelConfig.isNegotiated = true
                                //dataChannelConfig.maxPacketLifeTime = 5000 // msec - TODO settings are failing!
                                dataChannelConfig.maxRetransmits = 5
                                localDataChannel = peerConnection!.dataChannel(forLabel:dataChannelName , configuration: dataChannelConfig)
                                if(localDataChannel == nil){
                                    print("Data channel not created!!")
                                    return
                                }
                                localDataChannel?.delegate = self
                                self.model!.exec(state:.START_SIGNALING)
                            }
                        }
                    }
                }
            }catch{
                print(error)
            }
        }
    }
    
    /*========================================================================
     Remote Tracks
     ========================================================================*/
    func remoteTracks() async{
        var tracks = [Calls.RemoteTrack]()
        let trackAudio = Calls.RemoteTrack(location: "remote", sessionId: model!.sessionIdRemote, trackName:model!.trackIdAudioRemote)
        tracks.append(trackAudio)
        
        let trackVideo = Calls.RemoteTrack(location: "remote", sessionId: model!.sessionIdRemote, trackName:model!.trackIdVideoRemote)
        tracks.append(trackVideo)

        let newTracksRemote = Calls.NewTracksRemote(tracks: tracks)
        

        // API Call for new Tracks
        await model!.api.newTracks(sessionId: model!.sessionId, newTracksRemote:newTracksRemote){ [self]newTracksResponse, error in
            
            // Renegotiate
            guard let res = newTracksResponse else {
                print(error ?? "")
                return
            }
            let isRenegotiate = res.requiresImmediateRenegotiation
          
            Task{
                let dataChannels = Calls.DataChannelRemote(location: "remote", dataChannelName: model!.dataChannelNameRemote, sessionId: model!.sessionIdRemote)
                let dataChannelReq = Calls.DataChannelRemoteReq(dataChannels: [dataChannels])
                DispatchQueue.main.async {
                    self.model!.sdpRemote = res.sessionDescription.sdp
                }
                
                await model!.api.newDataChannelRemote(sessionId: model!.sessionId, dataChannelReq:dataChannelReq){ [self] newDataTrackRes, error in
                    if error != nil && error!.count > 0 {
                        print(error ?? "")
                        return
                    }
                    let dataRemoteId = newDataTrackRes!.dataChannels.first!.id
                    let dataChannelConfig = RTCDataChannelConfiguration()
                    dataChannelConfig.channelId = Int32( dataRemoteId)
                    dataChannelConfig.isOrdered = true
                    dataChannelConfig.isNegotiated = true
                    //dataChannelConfig.maxPacketLifeTime = 5000 // TODO Settings are failing!
                    dataChannelConfig.maxRetransmits = 5
                    self.remoteDataChannel = self.peerConnection!.dataChannel(forLabel:"DataSubscriber" , configuration: dataChannelConfig)
                    if(self.remoteDataChannel == nil){
                        print("data remoteDataChannel could not be created!")
                        return
                    }
                    self.remoteDataChannel!.delegate = dataRemoteDelegate

                    if isRenegotiate{
                        Task{
                            if res.sessionDescription.type == "answer"{
                                print("this is wrong, should be an offer")
                                return
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                Task{
                                    await self.renegotiate()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /*========================================================================
     Renegotiate
     ========================================================================*/
    func renegotiate() async{
        let desc = RTCSessionDescription(type: .offer, sdp: model!.sdpRemote)
        do{
            try await self.peerConnection!.setRemoteDescription(desc)
        }
        catch{
            print(error)
        }
        do{
            let answer = try await peerConnection!.answer(for: constraint)
            try await self.peerConnection!.setLocalDescription(answer)
        }
        catch{
            print(error)
        }
        
        // API call Renegotiate
        let sdp = peerConnection?.localDescription
        let sessionDescription = Calls.SessionDescription(type: "answer", sdp: sdp!.sdp)
        await model!.api.renegotiate(sessionId: model!.sessionId, sessionDescription:sessionDescription){ res in
            DispatchQueue.main.async {
                self.model!.hasRemoteTracks = "✅"
                
                #if os(iOS)
                print("preferredInput: \(RTCAudioSession.sharedInstance().session.preferredInput?.portName)")
                print("SampleRate: \(RTCAudioSession.sharedInstance().session.sampleRate)")
                print("Channels In: \(RTCAudioSession.sharedInstance().session.inputNumberOfChannels)")
                print("Channels Out: \(RTCAudioSession.sharedInstance().session.outputNumberOfChannels)")
                print("Buffer Duration msec: \(1000 * RTCAudioSession.sharedInstance().session.ioBufferDuration)")
                #endif
            }
        }
        // We are done!
        model!.exec(state: .RUNNING)
    }
    
    func getOfffer(completion:  @escaping (_ sdp:RTCSessionDescription? )->()) async{
        do{
            let sdp = try await self.peerConnection?.offer(for: constraint)
            completion(sdp)
        }catch{
            print(error)
        }
    }
    
    func getAnswer(completion:  @escaping (_ sdp:RTCSessionDescription? )->()) async{
        do{
            let sdp = try await self.peerConnection?.answer(for: constraint)
            completion(sdp)
        }catch{
            print(error)
        }
    }
}
