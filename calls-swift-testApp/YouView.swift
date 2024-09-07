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
    var height:CGFloat = 0
    var model : Model
    
    init(model:Model, width:CGFloat, height:CGFloat){
        self.model = model
        self.width = width
        self.height = height
    }
    func makeNSView(context: Context) ->RTCMTLNSVideoView{
        return model.youView
    }
    
    func updateNSView(_ nsView: RTCMTLNSVideoView, context: Context) {
        nsView.setSize(CGSize(width:width, height:height))
    }
}
#else

struct YouView : UIViewRepresentable{
    
    var width:CGFloat = 0
    var height:CGFloat = 0
    var model:Model
    
    init(model:Model, width:CGFloat, height:CGFloat){
        self.model = model
        self.width = width
        self.height = height
    }
    
    func makeUIView(context: Context) ->RTCMTLVideoView{
        return model.youView
        
        
    }
    
    func updateUIView(_ nsView: RTCMTLVideoView, context: Context) {
       
    }
}
#endif



