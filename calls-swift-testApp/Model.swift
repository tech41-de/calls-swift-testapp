//
//  Model.swift
//  calls-swift-testApp
//
//  Created by mat on 8/22/24.
//

import SwiftUI
import AVFoundation

import WebRTC
import Calls_Swift

struct ADevice{
    var id = ""
    var name = ""
    var uid :UInt32 = 0
}

class Model : ObservableObject{
    
    static let shared = Model()
    @Published var signalIndicator = "❌"
    @Published var hasSDPLocal = "❌"
    @Published var hasSDPRemote = "❌"
    @Published var audioInDevices = [ADevice]()
    @Published var audioOutDevices = [ADevice]()
    @Published var videoDevices = [ADevice]()
    @Published var audioInDevice = ""
    @Published var audioOutDevice = ""
    @Published var camera = ""
    @Published var isConnected = false
    @Published var webRtcClientA : WebRTCClient?
    @Published var webRtcClientB : WebRTCClient?
    @Published var sdpLocal : String = ""
    
#if os(macOS)
    @Published var youView = RTCMTLNSVideoView()
    @Published var meView = RTCMTLNSVideoView()
    @Published var audioInputDefaultDevice : AudioDeviceID? // the devices pre app Start
    @Published var audioOutputDefaultDevice : AudioDeviceID?
#else
    @Published var youView = RTCMTLVideoView()
    @Published var meView = RTCMTLVideoView()
#endif

    @Published var trackIdLocalVideo =  ""
    @Published var trackIdLocalAudio =  ""
    @Published var midLocalVideo =  ""
    @Published var midLocalAudio =  ""
    
    @Published var mainController : MainController?
    @Published var sessionId = ""
    @Published var hasConfig = false
    @Published var isLoggedOn = false
    @Published var errorMsg = ""
    @Published var trackIdVideoRemote = ""
    
    @Published var videoWidth : CGFloat = 0
    @Published var videoHeight :CGFloat = 0
    @Published var localVideoTrackId = ""
    
    func getAudioInDevice(name:String)->ADevice?{
        for d in audioInDevices{
            if d.name == name{
                return d
            }
        }
        return nil
    }
    
    func getAudioOutDevice(name:String)->ADevice?{
        for d in audioOutDevices{
            if d.name == name{
                return d
            }
        }
        return nil
    }
}
