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
    
    var width:CGFloat = 0
    
    init(width:CGFloat){
        self.width = width
    }
    
    func makeNSView(context: Context) ->RTCMTLNSVideoView{
        return Model.shared.youView
    }
    
    func updateNSView(_ nsView: RTCMTLNSVideoView, context: Context) {
       
    }
}
#else
struct YouView : UIViewRepresentable{
    
    var width:CGFloat = 0
    var model:Model
    
    init(model:Model, width:CGFloat){
        self.model = model
        self.width = width
    }
    
    func makeUIView(context: Context) ->RTCMTLVideoView{
        return model.youView
    }
    
    func updateUIView(_ nsView: RTCMTLVideoView, context: Context) {
       
    }
}
#endif



