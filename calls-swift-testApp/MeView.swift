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
    
    var width:CGFloat = 0
    
    init(width:CGFloat){
        self.width = width
    }
    
    func makeNSView(context: Context) ->RTCMTLNSVideoView{
       // Model.shared.meView.setSize(CGSize(width:400, height:300))
        return Model.shared.meView
    }
    
    func updateNSView(_ nsView: RTCMTLNSVideoView, context: Context) {
       
    }
}
#else
struct MeView : UIViewRepresentable{
    
    var width:CGFloat = 0
    
    init(width:CGFloat){
       // Model.shared.meView.setSize(CGSize(width:400, height:300))
    }
    
    func makeUIView(context: Context) ->RTCMTLVideoView{
       // Model.shared.meView.setSize(CGSize(width:400, height:300))
        return Model.shared.meView
    }
    
    func updateUIView(_ nsView: RTCMTLVideoView, context: Context) {
       
    }
}
#endif
