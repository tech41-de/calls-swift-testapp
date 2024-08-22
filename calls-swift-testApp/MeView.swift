//
//  MeView.swift
//  calls-swift-testApp
//
//  Created by mat on 8/22/24.
//

import SwiftUI
import WebRTC

#if os(macOS)
struct MeView : NSViewRepresentable{
    func makeNSView(context: Context) ->RTCMTLNSVideoView{
        //Model.shared.meView.setSize(CGSize(width:400, height:300))
        return Model.shared.meView
    }
    
    func updateNSView(_ nsView: RTCMTLNSVideoView, context: Context) {
       
    }
}
#else
struct MeView : UIViewRepresentable{
    func makeNSView(context: Context) ->RTCMTLNSVideoView{
       // Model.shared.meView.setSize(CGSize(width:400, height:300))
        return Model.shared.meView
    }
    
    func updateNSView(_ nsView: RTCMTLNSVideoView, context: Context) {
       
    }
}
#endif
