//
//  STM.swift
//  calls-swift-testApp
//
//  Created by mat on 8/24/24.
//

import Foundation

class STM : ObservableObject, StateExecutor{

    @Service var model: Model
    @Service var controller: Controller
    @Service var signalClient: SignalClient

    let defaults = UserDefaults.standard
    
    func exec(state:States){
        if (state == model.currentstate ){
            return
        }
        Task{@MainActor in
            self.model.currentstate = state
        }
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
            DispatchQueue.main.async { [self] in
                AudioDeviceManager().setup()
                exec(state: .VIDEOO_SETUP)
            }
            break
            
        case .VIDEOO_SETUP:
            DispatchQueue.main.async { [self] in
                VideoDeviceManager(model:model).setup()
                exec(state: .START_PEER)
            }
           
            break
            
        case .START_PEER:
            Task{
                await controller.rtc!.setupPeer()
            }
            break

        case .START_SESSION: // fired from New Session Buttton
            Task{
                await controller.rtc!.newSession()
            }
            break
            
        case .NEW_LOCAL_TRACKS:
            Task{
                await controller.rtc!.localTracks(deviceId: Model.getInstance().audioInDevice!.uid)
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
                // We are signaling the tracks as remote tracks
                var tracks = [Track]()
                for track in model.tracks{
                    if track.type == "local"{
                        let trackCopy = Track(trackId:track.trackId, mid: track.mid, type: "remote", kind: track.kind)
                        tracks.append(trackCopy)
                    }
                }
                let session = Session(sessionId: model.sessionId, tracks:tracks, room: model.room)
                let req = SignalReq(cmd:"invite" ,receiver:"", session:session )
                signalClient.send(req: req)
            }
            break
            
        case  .NEW_REMOTE_TRACKS:
            Task{
                await controller.rtc!.remoteTracks()
            }
            break
            
        case .RUNNING:
            print("Running")
        }
    }
}
