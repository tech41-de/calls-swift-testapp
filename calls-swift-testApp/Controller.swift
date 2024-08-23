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
    
    func updateAudioInputDevice(name:String){
        guard let device = Model.shared.getAudioInDevice(name: name)else{
            return
        }
        Model.shared.audioInDevice = name
        UserDefaults.standard.set(name, forKey: "audioIn")
#if os(macOS)
        AudioDeviceManager().setInputDevice(uid: device.uid)
#else
        AudioDeviceManager().setInputDevice(name: name)
#endif
        Model.shared.webRtcClientA!.updateAudioInputDevice()
    }
    
    func updateAudioOutputDevice(name:String){
        guard let device = Model.shared.getAudioInDevice(name: name)else{
            return
        }
        Model.shared.audioOutDevice = name
        UserDefaults.standard.set(name, forKey: "audioOut")
#if os(macOS)
        AudioDeviceManager().setOutputDevice(uid: device.uid)
#else
        AudioDeviceManager().setOutputDevice(name: name)
#endif
        Model.shared.webRtcClientA!.updateAudioOutputDevice()
    }
}
