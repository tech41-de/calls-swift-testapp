//
//  Controller.swift
//  RSession2
//
//  Created by mat on 8/11/24.
//

import SwiftUI
import WebRTC
import Calls_Swift

class Controller : ObservableObject{
    let BLOCKSIZE = 1500
    let jsonDecoder = JSONDecoder()
    let jsonEncoder = JSONEncoder()
    
    var model : Model?
    var signalClient : SignalClient?
    var webRtcClient : WebRTC_Client?
    var stm : STM?
    var jobId :Int32 = 0
    var pingSendAt = 0
    
    init(){
        
    }
    
    func setup(model:Model, stm:STM, signalClient: SignalClient){
        self.model = model
        self.signalClient = signalClient
        self.stm = stm
        webRtcClient =  WebRTC_Client()
        webRtcClient!.setup(model: model, stm: stm, controller : self)
    }

    func setRemoteTracks(){
        Task{
            await webRtcClient!.remoteTracks()
        }
    }
    
    func chatSend(text:String){
        Task{
            do{
                let chatMsg = ChatMsg(text: text)
                let msg = ChannelMsg(type: .chat, sender: model!.sessionId, reciever: "", obj: chatMsg, sendDate: Int(Date().timeIntervalSince1970 * 1000.0))
                let datas = try jsonEncoder.encode(msg)
                let jsons = String(decoding: datas, as: UTF8.self)
                webRtcClient!.sendText(json: jsons)
            }
            catch{
                print(error)
            }
        }
    }
    
    func handleBinary(data:Data){

    }
    
    func handle(json:String){
        do{
            let data = json.data(using: .utf8)
            let msg : ChannelMsg = try jsonDecoder.decode(ChannelMsg.self, from:data! )
            switch(msg.type){
                
            case .chat:
                let chatMsg = msg.obj as? ChatMsg
                DispatchQueue.main.async {
                    print(self.model ?? "")
                    self.model!.chatReceived += chatMsg!.text + "\n"
                }
                break
                
            case .ping:
                Task{
                    pingSendAt = Int(Date().timeIntervalSince1970 * 1000.0)
                    let msg = ChannelMsg(type: .pong, sender: self.model!.sessionId, reciever: "", obj: PongMsg(), sendDate:pingSendAt)
                    sendMsg(msg:msg)
                }
                break
                
            case .pong:
                DispatchQueue.main.async {
                    let now = Int(Date().timeIntervalSince1970 * 1000.0)
                    self.model!.pongLatency = now - msg.sendDate
                }
                break
 
            }
        }catch{
            print(error)
        }
    }
    
    func ping(){
        let msg = ChannelMsg(type: .ping, sender: model!.sessionId, reciever: "", obj: PingMsg(), sendDate:Int(Date().timeIntervalSince1970))
        sendMsg(msg:msg)
    }

    func sendMsg(msg:ChannelMsg){
        Task{
            do{
                let data = try jsonEncoder.encode(msg)
                let json = String(decoding: data, as: UTF8.self)
                webRtcClient!.sendText(json: json)
            }
            catch{
                print(error)
            }
        }
    }
    
    func sendInviteSignal(){
        let session = Session(sessionId: model!.sessionId, tracks:model!.tracks, room: model!.room)
        let req = SignalReq(cmd:"invite" ,receiver:"", session:session )
        signalClient!.send(req: req)
    }
    
    func sendUpdateSignal(receiver:String){
        let session = Session(sessionId: model!.sessionId, tracks:model!.tracks, room: model!.room)
        let req = SignalReq(cmd:"update", receiver:receiver, session:session )
        signalClient!.send(req: req)
    }
    
    func updateCameraInputDevice(name:String){
     print("Setting Camera \(name)")
        stm!.exec(state: .START_STREAM)
    }
    
    func updateAudioInputDevice(name:String){
        guard let device = model!.getAudioInDevice(name: name)else{
            return
        }
        model!.audioInDevice = name
        UserDefaults.standard.set(name, forKey: "audioIn")
        AudioDeviceManager(model:model!).setInputDevice(name:name)
    }
    
    func updateAudioOutputDevice(name:String){
        guard let device = model!.getAudioInDevice(name: name)else{
            return
        }
        model!.audioOutDevice = name
        UserDefaults.standard.set(name, forKey: "audioOut")
        AudioDeviceManager(model:model!).setOutputDevice(uid: device.id)
    }
}
