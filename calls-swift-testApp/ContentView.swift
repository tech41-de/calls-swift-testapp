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

    @State var localVideoTrackId = ""
    @State var localAudioTrackId = ""
    @State var trackIdVideoRemote = ""
    @State var trackIdAudioRemote = ""
    @State var sessionIdRemote = ""
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
    @State var hasRemoteTracks = "❌"
    @State var sessionId = ""

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
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

    var body: some View {
        let fontSize:CGFloat = 9
        VStack(alignment: .leading, spacing:5){
            HStack{
                Button(isHidden ? "show config" : "hide config"){
                    isHidden = !isHidden
                    defaults.set(isHidden, forKey: "isHidden")
                }.buttonStyle(MyButtonStyle())
                Text("\(hasSDPLocal)").font(.system(size: fontSize))
                Text("\(hasSDPRemote)").font(.system(size: fontSize))
                Text("\(isConnected)").font(.system(size: fontSize))
                Text("\(hasRemoteTracks)").font(.system(size: fontSize))
            }
           
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
            
            if isHidden{
                ZStack{
                    GeometryReader{ g in
                        let width = g.size.width / 2 - 2
                        MeView(width:width).scaleEffect(x: -1, y: 1).frame(width:width).offset(x:0)
                        Divider().frame(width:2)
                        YouView(width:width).frame(width:width).offset(x:width)
                            .onAppear(){
                            Model.shared.videoWidth = g.size.width / 2
                            Model.shared.videoHeight = g.size.height
                        }
                    }
                }.frame(maxHeight:300)
            }

            VStack{
                Text("Local Tracks")
                Button("Start new session"){
                    STM.shared.exec(state: .START_SESSION)
                } .buttonStyle(MyButtonStyle())
                HStack{
                    TextField("Session Id Local", text: $sessionId).textSelection(.enabled)
                    Text("Session Id")
                }
                
                HStack{
                    TextField("Track Id Audio Local", text: $localAudioTrackId).textSelection(.enabled)
                    Text("Track ID Audio ")
                }
                
                HStack{
                    TextField("Track Id Video Local", text: $localVideoTrackId).textSelection(.enabled)
                    Text("Track ID Video")
                }
                
            }.padding(5).border(.gray, width: 1)
      
            VStack{
                Text("Remote Tracks")
                Button("Set Remote Tracks"){
                    Model.shared.sessionIdRemote = sessionIdRemote
                    Model.shared.trackIdAudioRemote = trackIdAudioRemote
                    Model.shared.trackIdVideoRemote = trackIdVideoRemote

                    Task{
                        await m.webRtcClient.remoteTracks()
                    }
                }.buttonStyle(MyButtonStyle())
                HStack{
                    TextField("Session Id Remote", text: $sessionIdRemote).textSelection(.enabled)
                    Text("Session Id")
                }
                HStack{
                    TextField("Track ID Audio", text: $trackIdAudioRemote).textSelection(.enabled)
                    Text("Track ID Audio ")
                }
                HStack{
                    TextField("Track ID Video", text: $trackIdVideoRemote).textSelection(.enabled)
                    Text("Track ID Video")
                }
            }.padding(5).border(.gray, width: 1)
            Spacer()
            
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
            localVideoTrackId = m.localVideoTrackId
            localAudioTrackId = m.localAudioTrackId
            hasRemoteTracks = m.hasRemoteTracks
          }
    }
}
