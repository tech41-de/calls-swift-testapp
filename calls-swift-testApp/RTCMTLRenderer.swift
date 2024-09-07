//
//  RTCMTLRenderer.swift
//  calls-swift-testApp
//
//  Created by mat on 9/3/24.
//

import Foundation
import Metal
import MetalKit
import WebRTC
// https://github.com/pristineio/webrtc-mirror/blob/master/webrtc/sdk/objc/Framework/Classes/Metal/RTCMTLRenderer.mm

class RTCMTLRenderer{
    static let vertexFunctionName = "vertexPassthrough"
    static let fragmentFunctionName = "fragmentColorConversion"
    static let pipelineDescriptorLabel = "RTCPipeline"
    static let commandBufferLabel = "RTCCommandBuffer"
    static let renderEncoderLabel = "RTCEncoder"
    static let renderEncoderDebugGroup = "RTCDrawFrame"
    
    let cubeVertexData : [Float] = [-1.0, -1.0, 0.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, -1.0, -1.0, 1.0, 1.0, 1.0, -1.0, 1.0, 0.0, -1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, -1.0, -1.0, 1.0, 0.0, 1.0, -1.0, 0.0, 0.0, -1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, -1.0, -1.0, 0.0, 0.0, 1.0, -1.0, 0.0, 1.0, -1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0]

    static func getCubeVertexData(cropX : Int, cropY :Int, cropWidth : Int, cropHeight : Int, frameWidth :Int, frameHeight : Int, rotation : RTCVideoRotation) ->[Float]{

        let cropLeft = Float(cropX / frameWidth)
        let cropRight = Float((cropX + cropWidth) / frameWidth)
        let cropTop = Float(cropY / frameHeight)
        let cropBottom = Float((cropY + cropHeight) / frameHeight)

      // These arrays map the view coordinates to texture coordinates, taking cropping and rotation
      // into account. The first two columns are view coordinates, the last two are texture coordinates.
      switch (rotation) {
      case ._0:
          return [-1.0, -1.0, cropLeft, cropBottom,
                               1.0, -1.0, cropRight, cropBottom,
                              -1.0,  1.0, cropLeft, cropTop,
                               1.0,  1.0, cropRight, cropTop];
    case ._90:
          return [-1.0, -1.0, cropRight, cropBottom,
                               1.0, -1.0, cropRight, cropTop,
                              -1.0,  1.0, cropLeft, cropBottom,
                               1.0,  1.0, cropLeft, cropTop]
      case ._180:
          return [-1.0, -1.0, cropRight, cropTop,
                               1.0, -1.0, cropLeft, cropTop,
                              -1.0,  1.0, cropRight, cropBottom,
                               1.0,  1.0, cropLeft, cropBottom]
      case ._270:
          return [-1.0, -1.0, cropLeft, cropTop,
                               1.0, -1.0, cropLeft, cropBottom,
                              -1.0, 1.0, cropRight, cropTop,
                               1.0, 1.0, cropRight, cropBottom]
      @unknown default:
          return [-1.0, -1.0, cropLeft, cropBottom,
                               1.0, -1.0, cropRight, cropBottom,
                              -1.0,  1.0, cropLeft, cropTop,
                               1.0,  1.0, cropRight, cropTop]
      }
    }
    
    func offsetForRotation(rotation : RTCVideoRotation ) ->Int{
      switch (rotation) {
          
      case ._0:
          return 0
          
      case ._90:
          return 16
          
      case ._180:
          return 32
          
      case ._270:
          return 48
          
      @unknown default:
          return 0
      }
    }

    var _view : MTKView?

    // Renderer.
    var _device : MTLDevice?
    var _commandQueue : MTLCommandQueue?
    var _defaultLibrary: MTLLibrary?
    var _pipelineState : MTLRenderPipelineState?

    // Buffers.
    var _vertexBuffer : MTLBuffer?

    // RTC Frame parameters.
    var _offset : Int = 0
    
    init(){
        _offset = 0;
    }
    
    func addRenderingDestination(_ view : MTKView) ->Bool{
        return self.setupWithView(view: view)
    }
    
    func setupWithView(view : MTKView) ->Bool {
      var success = false
        if setupMetal() {
            setupView(view:view)
            setupBuffers()
            success = true
      }
      return success
    }
    
   func currentMetalDevice() ->MTLDevice?{
       return _device
    }
    
    func shaderSource() ->String{
      return ""
    }
    
    func uploadTexturesToRenderEncoder(renderEncoder : MTLRenderCommandEncoder) {
     
    }

    func setupTexturesForFrame(frame:RTCVideoFrame)->Bool {
        _offset = offsetForRotation(rotation: frame.rotation);
      return true
    }
    
    func setupMetal()->Bool {
        _device = MTLCreateSystemDefaultDevice()
        if (_device == nil) {
            return false
        }
        _commandQueue = _device!.makeCommandQueue()
        do{
            let sourceLibrary = try _device!.makeLibrary(source: shaderSource(), options:nil)
            _defaultLibrary = sourceLibrary
        }
        catch{
            print(error)
            return false
        }
        return true
    }

    func setupView(view: MTKView){
        _view = view
        view.device = _device
        view.preferredFramesPerSecond = 30
        view.autoResizeDrawable = false
        loadAssets()
        _vertexBuffer = _device!.makeBuffer(bytes: cubeVertexData, length:4 * 32, options:.cpuCacheModeWriteCombined) // cpuCacheModeWriteCombined
    }
    
    func loadAssets() {
        do{
            let vertexFunction = _defaultLibrary!.makeFunction(name: RTCMTLRenderer.vertexFunctionName)
            let fragmentFunction = _defaultLibrary!.makeFunction(name: RTCMTLRenderer.fragmentFunctionName)
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.label = RTCMTLRenderer.pipelineDescriptorLabel
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = _view!.colorPixelFormat
            pipelineDescriptor.depthAttachmentPixelFormat = .invalid
            _pipelineState = try _device!.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }catch{
            print(error)
        }
    }
    
    func setupBuffers(){
       
    }
    
    let semaphore = DispatchSemaphore(value: 1)
   
    func drawFrame(frame:RTCVideoFrame?){
        if frame == nil{
            return
        }
       semaphore.wait()
        if setupTexturesForFrame(frame:frame!){
            render()
        }else{
            semaphore.signal()
        }
    }
    
    func render (){
        let commandBuffer = _commandQueue!.makeCommandBuffer()
        commandBuffer!.label = RTCMTLRenderer.commandBufferLabel
        commandBuffer!.addCompletedHandler(){res in
           self.semaphore.signal()
        }

        let renderPassDescriptor = _view?.currentRenderPassDescriptor
        if renderPassDescriptor != nil {
            let renderEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
            renderEncoder!.label = RTCMTLRenderer.renderEncoderLabel

            renderEncoder!.pushDebugGroup(RTCMTLRenderer.renderEncoderDebugGroup)
            renderEncoder!.setRenderPipelineState(_pipelineState!)
            renderEncoder!.setVertexBuffer(_vertexBuffer, offset: 0, index:0) //offset * MemoryLayout<Float>.size

            uploadTexturesToRenderEncoder(renderEncoder: renderEncoder!)
            renderEncoder!.drawPrimitives(type: .triangleStrip, vertexStart:0, vertexCount:4, instanceCount:1)
            renderEncoder!.popDebugGroup()
            renderEncoder!.endEncoding()

            commandBuffer!.present((_view?.currentDrawable!)!)
        }
        commandBuffer!.commit()
    }
}
