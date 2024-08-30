//
//  Controller.swift
//  RSession2
//
//  Created by mat on 8/11/24.
//

import SwiftUI

class Controller{
    static let shared = Controller()
    let jsonDecoder = JSONDecoder()
    let jsonEncoder = JSONEncoder()

    func setRemoteTracks(){
        Task{
            await Model.shared.webRtcClient.remoteTracks()
        }
    }
    
    func chatSend(text:String){
        Task{
            do{
                let chatMsg = ChatMsg(text: text)
                let data = try self.jsonEncoder.encode(chatMsg)
                let json = String(decoding: data, as: UTF8.self)
                
                let msg =  ChannelMsg(type: .chat, sender: Model.shared.sessionId, reciever: "", json: json, sendDate: Int(Date().timeIntervalSince1970 * 1000.0))
                let datas = try jsonEncoder.encode(msg)
                let jsons = String(decoding: datas, as: UTF8.self)
                Model.shared.webRtcClient.sendText(json: jsons)
            }
            catch{
                print(error)
            }
        }
    }
    
    var pingSendAt = 0
    
    func handle(json:String){
        do{
            print(json)
            let data = json.data(using: .utf8)
            let msg : ChannelMsg = try jsonDecoder.decode(ChannelMsg.self, from:data! )
            switch(msg.type){
                
            case .chat:
                let data = msg.json.data(using: .utf8)
                let chatMsg = try jsonDecoder.decode(ChatMsg.self, from:data!)
                Model.shared.chatReceived +=   chatMsg.text + "\n"
                break
                
            case .ping:
                Task{
                    pingSendAt = Int(Date().timeIntervalSince1970 * 1000.0)
                    let msg = ChannelMsg(type: .pong, sender: Model.shared.sessionId, reciever: "", json: "", sendDate:pingSendAt)
                    sendMsg(msg:msg)
                }
                break
                
            case .pong:
                DispatchQueue.main.async {
                    let now = Int(Date().timeIntervalSince1970 * 1000.0)
                    Model.shared.pongLatency = now - msg.sendDate
                }
                break
                
            case .file:
                break
            }
        }catch{
            print(error)
        }
    }
    
    func ping(){
        let msg = ChannelMsg(type: .ping, sender: Model.shared.sessionId, reciever: "", json: "", sendDate:Int(Date().timeIntervalSince1970))
        sendMsg(msg:msg)
    }

    func sendMsg(msg:ChannelMsg){
        Task{
            do{
                let data = try jsonEncoder.encode(msg)
                let json = String(decoding: data, as: UTF8.self)
                Model.shared.webRtcClient.sendText(json: json)
            }
            catch{
                print(error)
            }
        }
    }
    
    func sendInviteSignal(){
        let session = Session(sessionId: Model.shared.sessionId, tracks:Model.shared.tracks, room: Model.shared.room)
        let req = SignalReq(cmd:"invite" ,receiver:"", session:session )
        SignalClient.shared.send(req: req)
    }
    
    func sendUpdateSignal(receiver:String){
        let session = Session(sessionId: Model.shared.sessionId, tracks:Model.shared.tracks, room: Model.shared.room)
        let req = SignalReq(cmd:"update", receiver:receiver, session:session )
        SignalClient.shared.send(req: req)
    }
    
    func updateAudioInputDevice(name:String){
        guard let device = Model.shared.getAudioInDevice(name: name)else{
            return
        }
        Model.shared.audioInDevice = name
        UserDefaults.standard.set(name, forKey: "audioIn")
        AudioDeviceManager().setInputDevice(uid: device.id)
    }
    
    func updateAudioOutputDevice(name:String){
        guard let device = Model.shared.getAudioInDevice(name: name)else{
            return
        }
        Model.shared.audioOutDevice = name
        UserDefaults.standard.set(name, forKey: "audioOut")
        AudioDeviceManager().setOutputDevice(uid: device.id)
    }
}
