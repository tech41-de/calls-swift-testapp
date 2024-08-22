//
//  App.swift
//  calls-swift-testApp
//
//  Created by mat on 8/22/24.
//
// webrtc options tested
// https://github.com/alexpiezo/WebRTC.git // has link errors on IoS - importWebRTC
// https://github.com/stasel/WebRTC // has link errors on Mac - importWebRTC
// https://github.com/livekit/webrtc-xcframework.git // needs prefixing with LK - import LiveKitWebRTC

import SwiftUI

@main
struct Main: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
