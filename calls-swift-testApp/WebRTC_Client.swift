//
//  WebRTC_Client.swift
//  calls-swift-testApp
//
//  Created by mat on 8/24/24.
//

import Foundation
import AVFoundation
import WebRTC

class WebRTC_Client :NSObject, RTCPeerConnectionDelegate{
    
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var localAudioTrack: RTCAudioTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    
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
            if Model.shared.currentstate == .NEW_SESSION{
                STM.shared.exec(state: .NEW_LOCAL_TRACKS)
            }
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
        await CloudflareCallsApi.shared.api.newSession(sdp: sdp){ [self] sessionId, sdp, error in
            Model.shared.sessionId = sessionId
            Model.shared.hasSDPRemote = "✅"
            
            let desc = RTCSessionDescription(type: .answer , sdp: sdp)
            Task{
                do{
                    await try peerConnection!.setRemoteDescription(desc);
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

        // att the Me View to the local local Video track
        self.localVideoTrack?.add(Model.shared.meView)
       
        self.videoCapturer = capturer
        let initalize = RTCRtpTransceiverInit()
        initalize.direction = .sendOnly
        var transceiverAudio = peerConnection?.addTransceiver(with: localAudioTrack!, init: initalize)
        var transceiverVideo = peerConnection?.addTransceiver(with: localVideoTrack!, init: initalize)
      

        print("localTracks")
    }
    
    func remoteTracks() async{
        
    }
}
