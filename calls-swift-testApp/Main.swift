//
//  App.swift
//  calls-swift-testApp
//
//  Created by mat on 8/22/24.
//
// webrtc options tested
// https://github.com/alexpiezo/WebRTC.git // has link errors on IoS - import WebRTC
// https://github.com/stasel/WebRTC // has link errors on Mac - import WebRTC
// https://github.com/livekit/webrtc-xcframework.git // needs prefixing with LK - import LiveKitWebRTC
// https://github.com/webrtc-sdk/Specs // Misses RTCMTLNSVideoView - works in iOS and Catalyst stable - import WebRTC

import SwiftUI

@main
struct Main: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/*
 macCatalyst 13.0 = macOS 10.15 (Catalina)
 macCatalyst 13.4 = macOS 10.15.4
 macCatalyst 14.0 = macOS 11.0 (Big Sur)
 macCatalyst 14.7 = macOS 11.6
 macCatalyst 15.0 = macOS 12.0 (Monterey)
 macCatalyst 15.3 = macOS 12.2 and 12.2.1
 macCatalyst 15.4 = macOS 12.3
 macCatalyst 15.5 = macOS 12.4
 macCatalyst 15.6 = macOS 12.5
 macCatalyst 16.6 = macOS 13.5 (Ventura)
 macCatalyst 17.0 = macOS 14.0 (Sonoma)
 macCatalyst 17.2 = macOS 14.2 and 14.2.1
 */
