//
//  SignalClient.swift
//  calls-swift-testApp
//
//  Created by mat on 8/28/24.
//

import Foundation
import Starscream

class SignalClient : WebSocketDelegate{
    
    static let shared = SignalClient()
    private init(){
        
    }
    
    var isConnected = false
    var socket : WebSocket?
    
    func handleError(_ error:Error?){
        print(error)
    }
    
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        print(event)
        switch event {
            case .connected(let headers):
                isConnected = true
                Model.shared.isSignalConnectd = true
                print("websocket is connected: \(headers)")
            
            case .disconnected(let reason, let code):
                isConnected = false
                Model.shared.isSignalConnectd = false
                print("websocket is disconnected: \(reason) with code: \(code)")
            
            case .text(let string):
                print("Received text: \(string)")
            
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
                Model.shared.isSignalConnectd = false
            
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
    
    
    func start(){
       
        var request = URLRequest(url: URL(string: "wss://api.pcalls.net/websocket")!)
        //request.setValue(["wamp"].joined(separator: ","), forHTTPHeaderField: "Sec-WebSocket-Protocol")
        socket = WebSocket(request:request)
        socket!.delegate = self
        socket!.connect()
    }
    
    deinit {
      socket!.disconnect()
      socket!.delegate = nil
    }
}

