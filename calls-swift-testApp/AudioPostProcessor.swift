//
//  AudioPostProcessor.swift
//  calls-swift-testApp
//
//  Created by mat on 9/6/24.
//

import Foundation

import Foundation
import WebRTC

class AudioPostProcessor : NSObject, RTCAudioCustomProcessingDelegate{
    
    func audioProcessingInitialize(sampleRate sampleRateHz: Int, channels: Int) {
        print("AudioPostProcessor sampleRate \(sampleRateHz)")
        print("AudioPostProcessor channels \(channels)")
    }
    
    func audioProcessingProcess(audioBuffer: RTCAudioBuffer) {

    }
    
    func audioProcessingRelease() {
        print("AudioPostProcessor release ")
    }
    
}
