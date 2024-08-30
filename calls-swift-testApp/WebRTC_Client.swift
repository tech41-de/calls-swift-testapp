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

extension WebRTC_Client {
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd receiver: RTCRtpReceiver, streams: [RTCMediaStream]) {
        let initalize = RTCRtpTransceiverInit()
        initalize.direction = .recvOnly
        if let videoTrack = receiver.track as? RTCVideoTrack {
            self.remoteVideoTrack = videoTrack as RTCVideoTrack
            self.remoteVideoTrack!.add(Model.shared.youView)
            print("Added remote video track \( self.remoteVideoTrack?.trackId)")
            return
        }

        if let audioTrack = receiver.track as? RTCAudioTrack {
            self.remoteAudioTrack = audioTrack as RTCAudioTrack
            print("Added remote audio track \(self.remoteVideoTrack?.trackId)")
            return
        }
    }
}

class WebRTC_Client :NSObject, RTCPeerConnectionDelegate, RTCDataChannelDelegate{

    private var localAudioTrack: RTCAudioTrack?
    private var localVideoTrack: RTCVideoTrack?
    private var localDataChannel: RTCDataChannel?

    private var remoteAudioTrack: RTCAudioTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    private var remoteDataChannel: RTCDataChannel?
 
    var transceiverAudio : RTCRtpTransceiver?
    var transceiverVideo : RTCRtpTransceiver?
    var transceiverData : RTCRtpTransceiver?

    private var videoCapturer: RTCVideoCapturer?
    
    private let constraint = RTCMediaConstraints(mandatoryConstraints: nil,optionalConstraints:nil)
    override init(){
        super.init()
    }
    
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    
    // RTCPeerConnectionDelegate
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("peerConnectionShouldNegotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("didChange RTCSignalingState")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        if peerConnection.iceConnectionState == .connected{
            Model.shared.isConnected = true
        }
        print("didChange RTCIceConnectionState")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("didRemove RTCMediaStream")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("didAdd RTCMediaStream")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("didChange RTCIceGatheringState")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("didGenerate RTCIceCandidate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("didRemove RTCIceCandidate")
    }
    
