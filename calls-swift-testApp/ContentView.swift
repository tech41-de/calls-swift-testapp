//
//  ContentView.swift
//  calls-swift-testApp
//
//  Created by mat on 8/22/24.
//

import SwiftUI
import WebRTC

struct MyButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(5)
            .foregroundColor(configuration.isPressed ? Color.gray : Color.white)
            .background(configuration.isPressed ? Color.white : Color.gray)
            .cornerRadius(4.0)
    }
}

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
    @ObservedObject var m = Model.shared
    
    @State var sessionIdInvite = ""
    @State var trackNameInvite = ""
    @State var localVideoTrackId = ""
    @State var serverURL = ""
    @State var appId = ""
    @State var appSecret = ""
    @State var isHidden = false
    @State var debugStr = ""
    @State private var signal = "❌"
    @State private var hasSDPLocal = "❌"
    @State private var hasSDPRemote = "❌"
    @State private var isConnected = "❌"
    @State private var hasConfig = "❌"
    @State private var isLoggedOn = "❌"
    @State var errorMsg = ""
    @State var sessionId = ""
    
    let api = CloudflareCallsApi.shared
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    let defaults = UserDefaults.standard
    
    func videoInChanged(_ tag: String) {
        m.camera = tag
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
        Model.shared.webRtcClientA!.renderRemoteVideo(to: remoteRenderer)
    }
     
    var body: some View {
        VStack(alignment: .leading, spacing:5){
            /*@START_MENU_TOKEN@*/Text("Placeholder")/*@END_MENU_TOKEN@*/
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
            }.buttonStyle(MyButtonStyle())
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
                        STM.shared.exec(state: .CONFIGURE)
                    }.buttonStyle(MyButtonStyle())
                }
            }
            Divider()
            
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

            VStack{
                Text("Session")
                Button("Start new session"){
                    Model.shared.mainController?.offerSDP()
                } .buttonStyle(MyButtonStyle())
                TextField("Session Id Local", text: $sessionId).textSelection(.enabled)
                TextField("Track Name Local", text: $localVideoTrackId).textSelection(.enabled)
            }.padding(5).border(.gray, width: 1)
      
            VStack{
                Text("Tracks")
                Button("Set Local Tracks"){
                    Task{
                        await api.SetLocalTracks(sessionId: sessionId, sdp: Model.shared.sdpLocal, mid: "0", trackName: localVideoTrackId)
                    }
                }.buttonStyle(MyButtonStyle())
                Button("Set Remote Tracks"){
                    Task{
                        api.SetRemoteTracks(sessionId:sessionIdInvite, mid:"0", trackName:trackNameInvite)
                    }
                }.buttonStyle(MyButtonStyle())
                TextField("Session Id Remote", text: $sessionIdInvite).textSelection(.enabled)
                TextField("Track Name Remote", text: $trackNameInvite).textSelection(.enabled)
            }.padding(5).border(.gray, width: 1)
            
            TextField("Debug", text: $debugStr,  axis: .vertical).lineLimit(5...10)
            Spacer()
            
            Text("Session Id: \(sessionId)").font(.system(size: 9))
            HStack(){
                Picker(selection: $m.camera.onChange(videoInChanged), label:Text("Camera")) {
                    ForEach(m.videoDevices, id: \.self) {
                        Text($0.name).tag($0.name)
                    }
                }.pickerStyle(.menu).frame(maxWidth:220)
                
                Picker(selection: $m.audioInDevice.onChange(audioInChanged), label:Text("Audio In")) {
                    ForEach(m.audioInDevices, id: \.self) {
                        Text($0.name).tag($0.name)
                    }
                }.pickerStyle(.menu).frame(maxWidth:220)
                
                Picker(selection: $m.audioOutDevice.onChange(audioOutChanged), label:Text("Audio Out")) {
                    ForEach(m.audioOutDevices, id: \.self) {
                        Text($0.name).tag($0.name)
                    }
                }.pickerStyle(.menu).frame(maxWidth:220)
            }
            
        }.padding()
        .onAppear(){
            STM.shared.exec(state: .BOOT)
            serverURL = defaults.string(forKey: "serverURL")!
            appId = defaults.string(forKey: "appId")!
            appSecret = defaults.string(forKey: "appSecret")!
            isHidden = defaults.bool(forKey: "isHidden")
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
            localVideoTrackId = m.localVideoTrackId
          }
    }
}
