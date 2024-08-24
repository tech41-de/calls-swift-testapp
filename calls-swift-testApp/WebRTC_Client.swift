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

class WebRTC_Client :NSObject, RTCPeerConnectionDelegate{
    
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var localAudioTrack: RTCAudioTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    
    var haveFirstPeer = false
    
    // RTCPeerConnectionDelegate
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("peerConnectionShouldNegotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("didChange RTCSignalingState")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        if peerConnection.iceConnectionState == .connected &&  Model.shared.isConnected == false{
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
    
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("didOpen RTCDataChannel")
    }
    // End of RTCPeerConnectionDelegate
    
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    
    private var peerConnection: RTCPeerConnection?
    
    func setupPeer(){
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.cloudflare.com:3478"])]
       // config.sdpSemantics = .unifiedPlan
       // config.continualGatheringPolicy = .gatherContinually
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
        
        let c = RTCMediaConstraints(mandatoryConstraints: nil,optionalConstraints:nil)
        peerConnection.offer(for: c){sdp, error in
            Model.shared.sdpLocal = sdp!.sdp
            peerConnection.setLocalDescription(sdp!){completionHandler in
                print(completionHandler?.localizedDescription)
                STM.shared.exec(state: .NEW_SESSION)
            }
        }
    }
    
    func newSession(sdp:String) async{
        await Model.shared.api.newSession(sdp: sdp){ [self] sessionId, sdp, error in
            Model.shared.sessionId = sessionId
            Model.shared.hasSDPRemote = "✅"
            
            let desc = RTCSessionDescription(type: .answer , sdp: sdp)
            Task{
                do{
                    await try peerConnection!.setRemoteDescription(desc);
                    STM.shared.exec(state: .NEW_LOCAL_TRACKS)
                }catch{
                    print(error)
                }
            }
        }
    }
    
    func localTracks() async{
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints:nil, optionalConstraints: nil)
        let audioSource = WebRTC_Client.factory.audioSource(with: audioConstrains)
        localAudioTrack = WebRTC_Client.factory.audioTrack(with: audioSource, trackId: "audio0")
 
        let videoSource = WebRTC_Client.factory.videoSource()
        localVideoTrack = WebRTC_Client.factory.videoTrack(with: videoSource, trackId: "video0")
        let camera = VideoDeviceManager().getDevice(name: Model.shared.camera)
        guard let frontCamera = camera,
            let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted { (f1, f2) -> Bool in
                let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
                let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
                return width1 < width2
            }).last,
        
            // choose highest fps
            let fps = (format.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last) else {
            return
        }

        let capturer = RTCCameraVideoCapturer(delegate: videoSource)
        do{
            try await capturer.startCapture(with: camera!, format: format, fps: Int(fps.maxFrameRate))
        }catch{
            print(error)
        }
        self.localVideoTrack?.add(Model.shared.meView)
        self.videoCapturer = capturer
        let initalize = RTCRtpTransceiverInit()
        initalize.direction = .sendOnly
        let transceiverAudio = peerConnection?.addTransceiver(with: localAudioTrack!, init: initalize)
        let transceiverVideo = peerConnection?.addTransceiver(with: localVideoTrack!, init: initalize)
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil,optionalConstraints:nil)
        peerConnection!.offer(for: constraints){sdp, error in
            do{
                Task{
                    try await self.peerConnection!.setLocalDescription(sdp!)
                    Model.shared.sdpLocal = sdp!.sdp
                    
                    Model.shared.localAudioTrackId = transceiverAudio!.sender.track!.trackId
                    Model.shared.localVideoTrackId = transceiverVideo!.sender.track!.trackId
                    
                    print( Model.shared.localAudioTrackId)
                    
                    var localTracks =  [Calls.LocalTrack]()
                    
                    for t in self.peerConnection!.transceivers{
                        if t.mediaType == .audio{
                            let t = Calls.LocalTrack(location: "local", mid: t.mid, trackName:"audio0")
                            localTracks.append(t)
                        }
                        if t.mediaType == .video{
                            let t = Calls.LocalTrack(location: "local", mid: t.mid, trackName:"video0")
                            localTracks.append(t)
                        }
                    }
                    let desc = Calls.SessionDescription( type:"offer",  sdp: Model.shared.sdpLocal)
                    let req =  Calls.NewTracksLocal(sessionDescription: desc, tracks:localTracks)
                    
                    await Model.shared.api.newLocalTracks(sessionId: Model.shared.sessionId, newTracks: req){newTracksResponse, error in
                        let sdpStr = newTracksResponse!.sessionDescription.sdp
                        let sdp = RTCSessionDescription(type: .answer, sdp: sdpStr)
                      
                        self.peerConnection!.setRemoteDescription(sdp){ error in
                            print(error)
                        }
                    }
                }
            }catch{
                print(error)
            }
        }
    }
    
    func remoteTracks() async{
        var tracks = [Calls.RemoteTrack]()
        print(Model.shared.sessionIdRemote)
        print(Model.shared.trackIdAudioRemote)
        print(Model.shared.trackIdVideoRemote)
        
        let trackAudio = Calls.RemoteTrack(location: "remote", sessionId: Model.shared.sessionIdRemote, trackName:Model.shared.trackIdAudioRemote)
        tracks.append(trackAudio)
        
        let trackVideo = Calls.RemoteTrack(location: "remote", sessionId: Model.shared.sessionIdRemote, trackName: Model.shared.trackIdVideoRemote)
        tracks.append(trackVideo)
        
        let newTracksRemote = Calls.NewTracksRemote(tracks: tracks)
        await Model.shared.api.newTracks(sessionId: Model.shared.sessionId, newTracksRemote:newTracksRemote){newTracksResponse, error in
            
            // Renegotiate
            guard let res = newTracksResponse else {
                print(error)
                return
            }
            let isRenegotiate = res.requiresImmediateRenegotiation
            if isRenegotiate{
                Task{
                    print("isRenegotiate")
                    print(res.sessionDescription.type)
                    if res.sessionDescription.type == "answer"{
                        print("this is wrong, should be an offer")
                        return
                    }
                    let desc = RTCSessionDescription(type: .offer, sdp: res.sessionDescription.sdp)
                    do{
                        try await self.peerConnection!.setRemoteDescription(desc)
                    }
                    catch{
                        print(error)
                    }
                    let constraints = RTCMediaConstraints(mandatoryConstraints: nil,optionalConstraints:nil)
                    self.peerConnection!.answer(for: constraints){answer,arg  in
                        Task{
                            try await self.peerConnection!.setLocalDescription(answer!)
                            
                            // Renegotiate
                            let n = Calls.NewReq(sdp: res.sessionDescription.sdp, type: "answer")
                            let newDesc = Calls.NewDesc(sessionDescription: n)
                            await Model.shared.api.renegotiate(sessionId: Model.shared.sessionId, sdp:newDesc){ res in
                                print(res)
                                print("count \(self.peerConnection!.transceivers.count)")
                                for t in self.peerConnection!.transceivers{
                                    print(t.mediaType)
                                    print(t.receiver.track!.trackId)
                                    
                                    if (t.mediaType == .video){
                                        print("Adding video remote \(t.receiver.track?.trackId)")
                                        self.remoteVideoTrack = t.receiver.track as? RTCVideoTrack
                                        self.remoteVideoTrack?.add(Model.shared.youView)
                                        print("added remote Video")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
