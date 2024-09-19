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

protocol StateExecutor{
    func exec(state:States)
}

class Model : ObservableObject, @unchecked Sendable{

    public init(){
        Model.model = self
        #if os(iOS)
        youView.videoContentMode = .scaleAspectFit
        meView.videoContentMode = .scaleAspectFit
        #endif
    }
    
    var stateExec : StateExecutor?
    
    func exec(state:States){
        stateExec!.exec(state: state)
    }
    
    // Calls API to Cloudflare
    let api = Calls()
    
    public nonisolated(unsafe) static var model: Model?
    static func getInstance() ->Model{
        return Model.model!
    }

    @Published var hasRemoteTracks = "❌"
    @Published var hasSDPLocal = "❌"
    @Published var hasSDPRemote = "❌"
    @Published var sdpRemote = ""
    @Published var sdpOffer = ""
    @Published var sdpAnswer = ""
    @Published var audioInDevices = [ADevice]()
    @Published var audioOutDevices = [ADevice]()
    @Published var videoDevices = [ADevice]()
    
    @Published var audioInName = ""
    @Published var audioOutName = ""
    @Published var audioInDevice : ADevice?
    @Published var audioOutDevice : ADevice?
    @Published var camera = ""
    @Published var isConnected = false
    @Published var currentstate = States.COLD
    @Published var disableVideo = false
    @Published var isSignalConnectd = false
    
#if os(macOS)
    @Published var youView = RTCMTLNSVideoView(frame:CGRect(x:0,y:0, width:300, height:200))
    @Published var meView = RTCMTLNSVideoView(frame:CGRect(x:0,y:0, width:300, height:200))
    @Published var audioInputDefaultDevice : AudioDeviceID? // the devices pre app Start
    @Published var audioOutputDefaultDevice : AudioDeviceID?
#else
    @Published var youView = RTCMTLVideoView()
    @Published var meView  = RTCMTLVideoView()
    @Published var audioInputDefaultDevice :UInt32  = 0
    @Published var audioOutputDefaultDevice:UInt32  = 0
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
    @Published var dataChannelIdRemote = 0
    @Published var dataChannelIdLocal = 0
    
    @Published var dataChannelNameRemote = ""
    @Published var dataChannelNameLocal = ""
    
    @Published var videoWidth : CGFloat = 0
    @Published var videoHeight :CGFloat = 0
    @Published var room = ""
    @Published var tracks = [Track]()
    @Published var displayMode = DisplayMode.HOME
    @Published var chatReceived = ""
    @Published var pongLatency = 0.0
    @Published var localVideoMid = ""
    
    @Published var isRed = true
    
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
