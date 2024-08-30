//
//  Controller.swift
//  RSession2
//
//  Created by mat on 8/11/24.
//

import SwiftUI

class Controller{
    static let shared = Controller()
    
    func OfferSDP(){
       // WebRtcProxy.shared.mainViewController?.offerSDP()
    }

    func AcceptSDP(){
        //WebRtcProxy.shared.mainViewController?.answerSDP()
    }
    
    func setRemoteTracks(){
        Task{
            await Model.shared.webRtcClient.remoteTracks()
        }
    }
    
    func chatSend(text:String){
        Task{

            await Model.shared.webRtcClient.sendText(text: text)
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
