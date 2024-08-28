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
    @State var signal = "❌"
    @State var hasSDPLocal = "❌"
    @State var hasSDPRemote = "❌"
    @State var isConnected = "❌"
    @State var hasConfig = "❌"
    @State var isLoggedOn = "❌"
    @State var hasRemoteTracks = "❌"
    @State var sessionId = ""
    @State var remoteDataChannelId = ""
    @State var localDataChannelId = ""
    @State var trackMid = ""
    @State var sessionData = ""
    @State var sessionIdRemoteData = ""
    @State var isSignalConnectd = "❌"

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

            // Tracks
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
                
                HStack{
                    TextField("Track Id Data Local", text: $localDataChannelId).textSelection(.enabled)
                    Text("Track ID Data")
                }
                
            }.padding(5).border(.gray, width: 1)
      
            // Remote
            VStack{
                Text("Remote Tracks")
                Button("Set Remote Tracks"){
                    Model.shared.sessionIdRemote = sessionIdRemote
                    Model.shared.trackIdAudioRemote = trackIdAudioRemote
                    Model.shared.trackIdVideoRemote = trackIdVideoRemote
                    Model.shared.remoteDataChannelId = remoteDataChannelId

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
                HStack{
                    TextField("Track Id Remote Data", text: $remoteDataChannelId).textSelection(.enabled)
                    Text("Track ID Data")
                }
            }.padding(5).border(.gray, width: 1)
            
            // Data
            VStack{
                Text("Data Track")
                HStack{
                    Button("Send Data"){
                        Task{
                           m.webRtcClient.sendData("Café".data(using: .utf8)!)
                        }
                    }.buttonStyle(MyButtonStyle())
                }
            }.padding(5).border(.gray, width: 1)
            
            // Session
            HStack{
                VStack{
                    Text("Session")
                    Button("Get Session"){
                        if Model.shared.sessionId == ""{
                            return
                        }
                        Task{
                            await Model.shared.api.getSession(sessionId: Model.shared.sessionId){res, error in
                                if(error.count > 0){
                                    print(error)
                                    return
                                }
                                print(error)
                                sessionData = ""
                                for t in res!.tracks{
                                    sessionData += "Track Id: " + t.trackName + " mid: " + t.mid + "\r\n"
                                }
                            }
                        }
                    }.buttonStyle(MyButtonStyle())
                    HStack{
                        Text(sessionData)
                    }
                }.padding(5).border(.gray, width: 1)
                Spacer()
                
                // Remove Track
                VStack{
                    Text("Close Track")
                    Button("Close"){
                        Task{
                            
                            await Model.shared.webRtcClient.getOfffer(){ sdp in
                                Task{
                                    let desc = Calls.SessionDescription(type:"offer", sdp:sdp!.sdp)
                                    let local = Calls.ClosedTrack(mid: trackMid)
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
                }
            }
            
            // Signal
            VStack{
                Text("Signal")
                Button("Send"){
                    Task{
                        let session = Session(sessionId: Model.shared.sessionId, tracks:Model.shared.tracks, room: Model.shared.room)
                        let req = SignalReq(cmd:"room" ,session:session )
                        SignalClient.shared.send(req: req)
                    }
                }.buttonStyle(MyButtonStyle())
                
            }.padding(5).border(.gray, width: 1)
            
            Spacer()
            
            // Footer
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
            SignalClient.shared.start()
        }
        .onReceive(timer) { input in
            let m = Model.shared
           
            hasConfig = m.hasConfig ? "✅" : "❌"
            signal = m.signalIndicator
            hasSDPLocal = m.hasSDPLocal
            hasSDPRemote = m.hasSDPRemote
            isConnected = m.isConnected ? "✅" : "❌"
            isLoggedOn = m.isLoggedOn ? "✅" : "❌"
            hasRemoteTracks = m.hasRemoteTracks
            localDataChannelId = m.localDataChannelId
            isSignalConnectd = m.isSignalConnectd ? "✅" : "❌"
            
            sessionId = m.sessionId
            localVideoTrackId = m.localVideoTrackId
            localAudioTrackId = m.localAudioTrackId
            
            sessionIdRemote = m.sessionIdRemote
            trackIdAudioRemote = m.trackIdAudioRemote
            trackIdVideoRemote = m.trackIdVideoRemote
          }
    }
}
