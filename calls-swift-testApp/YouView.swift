//
//  YouViewer.swift
//  calls-swift-testApp
//
//  Created by mat on 8/22/24.
//

import SwiftUI
import WebRTC


#if os(macOS)
struct YouView : NSViewRepresentable{
    func makeNSView(context: Context) ->RTCMTLNSVideoView{
        //Model.shared.youView.setSize(CGSize(width:150, height:150))
        return Model.shared.youView
    }
    
    func updateNSView(_ nsView: RTCMTLNSVideoView, context: Context) {
       
    }
}
#else
struct YouView : UIViewRepresentable{
    func makeUIView(context: Context) ->RTCMTLVideoView{
        //Model.shared.youView.setSize(CGSize(width:150, height:150))
        return Model.shared.youView
    }
    
    func updateUIView(_ nsView: RTCMTLVideoView, context: Context) {
       
    }
}
#endif



