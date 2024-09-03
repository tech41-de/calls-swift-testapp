//
//  SignalClient.swift
//  calls-swift-testApp
//
//  Created by mat on 8/28/24.
//

import Foundation
import Starscream

class SignalClient : WebSocketDelegate{
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    let model : Model
    let controller : Controller
    
    init(model:Model, controller:Controller){
        self.model = model
        self.controller = controller
    }
    
    var isConnected = false
    var socket : WebSocket?
    
    func handleError(_ error:Error?){
        print(error ?? "")
    }
    
    func send(req: SignalReq){
        do{
            let data = try encoder.encode(req)
            let str = String(decoding: data, as: UTF8.self)
            send(msg:str)
        }
        catch{
            print(error)
        }
        
    }
    
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        print(event)
        switch event {
            case .connected(let headers):
                isConnected = true
                model.isSignalConnectd = true
                print("websocket is connected: \(headers)")
            
            case .disconnected(let reason, let code):
                isConnected = false
            model.isSignalConnectd = false
                print("websocket is disconnected: \(reason) with code: \(code)")
            
            case .text(let string):
                print("Received text: \(string)")
           
            do{
                let data = string.data(using: .utf8) // non-nil
                let res = try decoder.decode(SignalRes.self, from: data!)
                if res.cmd == "invite" && res.session.sessionId != model.sessionId{
                    DispatchQueue.main.async {
                        self.model.sessionIdRemote = res.session.sessionId
                        self.model.trackIdAudioRemote = res.session.tracks[0].trackId
                        self.model.trackIdVideoRemote = res.session.tracks[1].trackId
                        self.model.dataChannelNameRemote = res.session.tracks[2].trackId
                        self.controller.setRemoteTracks()
                        self.controller.sendUpdateSignal(receiver: "")
                    }
                }
                if res.cmd == "update" && res.session.sessionId != model.sessionId{
                    DispatchQueue.main.async {
                        self.model.sessionIdRemote = res.session.sessionId
                        self.model.trackIdAudioRemote = res.session.tracks[0].trackId
                        self.model.trackIdVideoRemote = res.session.tracks[1].trackId
                        self.model.dataChannelNameRemote = res.session.tracks[2].trackId
                        self.controller.setRemoteTracks()
                    }
                }
                if res.cmd == "updateVideo" && res.session.sessionId != model.sessionId{
                    DispatchQueue.main.async {
                        self.model.sessionIdRemote = res.session.sessionId
                        self.model.trackIdVideoRemote = res.session.tracks[0].trackId
                        self.controller.updateVideoTrack(mid:res.session.tracks[0].mid)
                    }
                }
            }catch{
                print(error)
            }
            
            case .binary(let data):
                print("Received data: \(data.count)")
            
            case .ping(_):
                break
            
            case .pong(_):
                break
            
            case .viabilityChanged(_):
                break
            
            case .reconnectSuggested(_):
                break
            
            case .cancelled:
                isConnected = false
                 model.isSignalConnectd = false
            
            case .error(let error):
                isConnected = false
                handleError(error)
                case .peerClosed:
                       break
            }
    }
    
    func send(msg:String){
        socket!.write(string: msg){
        }
    }
    
    func invite(room:String){
        var roomParsed = room.lowercased()
        var shortStr : String.SubSequence
        if roomParsed.count > 32{
            let index = roomParsed.index(roomParsed.startIndex, offsetBy: 32)
            shortStr = roomParsed.prefix(upTo: index)
            roomParsed = (String(shortStr))
        }
        roomParsed = roomParsed.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let uri = "wss://api.pcalls.net/v0/invite/" + roomParsed + "/websocket"
        print(uri)
        let request = URLRequest(url: URL(string: uri)!)
        socket = WebSocket(request:request)
        socket!.delegate = self
        socket!.connect()
    }
    
    deinit {
      socket!.disconnect()
      socket!.delegate = nil
    }
}

