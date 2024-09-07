//
//  AudioDeviceModule.swift
//  calls-swift-testApp
//
//  Created by mat on 9/6/24.
//

import Foundation
import WebRTC

/*
class AudioDevice : NSObject, RTCAudioDevice{
    
    static let shared = AudioDevice()
    
    override public init(){
        
        deviceInputSampleRate = 48000
        deviceOutputSampleRate = 48000
        inputNumberOfChannels = 2
        inputLatency = 5
        outputLatency = 5
        inputIOBufferDuration = 0.05
        isInitialized = true
        isPlayoutInitialized = true
        isPlaying = false
        isRecording = true
        inputIOBufferDuration = 5
        super.init()
    }
    
    func initialize(with delegate: any RTCAudioDeviceDelegate) -> Bool {
        self.delegate = delegate
        return true
    }
    
    var deviceInputSampleRate: Double = 0
    var inputIOBufferDuration: TimeInterval
    var inputNumberOfChannels: Int
    var inputLatency: TimeInterval
    var deviceOutputSampleRate: Double
    var outputIOBufferDuration: TimeInterval
    var outputNumberOfChannels: Int
    var outputLatency: TimeInterval
    var isInitialized: Bool
    var delegate :RTCAudioDeviceDelegate?
    var isPlayoutInitialized: Bool
    var isRecordingInitialized: Bool
    var isRecording: Bool
    var isPlaying: Bool
    
    func terminateDevice() -> Bool {
        return true
    }
    
    func initializePlayout() -> Bool {
        return true
    }
  
    func startPlayout() -> Bool {
        return true
    }
    
    func stopPlayout() -> Bool {
        return true
    }
    
    func initializeRecording() -> Bool {
        return true
    }
    
    func startRecording() -> Bool {
        return true
    }
    
    func stopRecording() -> Bool {
        return true
    }
 }
*/
