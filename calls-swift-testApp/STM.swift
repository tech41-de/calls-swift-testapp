//
//  STM.swift
//  calls-swift-testApp
//
//  Created by mat on 8/24/24.
//

import Foundation

class STM : ObservableObject, StateExecutor{

    let controller : Controller
    let signalClient : SignalClient
    let model : Model
    
    init(model:Model, controller:Controller, signalClient:SignalClient){
        self.controller = controller
        self.signalClient = signalClient
        self.model = model
    }
   
    let defaults = UserDefaults.standard
    
    func exec(state:States){
        if (state == model.currentstate ){
            return
        }
        model.currentstate = state
        switch(state){
            
        case .COLD:
            break

        case .BOOT:
            if defaults.string(forKey: "appSecret") == nil{
                defaults.set("https://rtc.live.cloudflare.com/v1/apps/", forKey: "serverURL")
                defaults.set("", forKey: "appId")
                defaults.set("", forKey: "appSecret")
                defaults.set(false, forKey: "isHidden")
            }else{
                exec(state: .CONFIGURE)
            }
            break
            
        case .CONFIGURE:
            model.api.configure(serverUrl: defaults.string(forKey: "serverURL")!, appId: defaults.string(forKey: "appId")!, secret: defaults.string(forKey: "appSecret")!)
            exec(state: .AUDIO_SETUP)
            break
            
        case .AUDIO_SETUP:
            AudioDeviceManager(model:model).setup()
            exec(state: .VIDEOO_SETUP)
            break
            
        case .VIDEOO_SETUP:
            DispatchQueue.main.async { [self] in
                VideoDeviceManager(model:model).setup()
                exec(state: .START_STREAM)
            }
           
            break
            
        case .START_STREAM:
            Task{
                await controller.webRtcClient!.setupStream()
            }
            break

        case .START_SESSION: // fired from New Session Buttton
            if(model.room.count < 1){
                return
            }
            Task{
                await controller.webRtcClient!.setupPeer()
            }
            break
        
        case .NEW_SESSION:
            Task{
                await controller.webRtcClient!.newSession()
            }
            break
            
        case .NEW_LOCAL_TRACKS:
            Task{
               await controller.webRtcClient!.localTracks()
            }
            break
            
        case .START_SIGNALING:
            signalClient.invite(room:model.room)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if ( self.model.isSignalConnectd ){
                    self.exec(state:.INVITE)
                }else{
                    self.exec(state:.START_SIGNALING)
                }
            }
            break
            
        case .INVITE:
            Task{
                let session = Session(sessionId: model.sessionId, tracks:model.tracks, room: model.room)
                let req = SignalReq(cmd:"invite" ,receiver:"", session:session )
                signalClient.send(req: req)
            }
            break
            
        case  .NEW_REMOTE_TRACKS:
            Task{
                await controller.webRtcClient!.remoteTracks()
            }
            break
        }
    }
}
