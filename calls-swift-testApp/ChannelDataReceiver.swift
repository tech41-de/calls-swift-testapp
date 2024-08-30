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
        print("didReceiveMessageWith")
        let str = String(decoding: buffer.data, as: UTF8.self)
        print(str)
    }
    
    
}
