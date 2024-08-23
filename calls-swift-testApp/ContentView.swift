//
//  ContentView.swift
//  calls-swift-testApp
//
//  Created by mat on 8/22/24.
//

import SwiftUI
import Calls_Swift
import WebRTC

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler(selection)
        })
    }
}

struct ContentView: View {
    @State var serverURL = ""
    @State var appId = ""
    @State var appSecret = ""
    @State var isHidden = false
    @State var debugStr = ""
    @State var audioInOptions = [""]
    @State var audioOutOptions = [""]
    @State var videoInOptions = [""]
    
    @State var selectedAudioIn  = ""
    @State var selectedAudioOut  = ""
    @State var selectedVideoIn  = ""
    
    @State private var signal = "❌"
    @State private var hasSDPLocal = "❌"
    @State private var hasSDPRemote = "❌"
    @State private var isConnected = "❌"
    @State private var hasConfig = "❌"
    @State private var isLoggedOn = "❌"
    @State var errorMsg = ""
    @State var m = Model.shared
    @State var sessionId = ""

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let defaults = UserDefaults.standard
   
    
    func videoInChanged(_ tag: String) {
        Model.shared.camera = tag
        UserDefaults.standard.set(tag, forKey: "videoIn")
    }
    
    func audioInChanged(_ tag: String) {
        Controller.shared.updateAudioInputDevice(name: tag)
    }
    
    func audioOutChanged(_ tag: String) {
        Controller.shared.updateAudioOutputDevice(name: tag)
    }
    
    func setupWebRTC(){
        Model.shared.mainController = MainController( webRTCClient: Model.shared.webRtcClientA!)
        
#if os(macOS)
        let remoteRenderer = RTCMTLNSVideoView(frame: CGRect(x:0,y:0, width:Model.shared.videoWidth, height:Model.shared.videoWidth * 9 / 15))
        let localRenderer = RTCMTLNSVideoView(frame: CGRect(x:0,y:0, width:Model.shared.videoWidth, height:Model.shared.videoWidth * 9 / 15))
#else
        let remoteRenderer = RTCMTLVideoView(frame: CGRect(x:0,y:0, width:Model.shared.videoWidth, height:Model.shared.videoWidth * 9 / 15))
        let localRenderer = RTCMTLVideoView(frame: CGRect(x:0,y:0, width:Model.shared.videoWidth, height:Model.shared.videoWidth * 9 / 15))
#endif
        
        Model.shared.youView.addSubview(remoteRenderer)
        
       
        Model.shared.meView.addSubview(localRenderer)
        
        Model.shared.webRtcClientA!.startCaptureLocalVideo(renderer: localRenderer)
        //self.webRTCClient.renderRemoteVideo(to: remoteRenderer)
        
    }
    
    func updateDevies(){
        let m = Model.shared
        videoInOptions.removeAll()
        for d in  m.videoDevices{
            videoInOptions.append(d.name)
        }
        
        audioInOptions.removeAll()
        for d in  m.audioInDevices{
            audioInOptions.append(d.name)
        }
        
        audioOutOptions.removeAll()
        for d in  m.audioOutDevices{
            audioOutOptions.append(d.name)
        }
        selectedVideoIn = m.camera
        selectedAudioIn = m.audioInDevice
        selectedAudioOut = m.audioOutDevice
    }
    
    var body: some View {
        VStack{
            Text("\(errorMsg)").foregroundStyle(.red)
            HStack{
                let fontSize:CGFloat = 9
                Text("\(hasSDPLocal)").font(.system(size: fontSize))
                Text("\(hasSDPRemote)").font(.system(size: fontSize))
                Text("\(isConnected)").font(.system(size: fontSize))
            }
            Button(isHidden ? "show config" : "hide config"){
                isHidden = !isHidden
                defaults.set(isHidden, forKey: "isHidden")
            }.contentShape(Rectangle())
            if !isHidden{
                VStack {
                    Text("Cloudflare Calls Configuration ")
                    Link("Cloudflare Dashboard", destination: URL(string: "https://developers.cloudflare.com/")!)
                    TextField("ServerURL  https://rtc.live.cloudflare.com/v1/apps/", text: $serverURL)
                    TextField("appId", text: $appId)
                    TextField("appSecret", text: $appSecret)
                    Button("set"){
                        defaults.set(serverURL, forKey: "serverURL")
                        defaults.set(appId, forKey: "appId")
                        defaults.set(appSecret, forKey: "appSecret")
                        defaults.set(isHidden, forKey: "isHidden")
                    }
                }
            }
            Divider()
            HStack{
                Button("Start new session"){
                    Model.shared.mainController?.offerSDP()
                } .contentShape(Rectangle())
                Button("New Tracks"){
                    Model.shared.mainController?.startTracks()
                } .contentShape(Rectangle())
            }
            HStack{
                MeView()
                GeometryReader{ g in
                    YouView().onAppear(){
                        Model.shared.videoWidth = g.size.width
                        Model.shared.videoHeight = g.size.height
                        
                        // we simulate two peers
                        Model.shared.webRtcClientA = WebRTCClient(iceServers: [Global.STUN_SERVER], id:0) // left
                        //Model.shared.webRtcClientB = WebRTCClient(iceServers: [Global.STUN_SERVER], id:1) // right
                        setupWebRTC()
                    }
                }
            }
            TextField("Debug", text: $debugStr,  axis: .vertical).lineLimit(5...10)
            Spacer()
            
            Text("Session Id: \(sessionId)").font(.system(size: 9))
            HStack(){
                Picker(selection: $selectedVideoIn.onChange(videoInChanged), label:Text("Camera")) {
                    ForEach(videoInOptions, id: \.self) {
                        Text($0)
                    }
                }.pickerStyle(.menu).frame(maxWidth:220)
                
                Picker(selection: $selectedAudioIn.onChange(audioInChanged), label:Text("Audio In")) {
                    ForEach(audioInOptions, id: \.self) {
                        Text($0)
                    }
                }.pickerStyle(.menu).frame(maxWidth:220)
                
                Picker(selection: $selectedAudioOut.onChange(audioOutChanged), label:Text("Audio Out")) {
                    ForEach(audioOutOptions, id: \.self) {
                        Text($0)
                    }
                }.pickerStyle(.menu).frame(maxWidth:220)
            }
            
        }.padding()
        .onAppear(){
            if defaults.string(forKey: "appId") == nil{
                defaults.set("https://rtc.live.cloudflare.com/v1", forKey: "serverURL")
                defaults.set("", forKey: "appId")
                defaults.set("", forKey: "appSecret")
                defaults.set(false, forKey: "isHidden")
            }
            serverURL = defaults.string(forKey: "serverURL")!
            appId = defaults.string(forKey: "appId")!
            appSecret = defaults.string(forKey: "appSecret")!
            isHidden = defaults.bool(forKey: "isHidden")
            print(serverURL)
            print(appId)
            print(appSecret)
            Model.shared.api.configure(serverUrl: serverURL, appId: appId, secret: appSecret)
            AudioDeviceManager().setupAudio()
            VideoDevices().findDevices()
            
            updateDevies()
        }
        .onReceive(timer) { input in
            let m = Model.shared
            sessionId = m.sessionId
            hasConfig = m.hasConfig ? "✅" : "❌"
            signal = m.signalIndicator
            hasSDPLocal = m.hasSDPLocal
            hasSDPRemote = m.hasSDPRemote
            isConnected = m.isConnected ? "✅" : "❌"
            isLoggedOn = m.isLoggedOn ? "✅" : "❌"
            errorMsg = m.errorMsg
          }
    }
}
