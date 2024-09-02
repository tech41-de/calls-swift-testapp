//
//  ChannelDataReceiver.swift
//  calls-swift-testApp
//
//  Created by mat on 8/30/24.
//

import Foundation
import WebRTC

/*
 Receives Data from other Peers, Chat....
 */
class ChannelDataReceiver : NSObject, RTCDataChannelDelegate{
    
    let controller : Controller
    
    init(controller : Controller){
        self.controller = controller
    }
    
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("dataChannelDidChangeState")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        if buffer.isBinary{
            controller.handleBinary(data:  buffer.data)
        }else{
            let json = String(decoding: buffer.data, as: UTF8.self)
            controller.handle(json: json)
        }
    }
}
