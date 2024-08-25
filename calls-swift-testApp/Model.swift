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

struct ADevice : Hashable{
    var uid = ""
    var name = ""
}

class Model : ObservableObject{
    
    private init(){
        youView.videoContentMode = .scaleAspectFit
        meView.videoContentMode = .scaleAspectFit
    }
    
    let api = Calls()
    
    static let shared = Model()
    @Published var hasRemoteTracks = "❌"
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

    @Published var sdpLocal : String = ""
    @Published var currentstate = States.COLD
    
#if os(macOS)
    @Published var youView = RTCMTLNSVideoView()
    @Published var meView = RTCMTLNSVideoView()
    @Published var audioInputDefaultDevice : AudioDeviceID? // the devices pre app Start
    @Published var audioOutputDefaultDevice : AudioDeviceID?
#else
    @Published var youView = RTCMTLVideoView()
    @Published var meView = RTCMTLVideoView()
#endif

    @Published var midLocalVideo =  ""
    @Published var midLocalAudio =  ""
    @Published var sessionId = ""
    @Published var hasConfig = false
    @Published var isLoggedOn = false
    @Published var errorMsg = ""
 
    @Published var localVideoTrackId = ""
    @Published var localAudioTrackId = ""
    
    @Published var sessionIdRemote = ""
    @Published var trackIdAudioRemote = ""
    @Published var trackIdVideoRemote = ""
    
    @Published var videoWidth : CGFloat = 0
    @Published var videoHeight :CGFloat = 0
    
    var webRtcClient =  WebRTC_Client() // left
    
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