    // Halluzination WebRTC?
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd receiver: RTCRtpReceiver){
        print("didAdd RTCRtpReceiver")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("didOpen RTCDataChannel")
    }
    // End of RTCPeerConnectionDelegate
    
    // RTCPDataChannelDelegate
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("dataChannelDidChangeState")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        print("RTCDataChannel didReceiveMessageWith")
    }
    // End of RTCPDataChannelDelegate
    
    func sendData(_ data: Data) {
        let buffer = RTCDataBuffer(data: data, isBinary: true)
        self.remoteDataChannel?.sendData(buffer)
    }
    
    func sendText(text: String) {
        let data = Data(text.utf8)
        let buffer = RTCDataBuffer(data: data, isBinary: true)
        self.remoteDataChannel?.sendData(buffer)
    }
    
    private var peerConnection: RTCPeerConnection?
    private var videoLocalId = ""
    
    func setupStream() async{
        let videoSource = WebRTC_Client.factory.videoSource()
        videoLocalId = "v_" + UUID().uuidString
        localVideoTrack = WebRTC_Client.factory.videoTrack(with: videoSource, trackId: videoLocalId)
        let dm = VideoDeviceManager()
        let camera = dm.getDevice(name: Model.shared.camera)
        let (format,fps) = dm.chooseFormat(device:camera!, width:640,fps: 30)
        if format == nil{
            print("Could not select camera format")
            Model.shared.disableVideo = true
            return
        }
        let capturer = RTCCameraVideoCapturer(delegate: videoSource)
        do{
            try await capturer.startCapture(with: camera!, format: format!, fps: fps)
            videoCapturer = capturer
        }catch{
            print(error)
        }
        localVideoTrack!.add(Model.shared.meView)
    }
    
    func setupPeer() async{
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.cloudflare.com:3478"])]
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        config.bundlePolicy = .maxBundle
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil,optionalConstraints: ["DtlsSrtpKeyAgreement":kRTCMediaConstraintsValueTrue])
        guard let peerConnection = WebRTC_Client.factory.peerConnection(with: config, constraints: constraints, delegate: nil) else {
            fatalError("Could not create new RTCPeerConnection")
        }
        self.peerConnection = peerConnection
        peerConnection.delegate = self
        
        // Start an inactive audio session as required by Cloudflare Calls
        let initalize = RTCRtpTransceiverInit()
        initalize.direction = .inactive
        peerConnection.addTransceiver(of: .audio, init: initalize)
        
        do{
            let sdp = try await peerConnection.offer(for: constraint)
            try await peerConnection.setLocalDescription(sdp)
            DispatchQueue.main.async {
                Model.shared.hasSDPLocal = "✅"
                STM.shared.exec(state: .NEW_SESSION)
            }
        }
        catch{
            print(error)
        }
    }
    
    /*
     New Session
     */
    func newSession() async{
        print("Starting newSession")
        let c = RTCMediaConstraints(mandatoryConstraints: nil,optionalConstraints:nil)
        do{
            let sdp = try await peerConnection!.offer(for: c)
            try await self.peerConnection!.setLocalDescription(sdp);
            await Model.shared.api.newSession(sdp: sdp.sdp){ [self] sessionId, sdp, error in
               
                let desc = RTCSessionDescription(type: .answer , sdp: sdp)
                Task{
                    do{
                        try await peerConnection!.setRemoteDescription(desc);
                        Task{
                            var counter = 5
                            while(!Model.shared.isConnected && counter > 0 ){
                                try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
                                counter -= 1
                            }
                            if counter > 0{
                                DispatchQueue.main.async {
                                    Model.shared.sessionId = sessionId
                                    Model.shared.hasSDPRemote = "✅"
                                    STM.shared.exec(state: .NEW_LOCAL_TRACKS)
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
  
    /*
     Local Tracks
     */
    func localTracks() async{
        print(Model.shared.sessionId)
        print("Starting LocalTracks")
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints:nil, optionalConstraints: nil)
        let audioSource = WebRTC_Client.factory.audioSource(with: audioConstrains)
        localAudioTrack = WebRTC_Client.factory.audioTrack(with: audioSource, trackId: "a_" + UUID().uuidString)
        
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
                Model.shared.localAudioTrackId = self.localAudioTrack!.trackId
                Model.shared.localVideoTrackId = self.localVideoTrack!.trackId
                
                var tracks = [Track]()
                tracks.append(Track(trackId: self.transceiverAudio!.sender.track!.trackId, mid: self.transceiverAudio!.mid, type: "local"))
                tracks.append(Track(trackId: self.transceiverVideo!.sender.track!.trackId, mid: self.transceiverVideo!.mid, type: "local"))
                tracks.append(Track(trackId:dataChannelName, mid: "0", type: "local"))
                Model.shared.tracks = tracks
            }
            
            localTracks.append(trAudio)
            localTracks.append(trVideo)
            let desc = Calls.SessionDescription( type:"offer",  sdp:sdp.sdp)
            let req =  Calls.NewTracksLocal(sessionDescription: desc, tracks:localTracks)
            
            // New Track API Request!
            print( Model.shared.sessionId)
            await Model.shared.api.newLocalTracks(sessionId: Model.shared.sessionId, newTracks: req){newTracksResponse, error in
                if(error.count > 0)
                {
                    print(error)
                    return
                }
                guard let sdpStr = newTracksResponse?.sessionDescription.sdp else{
                    return
                }
                let sdp = RTCSessionDescription(type: .answer, sdp: sdpStr)
                self.peerConnection!.setRemoteDescription(sdp){ error in
                    print(error)
                }
                Task{
                   
                    let dataChannel = Calls.DataChannelLocal(location:"local", dataChannelName:dataChannelName)
                    let dataReq = Calls.DataChannelLocalReq(dataChannels:[dataChannel])
                    await Model.shared.api.newDataChannel(sessionId: Model.shared.sessionId, dataChannelReq: dataReq){dataChannelRes, error in
                        if error != nil && error!.count > 0{
                            print(error)
                            return
                        }
                        
                        DispatchQueue.main.async {

                            Model.shared.dataChannelIdLocal = (dataChannelRes?.dataChannels.first!.id)!
                            Model.shared.dataChannelIdRemote = (dataChannelRes?.dataChannels.first!.id)!
                           
                            let dataChannelConfig = RTCDataChannelConfiguration()
                            dataChannelConfig.channelId = Int32( Model.shared.dataChannelIdLocal)
                            dataChannelConfig.isOrdered = true
                            dataChannelConfig.isNegotiated = true
                            dataChannelConfig.maxPacketLifeTime = 2
                            dataChannelConfig.maxRetransmits = 5
                            self.localDataChannel = self.peerConnection!.dataChannel(forLabel:dataChannelName , configuration: dataChannelConfig)
                            self.localDataChannel?.delegate = self
                            
                            
                            STM.shared.exec(state:.INVITE)
                        }
                    }
                }
            }
        }catch{
            print(error)
        }
    }
    
    /*
     Local Tracks
     */
    func remoteTracks() async{
        print("Starting RemoteTracks")
        print("Starting \(Model.shared.sessionIdRemote)")
        print("Adding Audio Track \(Model.shared.trackIdAudioRemote)")
        print("Adding Video Track \(Model.shared.trackIdVideoRemote)")
       
        var tracks = [Calls.RemoteTrack]()
        let trackAudio = Calls.RemoteTrack(location: "remote", sessionId: Model.shared.sessionIdRemote, trackName:Model.shared.trackIdAudioRemote)
        tracks.append(trackAudio)
        
        let trackVideo = Calls.RemoteTrack(location: "remote", sessionId: Model.shared.sessionIdRemote, trackName: Model.shared.trackIdVideoRemote)
        tracks.append(trackVideo)

        let newTracksRemote = Calls.NewTracksRemote(tracks: tracks)
        

        // API Call for new Tracks
        await Model.shared.api.newTracks(sessionId: Model.shared.sessionId, newTracksRemote:newTracksRemote){ [self]newTracksResponse, error in
            
            // Renegotiate
            guard let res = newTracksResponse else {
                print(error)
                return
            }
            let isRenegotiate = res.requiresImmediateRenegotiation
          
            Task{
                let dataChannels = Calls.DataChannelRemote(location: "remote", dataChannelName: Model.shared.dataChannelNameRemote, sessionId: Model.shared.sessionIdRemote)
                let dataChannelReq = Calls.DataChannelRemoteReq(dataChannels: [dataChannels])
                DispatchQueue.main.async {
                    Model.shared.sdpRemote = res.sessionDescription.sdp
                }
                
                await Model.shared.api.newDataChannelRemote(sessionId: Model.shared.sessionId, dataChannelReq:dataChannelReq){ [self] newDataTrackRes, error in
                    if error != nil && error!.count > 0 {
                        print(error)
                        return
                    }
                    let dataRemoteId = newDataTrackRes!.dataChannels.first!.id
                    print(dataRemoteId)
                    
                    let dataChannelConfig = RTCDataChannelConfiguration()
                    dataChannelConfig.channelId = Int32( dataRemoteId)
                    dataChannelConfig.isOrdered = true
                    dataChannelConfig.isNegotiated = true
                    dataChannelConfig.maxPacketLifeTime = 2
                    dataChannelConfig.maxRetransmits = 5
                    self.remoteDataChannel = self.peerConnection!.dataChannel(forLabel:"DataSubscriber" , configuration: dataChannelConfig)
                    self.remoteDataChannel?.delegate = ChannelDataReceiver()
                    
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
    
    /*
     Renegotiate
     */
    
    func renegotiate() async{
        print("Starting Renegotiate")
        let desc = RTCSessionDescription(type: .offer, sdp: Model.shared.sdpRemote)
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
        let n = Calls.SessionDescription( type: "answer", sdp: sdp!.sdp)
        let newDesc = Calls.NewDesc(sessionDescription: n)
        await Model.shared.api.renegotiate(sessionId: Model.shared.sessionId, sdp:newDesc){ res in
            Model.shared.hasRemoteTracks = "✅"
        }
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
