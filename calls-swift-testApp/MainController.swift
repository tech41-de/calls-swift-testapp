//
//  MainController.swift
//  RSession
//
//  Created by mat on 8/7/24.
//

import SwiftUI
import AVFoundation
import WebRTC

extension MainController: WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate:RTCIceCandidate) {
        print("discovered local candidate")
        self.localCandidateCount += 1
       // self.signalClient.send(candidate: candidate)
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        switch state {
        case .connected, .completed:
            Model.shared.isConnected = true
        case .disconnected:
            Model.shared.isConnected = false
        case .failed, .closed:
            Model.shared.isConnected = false
        case .new, .checking, .count:
            Model.shared.isConnected = false
        @unknown default:
            Model.shared.isConnected = false
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        DispatchQueue.main.async {
            let message = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes)"
            print(message)
        }
    }
}

/*
extension MainController: SignalClientDelegate {
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        self.signalingConnected = true
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        self.signalingConnected = false
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        print("Received remote sdp")
        self.webRTCClient.set(remoteSdp: sdp) { (error) in
            self.hasRemoteSdp = true
            print(sdp)
        }
    }
    
    func signalClientRecieveSDP(sdp: RTCSessionDescription) {
        print("Received remote sdp")
        self.webRTCClient.set(remoteSdp: sdp) { (error) in
            self.hasRemoteSdp = true
            print(sdp)
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
        self.webRTCClient.set(remoteCandidate: candidate){ error in
            print("Received remote candidate")
            self.remoteCandidateCount += 1
        }
    }
}
 */

class MainController {
    //private let signalClient: SignalingClient
    private let webRTCClient: WebRTCClient

    private var signalingConnected: Bool = false {
        didSet {
            DispatchQueue.main.async {
                if self.signalingConnected {
                    Model.shared.signalIndicator = "✅"
                }
                else {
                    Model.shared.signalIndicator =  "❌"
                }
            }
        }
    }
    
    private var hasLocalSdp: Bool = false {
        didSet {
            DispatchQueue.main.async {
                Model.shared.hasSDPLocal = self.hasLocalSdp ? "✅" : "❌"
            }
        }
    }
    
    private var localCandidateCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                print("localCandidateCount \(self.localCandidateCount)")
            }
        }
    }
    
    private var hasRemoteSdp: Bool = false {
        didSet {
            DispatchQueue.main.async {
                Model.shared.hasSDPRemote = self.hasRemoteSdp ? "✅" : "❌"
            }
        }
    }
    
    private var remoteCandidateCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                print("remoteCandidateCount \(self.remoteCandidateCount)")
            }
        }
    }
    
    private var speakerOn: Bool = false {
        didSet {
            //let title = "Speaker: \(self.speakerOn ? "On" : "Off" )"
        }
    }
    
    private var mute: Bool = false {
        didSet {
           // let title = "Mute: \(self.mute ? "on" : "off")"
        }
    }
    
    func offerSDP() {
        self.webRTCClient.offer { (sdp) in
            self.hasLocalSdp = true
            print(sdp)
            
            Task{
                Model.shared.sdpLocal = sdp.sdp
                await CloudflareCallsApi.shared.api.newSession(sdp: sdp.sdp){ sessionId, sdp, error in
                    Model.shared.sessionId = sessionId
                    Model.shared.hasSDPRemote = "✅"
                    print(sdp)
                    let sdp = RTCSessionDescription(type: .answer, sdp: sdp)
                    self.webRTCClient.set(remoteSdp: sdp){err in
                        print(err)
                        self.webRTCClient.createMediaSenders()
                        Model.shared.localVideoTrackId = self.webRTCClient.getLocalVideoTrackId()
                    }
                }
            }
        }
    }
    
    init(webRTCClient: WebRTCClient) {
        self.webRTCClient = webRTCClient
        self.signalingConnected = false
        self.hasLocalSdp = false
        self.hasRemoteSdp = false
        self.localCandidateCount = 0
        self.remoteCandidateCount = 0
        self.speakerOn = true
        self.webRTCClient.delegate = self
    }
}
