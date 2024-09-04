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
    
    @State var model : Model
    @State var controller : Controller
    @State var stm : STM
    @State var signalClient : SignalClient
    
    // Buiding services upfront and inject
    init(){
        let model = Model()
        let controller = Controller(model:model)
        let signalClient = SignalClient(model: model, controller:controller)
        let stm = STM(model: model, controller: controller, signalClient: signalClient)
        model.stateExec = stm
        self.model = model
        self.controller = controller
        self.signalClient = signalClient
        self.stm = stm
    }

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(model).environmentObject(controller).environmentObject(stm)
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
