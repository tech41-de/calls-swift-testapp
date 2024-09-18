//
//  ContentView.swift
//  calls-swift-testApp
//
//  Created by mat on 8/22/24.
//

import SwiftUI
@preconcurrency import WebRTC
import Calls_Swift

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
    @EnvironmentObject var m : Model
    @EnvironmentObject var controller : Controller
    @EnvironmentObject var stm : STM

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
    @State var hasSDPLocal = "❌"
    @State var hasSDPRemote = "❌"
    @State var isConnected = "❌"
    @State var hasConfig = "❌"
    @State var isLoggedOn = "❌"
    @State var hasRemoteTracks = "❌"
    @State var sessionId = ""
    @State var remoteDataChannelName = ""
    @State var localDataChannelName = ""
    @State var trackMid = ""
    @State var sessionData = ""
    @State var sessionIdRemoteData = ""
    @State var isSignalConnectd = "❌"
    @State var room = "shack"
    @State var ChatSend = ""
    @State var chatReceived = ""
    @State var pongLatency = ""
    @State var chooseFile = false
    @State var filePath = ""
    @State var fileUrl :URL?
    @State var closeTrackForceFlag  = false
    @State var isYouViewPortrait  = true
    
    @State var sdpOffer = "offer"
    @State var sdpAnswer = "answer"
    
    func getSession(){
        Task{
            await m.api.getSession(sessionId: m.sessionId){res, error in
                if(error.count > 0){
                    print(error)
                    return
                }
                sessionData = ""
                var tracks = ""
                for t  in res!.tracks{
                    if t.location == "local"{
                        tracks += "trackName:" + t.trackName! + " location:" + t.location! + " mid:" + t.mid! +  "\n"
                    }else{
                        tracks += "trackName:" + t.trackName! + " location:" + t.location! + " sessionId:" + t.sessionId! + "\n"
                    }
                }
                var dataChannel = ""
                for d  in res!.dataChannels{
                    if d.location == "local"{
                        dataChannel += "dataChannelName:" + d.dataChannelName! + " id:" + String(d.id)  + " location:" + d.location! + " status:" + d.status! +  "\n"
                    }else{
                        dataChannel += "dataChannelName:" + d.dataChannelName! + " id:" + String(d.id)  + " location:" + d.location! + " sessionId:" + d.sessionId! + " status:" + d.status! + "\n"
                    }
                }
                sessionData = tracks + dataChannel
            }
        }
    }


    let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    let defaults = UserDefaults.standard

    func videoInChanged(_ tag: String) {
        m.camera = tag
        UserDefaults.standard.set(tag, forKey: "videoIn")
        controller.updateCameraInputDevice(name: tag)
    }
    
    func audioInChanged(_ tag: String) {
        controller.updateAudioInputDevice(name: tag)
    }
    
    func audioOutChanged(_ tag: String) {
        controller.updateAudioOutputDevice(name: tag)
    }

    var body: some View {
        let fontSize:CGFloat = 9
        
        ScrollView(.vertical){
        VStack(alignment: .leading, spacing:5){
            
            // Configuration
            HStack{
                Button(isHidden ? "conf" : "video"){
                    isHidden = !isHidden
                    defaults.set(isHidden, forKey: "isHidden")
                }.buttonStyle(MyButtonStyle())
                
                Text("\(hasSDPLocal)").font(.system(size: fontSize))
                Text("\(hasSDPRemote)").font(.system(size: fontSize))
                Text("\(isConnected)").font(.system(size: fontSize))
                Text("\(isSignalConnectd)").font(.system(size: fontSize))
                Text("\(hasRemoteTracks)").font(.system(size: fontSize))
                Spacer()
                Button("Enter"){
                    if m.currentstate == .START_STREAM || m.currentstate == .RUNNING{
                        m.room = room
                        stm.exec(state: .START_SESSION)
                    }
                }.buttonStyle(MyButtonStyle())
                Text(":")
                TextField("room", text: $room).disableAutocorrection(true)
                Spacer()
                Button("Home"){
                    
                    m.displayMode = DisplayMode.HOME
                }.buttonStyle(MyButtonStyle()).border(.yellow, width:  m.displayMode == .HOME ? 2 : 0)
                Button("Debug"){
                    m.displayMode = .DEBUG
                }.buttonStyle(MyButtonStyle()).border(.yellow, width:  m.displayMode == .DEBUG ? 2 : 0)
                Button("SDP Offer"){
                    Task{
                        await controller.rtc?.getOfffer{sdp in
                            sdpOffer = sdp?.sdp ?? ""
                        }
                    }
                    m.displayMode = .OFFER
                }.buttonStyle(MyButtonStyle()).border(.yellow, width:  m.displayMode == .OFFER ? 2 : 0)
                Button("SDP Answer"){
                    m.displayMode = .ANSWER
                }.buttonStyle(MyButtonStyle()).border(.yellow, width:  m.displayMode == .ANSWER ? 2 : 0)
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
                        stm.exec(state: .CONFIGURE)
                    }.buttonStyle(MyButtonStyle())
                }
            }
            Divider()
            
            // Video Views
            if isHidden{
                ZStack{
                    GeometryReader{ g in
                        let width = g.size.width / 2 - 2
                        MeView(model:m, width:width).scaleEffect(x: -1, y: 1).frame(width:width).offset(x:0)
                        Divider().frame(width:2)
                        let w = isYouViewPortrait ? width * 9 / 15 :  width
                        let h = g.size.height
                        YouView(model:m, width:width, height : h).frame(width:w).offset(x:width)
                            .onAppear(){
                                if isYouViewPortrait{
                                   
                                }else{
                                    m.videoWidth = g.size.width / 2
                                    m.videoHeight = g.size.height
                                }
                            }
                    }
                }.frame(minHeight:200, maxHeight:300)
            }
            
            // Debug Fields Start
            if m.displayMode == .DEBUG{
                // Tracks
                VStack{
                    Text("Local Tracks")
                    
                    HStack{
                        TextField("Session Id Local", text: $sessionId).textSelection(.enabled).font(.system(size: 11))
                        Text("Session Id").font(.system(size: 11))
                    }
                    
                    HStack{
                        TextField("Track Id Audio Local", text: $localAudioTrackId).textSelection(.enabled).font(.system(size: 11))
                        Text("Track ID Audio ").font(.system(size: 11))
                    }
                    
                    HStack{
                        TextField("Track Id Video Local", text: $localVideoTrackId).textSelection(.enabled).font(.system(size: 11))
                        Text("Track ID Video").font(.system(size: 11))
                    }
                    
                    HStack{
                        TextField("Track Id Data Local", text: $localDataChannelName).textSelection(.enabled).font(.system(size: 11))
                        Text("Track ID Data").font(.system(size: 11))
                    }
                    
                }.padding(5).border(.gray, width: 1)
                
                // Remote
                VStack{
                    Text("Remote Tracks")

                    HStack{
                        TextField("Session Id Remote", text: $sessionIdRemote).textSelection(.enabled).font(.system(size: 11))
                        Text("Session Id").font(.system(size: 11))
                    }
                    HStack{
                        TextField("Track ID Audio", text: $trackIdAudioRemote).textSelection(.enabled).font(.system(size: 11))
                        Text("Track ID Audio ").font(.system(size: 11))
                    }
                    HStack{
                        TextField("Track ID Video", text: $trackIdVideoRemote).textSelection(.enabled).font(.system(size: 11))
                        Text("Track ID Video").font(.system(size: 11))
                    }
                    HStack{
                        TextField("Track Id Remote Data", text: $remoteDataChannelName).textSelection(.enabled).font(.system(size: 11))
                        Text("Track ID Data").font(.system(size: 11))
                    }
                }.padding(5).border(.gray, width: 1)
                
                // Session
                VStack{
                    VStack{
                        Text("Session")
                        Button("Get Session"){
                            if m.sessionId != ""{
                                getSession()
                            }
                        }.buttonStyle(MyButtonStyle())
                        
                        TextField("sessionData", text: $sessionData, axis: .vertical).textSelection(.enabled).lineLimit(6, reservesSpace: true).font(.system(size: 11))
                    }.padding(5).border(.gray, width: 1)
                    Spacer()
                    
                    // Remove Track
                    VStack{
                        Text("Close Track")
                        HStack{
                            Text("mid")
                            TextField("mid", text: $trackMid).textSelection(.enabled)
                            Spacer()
                            Toggle("force", isOn: $closeTrackForceFlag).frame(width:100)
                            Button("Close"){
                                if m.sessionId != ""{
                                    Task{
                                        await controller.rtc!.removeTrack(mid: trackMid)
                                        await controller.rtc!.getOfffer(){ sdp in
                                            Task{
                                                let desc = Calls.SessionDescription(type:"offer", sdp:sdp!.sdp)
                                                let local = Calls.CloseTrackObject(mid: trackMid)
                                        
                                                let closeTacksRequest = Calls.CloseTracksRequest(tracks: [local], sessionDescription:desc, force : closeTrackForceFlag)
                                                await self.m.api.close(sessionId: self.m.sessionId, closeTracksRequest: closeTacksRequest){res, error in
                                                    if(error.count > 0){
                                                        print(error)
                                                        return
                                                    }
                                                    
                                                    if res!.requiresImmediateRenegotiation{
                                                        Task{
                                                            await controller.rtc!.renegotiate()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }.buttonStyle(MyButtonStyle())
                        }
                    }.padding(5).border(.gray, width: 1)
                }
            }
            
            // Offer Fields Start =============================================
            if m.displayMode == .OFFER{
                VStack{
                    Text("Offer")
                    ScrollView(.vertical, showsIndicators: true){
                        TextField("", text: $sdpOffer, axis: .vertical)
                            .textSelection(.disabled)
                            .disableAutocorrection(true)
                            .lineLimit(200, reservesSpace: false)
                            .multilineTextAlignment(.leading)
                    }
                }.padding(5).border(.gray, width: 1)
            }
            
            // Answer Fields Start
            if m.displayMode == .ANSWER{
                VStack{
                    Text("Answer")
                    Button("Set"){
                        Task{
                            
                        }
                    }.buttonStyle(MyButtonStyle())
                    ScrollView(.vertical, showsIndicators: true){
                        TextField("", text: $sdpAnswer, axis: .vertical)
                            .textSelection(.disabled)
                            .disableAutocorrection(true)
                            .lineLimit(200, reservesSpace: true)
                            .multilineTextAlignment(.leading)
                        
                      
                    }
                }.padding(5).border(.gray, width: 1)
            }
            if m.displayMode == .HOME || m.displayMode == .DEBUG {
                VStack{
                    Text("Chat")
                    HStack{
                        ScrollView(.vertical){
                            TextField("", text: $chatReceived, axis: .vertical)
                                .textSelection(.disabled)
                                .disableAutocorrection(true)
                                .lineLimit(8, reservesSpace: true)
                                .multilineTextAlignment(.leading)
                        }
                        
                    }
                }.padding(5).border(.gray, width: 1)
                HStack{
                    TextField("chat", text: $ChatSend)
                        .textSelection(.enabled)
                        .disableAutocorrection(true)
                    Button("Send"){
                        if ChatSend.count == 0{
                            return // don't send empty lines
                        }
                        Task{
                            controller.chatSend(text:ChatSend)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                m.chatReceived += ChatSend + "\n"
                                chatReceived = m.chatReceived
                                ChatSend = ""
                            }
                        }
                    }.buttonStyle(MyButtonStyle())
                }
                HStack{
                    Text("Ping")
                    Button("Send"){
                        controller.ping()
                    }.buttonStyle(MyButtonStyle())
                    Text(pongLatency)
                }
            }
            Spacer()
            HStack(){
                Picker(selection: $m.camera.onChange(videoInChanged), label:Text("Camera")) {
                    ForEach(m.videoDevices, id: \.self) {
                        Text($0.name).tag($0.name)
                    }
                }.pickerStyle(.menu).frame(maxWidth:220)

                Picker(selection: $m.audioInName.onChange(audioInChanged), label:Text("Audio In")) {
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
    }
        .onAppear(){
            if defaults.string(forKey: "serverURL") == nil{
                defaults.setValue("https://rtc.live.cloudflare.com/v1/apps/", forKey: "serverURL")
                defaults.setValue("", forKey: "appId")
                defaults.setValue("", forKey: "appSecret")
                defaults.setValue(false, forKey: "isHidden")
            }
            serverURL = defaults.string(forKey: "serverURL")!
            appId = defaults.string(forKey: "appId")!
            appSecret = defaults.string(forKey: "appSecret")!
            isHidden = defaults.bool(forKey: "isHidden")
            
            stm.exec(state: .BOOT)
        }
        .onReceive(timer) { input in
           
            // flags
            hasConfig = m.hasConfig ? "✅" : "❌"
            hasSDPLocal = m.hasSDPLocal
            hasSDPRemote = m.hasSDPRemote
            isConnected = m.isConnected ? "✅" : "❌"
            isLoggedOn = m.isLoggedOn ? "✅" : "❌"
            hasRemoteTracks = m.hasRemoteTracks
            isSignalConnectd = m.isSignalConnectd ? "✅" : "❌"
            
            // locals
            sessionId = m.sessionId
            localVideoTrackId = m.localVideoTrackId
            localAudioTrackId = m.localAudioTrackId
            localDataChannelName = m.dataChannelNameLocal
            
            // remotes
            sessionIdRemote = m.sessionIdRemote
            trackIdAudioRemote = m.trackIdAudioRemote
            trackIdVideoRemote = m.trackIdVideoRemote
            remoteDataChannelName = m.dataChannelNameRemote
            chatReceived = m.chatReceived
            pongLatency = "\(Double(m.pongLatency) / 1000.0) sec"
          }
    }
}
