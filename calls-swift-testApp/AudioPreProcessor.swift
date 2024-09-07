//
//  AudioPreProcessor.swift
//  calls-swift-testApp
//
//  Created by mat on 9/6/24.
//

import Foundation
import WebRTC

class AudioPreProcessor : NSObject, RTCAudioCustomProcessingDelegate{
    
    func audioProcessingInitialize(sampleRate sampleRateHz: Int, channels: Int) {
        print("AudioPreProcessor sampleRate \(sampleRateHz)")
        print("AudioPreProcessor channels \(channels)")
    }
    
    func audioProcessingProcess(audioBuffer: RTCAudioBuffer) {
      //  print("AudioPreProcessor audioBuffer")
       // print(audioBuffer.channels)
       // print(audioBuffer.frames)
       // print(audioBuffer.framesPerBand)
       //print(audioBuffer.description)
    }
    
    func audioProcessingRelease() {
        print("AudioPreProcessor release ")
    }
}
