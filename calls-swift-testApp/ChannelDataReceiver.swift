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
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("dataChannelDidChangeState")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        if buffer.isBinary{
            Controller.shared.handleBinary(data:  buffer.data)
        }else{
            let json = String(decoding: buffer.data, as: UTF8.self)
            Controller.shared.handle(json: json)
        }
    }
}
