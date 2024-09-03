//
//  RTCMTLI420Renderer.swift
//  calls-swift-testApp
//
//  Created by mat on 9/3/24.
//

import Foundation
import Metal
import MetalKit
import WebRTC
// https://webrtc.googlesource.com/src/+/48fcf943fd2a4d52f6e77d7f99eccd1aac577c43/sdk/objc/components/renderer/metal/RTCMTLI420Renderer.mm

class RTCMTLI420Renderer : RTCMTLRenderer{
    
    init(device:MTLDevice){
        self.device = device
        super.init()
    }
    
    static let shaderSource = """
        using namespace metal;
        typedef struct {
          packed_float2 position;
          packed_float2 texcoord;
        } Vertex;
        typedef struct {
          float4 position[[position]];
          float2 texcoord;
        } Varyings;
        vertex Varyings vertexPassthrough(device Vertex * verticies[[buffer(0)]],
                                          unsigned int vid[[vertex_id]]) {
          Varyings out;
          device Vertex &v = verticies[vid];
          out.position = float4(float2(v.position), 0.0, 1.0);
          out.texcoord = v.texcoord;
          return out;
        }
        fragment half4 fragmentColorConversion(
            Varyings in[[stage_in]], texture2d<float, access::sample> textureY[[texture(0)]],
            texture2d<float, access::sample> textureU[[texture(1)]],
            texture2d<float, access::sample> textureV[[texture(2)]]) {
          constexpr sampler s(address::clamp_to_edge, filter::linear);
          float y;
          float u;
          float v;
          float r;
          float g;
          float b;
          // Conversion for YUV to rgb from http://www.fourcc.org/fccyvrgb.php
          y = textureY.sample(s, in.texcoord).r;
          u = textureU.sample(s, in.texcoord).r;
          v = textureV.sample(s, in.texcoord).r;
          u = u - 0.5;
          v = v - 0.5;
          r = y + 1.403 * v;
          g = y - 0.344 * u - 0.714 * v;
          b = y + 1.770 * u;
          float4 out = float4(r, g, b, 1.0);
          return half4(out);
        }
"""
    var device : MTLDevice
    var _yTexture : MTLTexture?
    var _uTexture : MTLTexture?
    var _vTexture : MTLTexture?
    
    var _descriptor :MTLTextureDescriptor?
    var _chromaDescriptor : MTLTextureDescriptor?
    var _width : Int = 300
    var _height : Int = 200
    var _chromaWidth : Int = 300
    var _chromaHeight : Int = 200
    var _cropWidth : Int = 300
    var _cropHeight : Int = 200
    
    // var commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    func drawFrame(frame:RTCVideoFrame?){
        if frame == nil{
            return
        }
        super.render()
    }
    
    func getWidth(frame:RTCVideoFrame) {
      _width = Int(frame.width)
      _height = Int(frame.height)
      _cropWidth = Int(frame.width)
      _cropHeight = Int(frame.height)
    }
    
    // Overrides
    override func shaderSource() ->String{
        return RTCMTLI420Renderer.shaderSource
    }
    
    override func setupTexturesForFrame(frame: RTCVideoFrame) ->Bool {
        if ((_descriptor == nil) || _width != frame.width || _height != frame.height) {
           
            _descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.r8Unorm, width:_width, height:_height, mipmapped:false)
            _descriptor!.usage = .shaderRead;
            _yTexture = device.makeTexture(descriptor: _descriptor!)
        }
        let buffer = frame.buffer.toI420()
        _yTexture!.replace(region: MTLRegionMake2D(0, 0, _width, _height), mipmapLevel:0, withBytes: buffer.dataY, bytesPerRow: Int(buffer.strideY))
        
        if ((_chromaDescriptor == nil) || _chromaWidth != frame.width / 2 || _chromaHeight != frame.height / 2) {
            _chromaWidth = Int(frame.width / 2)
            _chromaHeight = Int(frame.height / 2)
            _chromaDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:MTLPixelFormat.bgra8Unorm, width:_chromaWidth, height:_chromaHeight, mipmapped:false)
            _chromaDescriptor!.usage =  .shaderRead;
            _uTexture = device.makeTexture(descriptor: _chromaDescriptor!)
            _vTexture = device.makeTexture(descriptor: _chromaDescriptor!)
        }
       // _uTexture!.replace(region: MTLRegionMake2D(0, 0, _chromaWidth, _chromaHeight), mipmapLevel:0, withBytes:buffer.dataU, bytesPerRow:Int(buffer.strideU))
       // _vTexture!.replace(region: MTLRegionMake2D(0, 0, _chromaWidth, _chromaHeight), mipmapLevel:0, withBytes:buffer.dataV, bytesPerRow:Int(buffer.strideV))
        return  (_uTexture != nil) && (_yTexture != nil) && (_vTexture != nil);
    }
    
    override func uploadTexturesToRenderEncoder(renderEncoder : MTLRenderCommandEncoder){
        renderEncoder.setFragmentTexture(_yTexture, index:0)
        renderEncoder.setFragmentTexture(_uTexture, index:1)
        renderEncoder.setFragmentTexture(_vTexture, index:2)
    }
}
