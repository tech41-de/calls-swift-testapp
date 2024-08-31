//
//  ContentView.swift
//  calls-swift-testApp
//
//  Created by mat on 8/22/24.
//

import SwiftUI
import WebRTC
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
    
    func getSession(){
        Task{
            await Model.shared.api.getSession(sessionId: Model.shared.sessionId){res, error in
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
                print(sessionData)
            }
        }
    }


    let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
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
            
            // Configuration
            HStack{
                Button(isHidden ? "show config" : "hide config"){
                    isHidden = !isHidden
                    defaults.set(isHidden, forKey: "isHidden")
                }.buttonStyle(MyButtonStyle())
                
                Text("\(isSignalConnectd)").font(.system(size: fontSize))
                Text("\(hasSDPLocal)").font(.system(size: fontSize))
                Text("\(hasSDPRemote)").font(.system(size: fontSize))
                Text("\(isConnected)").font(.system(size: fontSize))
                Text("\(hasRemoteTracks)").font(.system(size: fontSize))
                Spacer()
                Button("Enter Room"){
                    Model.shared.room = room
                    print(room)
                    STM.shared.exec(state: .START_SESSION)
                } .buttonStyle(MyButtonStyle())
                Text(":")
                TextField("room", text: $room).disableAutocorrection(true)
                Spacer()
                Button(Model.shared.isDebug ? "hide" : "show"){
                    Model.shared.isDebug =  !Model.shared.isDebug
                }.buttonStyle(MyButtonStyle())
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
            
            // Video Views
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
            
            // Debug Fields Start
            if Model.shared.isDebug{
                // Tracks
                VStack{
                    Text("Local Tracks")
                    
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
                    
                    HStack{
                        TextField("Track Id Data Local", text: $localDataChannelName).textSelection(.enabled)
                        Text("Track ID Data")
                    }
                    
                }.padding(5).border(.gray, width: 1)
                
                // Remote
                VStack{
                    Text("Remote Tracks")
                    /*
                     Button("Set Remote Tracks"){
                     Model.shared.sessionIdRemote = sessionIdRemote
                     Model.shared.trackIdAudioRemote = trackIdAudioRemote
                     Model.shared.trackIdVideoRemote = trackIdVideoRemote
                     Model.shared.dataChannelNameRemote = remoteDataChannelName
                     Controller().setRemoteTracks()
                     }.buttonStyle(MyButtonStyle())
                     */
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
                    HStack{
                        TextField("Track Id Remote Data", text: $remoteDataChannelName).textSelection(.enabled)
                        Text("Track ID Data")
                    }
                }.padding(5).border(.gray, width: 1)
                
                // Session
                VStack{
                    VStack{
                        Text("Session")
                        Button("Get Session"){
                            if Model.shared.sessionId == ""{
                                return
                            }
                            getSession()
                        }.buttonStyle(MyButtonStyle())
                        
                        TextField("sessionData", text: $sessionData, axis: .vertical).textSelection(.enabled).lineLimit(6, reservesSpace: true).font(.system(size: 11))
                    }.padding(5).border(.gray, width: 1)
                    Spacer()
                    
                    // Remove Track
                    VStack{
                        Text("Close Track")
                        Button("Close"){
                            if Model.shared.sessionId.count == 0{
                                return
                            }
                            Task{
                                await Model.shared.webRtcClient.getOfffer(){ sdp in
                                    Task{
                                        let desc = Calls.SessionDescription(type:"offer", sdp:sdp!.sdp)
                                        let local = Calls.CloseTrackObject(mid: trackMid)
                                        print(trackMid)
                                        let closeTacksRequest = Calls.CloseTracksRequest(tracks: [local], sessionDescription:desc, force : false)
                                        await Model.shared.api.close(sessionId: Model.shared.sessionId, closeTracksRequest: closeTacksRequest){res, error in
                                            if(error.count > 0){
                                                print(error)
                                                return
                                            }
                                            print(error)
                                            for t in res!.tracks{
                                                print(t)
                                            }
                                        }
                                    }
                                }
                            }
                        }.buttonStyle(MyButtonStyle())
                        HStack{
                            TextField("mid", text: $trackMid).textSelection(.enabled)
                            Text("mid")
                        }
                    }.padding(5).border(.gray, width: 1)
                }
            }
            
            VStack{
                Text("File Transfer")
                
                HStack{
                    TextField("file path", text: $filePath).textSelection(.enabled)
                    Button("Choose"){
                        chooseFile = true
                    }.buttonStyle(MyButtonStyle())
                    
                    Button("Send"){
                        if fileUrl != nil{
                            Controller.shared.sendFile(url:fileUrl!)
                        }
                    }.buttonStyle(MyButtonStyle())
                    
                }
            }.padding(5).border(.gray, width: 1)
                .fileImporter(isPresented: $chooseFile, allowedContentTypes: [.item]) { result in
                    switch result {
                    case .success(let f):
                        fileUrl = f
                        filePath = f.path
                    case .failure(let error):
                        print(error)
                    }
                }
            
            VStack{
                Text("Chat")
                HStack{
                    ScrollView(.vertical){
                        TextField("", text: $chatReceived, axis: .vertical)
                            .textSelection(.enabled)
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
                        Controller.shared.chatSend(text:ChatSend)
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
                    Controller.shared.ping()
                }.buttonStyle(MyButtonStyle())
            Text(pongLatency)
            }
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
            //let data: Data? = TestStuff().msgString.data(using: .utf8) // non-nil
            //let movieObj = try? JSONDecoder().decode(Calls.GetSessionStateResponse.self, from: data!)
            
            STM.shared.exec(state: .BOOT)
            serverURL = defaults.string(forKey: "serverURL")!
            appId = defaults.string(forKey: "appId")!
            appSecret = defaults.string(forKey: "appSecret")!
            isHidden = defaults.bool(forKey: "isHidden")
        }
        .onReceive(timer) { input in
            let m = Model.shared
           
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
