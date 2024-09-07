//
//  VideoViewMacOS.swift
//  calls-swift-testApp
//
//  Created by mat on 9/3/24.
//

import SwiftUI
import WebRTC
import MetalKit

#if os(macOS)
class RTCMTLNSVideoView : MTKView, RTCVideoRenderer, MTKViewDelegate{
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer?.setSize(size: CGSize(width: frame.width, height: frame.height))
    }
    
    func draw(in view: MTKView) {
        renderer!.drawFrame(frame:videoFrame)
    }
    
    var metalDevice: MTLDevice!
    var renderer : RTCMTLI420Renderer?
    var videoFrame : RTCVideoFrame?
    
    required init(frame: NSRect){
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.metalDevice = metalDevice
        }
        renderer = RTCMTLI420Renderer(device:metalDevice)
        renderer?.setSize(size: CGSize(width: frame.width, height: frame.height))
        super.init(frame:frame,device:metalDevice)
        let ok = renderer!.addRenderingDestination(self)
        if ok{
            configure()
        }else{
            print("could not add Render Destination")
        }
    }
    
    required init(coder: NSCoder) {
       super.init(coder: coder)
    }
    
    static func isMetalAvailable() ->Bool{
      return true
    }
    
    func configure() {
        layerContentsPlacement = NSView.LayerContentsPlacement.scaleProportionallyToFit
        translatesAutoresizingMaskIntoConstraints = false
        framebufferOnly = true
        delegate = self
        /// https://webrtc.googlesource.com/src/+/48fcf943fd2a4d52f6e77d7f99eccd1aac577c43/sdk/objc/components/renderer/metal/RTCMTLI420Renderer.mm
    }

    func setSize(_ size :CGSize){
        renderer?.setSize(size: size)
    }
    
    func renderFrame(_ frame : RTCVideoFrame?){
        if frame == nil {
           return
         }
        videoFrame = frame!.newI420()
    }
}
#endif


