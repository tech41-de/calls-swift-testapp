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
    
    static let cubeVertexData = [-1.0, -1.0, 0.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, -1.0, -1.0, 1.0, 1.0, 1.0, -1.0, 1.0, 0.0, -1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, -1.0, -1.0, 1.0, 0.0, 1.0, -1.0, 0.0, 0.0, -1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, -1.0, -1.0, 0.0, 0.0, 1.0, -1.0, 0.0, 1.0, -1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0]

    static func offsetForRotation(rotation : RTCVideoRotation ) ->Int{
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
    
    let kMaxInflightBuffers = 1
    
    var _view : MTKView?
    var _inflight_semaphore : dispatch_semaphore_t?
    
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
        _inflight_semaphore = DispatchSemaphore(value: kMaxInflightBuffers);
    }
    
    func addRenderingDestination(_ view : MTKView) ->Bool{
        return self.setupWithView(view: view)
    }
    
    func setupWithView(view : MTKView) ->Bool {
      var success = false
        if setupMetal() {
            setupView(view:view)
            loadAssets()
            setupBuffers()
            success = true
      }
      return success
    }
    
   func currentMetalDevice() ->MTLDevice{
       return _device!
    }
    
    func shaderSource() ->String{
      return ""
    }
    
    func uploadTexturesToRenderEncoder(renderEncoder : MTLRenderCommandEncoder) {
     
    }

    func setupTexturesForFrame(frame:RTCVideoFrame)->Bool {
        _offset = RTCMTLRenderer.offsetForRotation(rotation: frame.rotation);
      return true
    }
     
    
    func setupMetal()->Bool {
      // Set the view to use the default device.
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
      view.device = _device;
      view.preferredFramesPerSecond = 30;
      view.autoResizeDrawable = false;
      _view = view;
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
        _vertexBuffer = _device!.makeBuffer(bytes: RTCMTLRenderer.cubeVertexData, length:MemoryLayout<Double>.size * 64, options:.cpuCacheModeWriteCombined)
    }
    
    func render (){
        let _ = _inflight_semaphore!.wait(timeout:.distantFuture )
        let commandBuffer = _commandQueue!.makeCommandBuffer()
        commandBuffer!.label = RTCMTLRenderer.commandBufferLabel
        let dispatch_semaphore_t  = _inflight_semaphore
        commandBuffer?.addCompletedHandler(){res in
            // GPU work completed.
            dispatch_semaphore_t!.signal();
        }

        let renderPassDescriptor = _view?.currentRenderPassDescriptor
        if renderPassDescriptor != nil {  // Valid drawable.
          
            let renderEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
            renderEncoder!.label = RTCMTLRenderer.renderEncoderLabel

            // Set context state.
            renderEncoder!.pushDebugGroup(RTCMTLRenderer.renderEncoderDebugGroup)
            renderEncoder!.setRenderPipelineState(_pipelineState!)
            renderEncoder!.setVertexBuffer(_vertexBuffer, offset:_offset * MemoryLayout<Float>.size, index:0)

            uploadTexturesToRenderEncoder(renderEncoder: renderEncoder!)
            renderEncoder!.drawPrimitives(type: .triangleStrip, vertexStart:0, vertexCount:4, instanceCount:1)
            renderEncoder!.popDebugGroup()
            renderEncoder!.endEncoding()

            commandBuffer!.present((_view?.currentDrawable!)!)
        }

      // CPU work is completed, GPU work can be started.
        commandBuffer!.commit()
    }
}
