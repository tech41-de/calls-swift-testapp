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
    var _width : Int = 640
    var _height : Int = 480
    var _chromaWidth : Int = 640 / 2
    var _chromaHeight : Int = 480 / 2
    
    func setSize(size:CGSize){
        /*
        if size.width < size.height{
            print("going portrait")
        }else{
            print("going landscpe")
        }
        _width = Int(size.width)
        _height = Int(size.height)
        _chromaWidth = Int(size.width / 2)
        _chromaHeight = Int(size.height / 2)
         */
    }
    
    // Overrides
    override func shaderSource() ->String{
        return RTCMTLI420Renderer.shaderSource
    }
    
    override func setupTexturesForFrame(frame: RTCVideoFrame) ->Bool {
        super.setupTexturesForFrame(frame:frame)
        
        let device = currentMetalDevice()
        if device == nil {
          return false
        }
   
        let buffer = frame.buffer.toI420()
        if buffer.width == 0{
            return false
        }

        // Luminance (y) texture - Format is 420 https://en.wikipedia.org/wiki/Y%E2%80%B2UV
        // For savety pinning to the frame size
        var tWidth = _width
        var tHeight = _height
        if ((_descriptor == nil) || _width != frame.width || _height != frame.height) {
            tWidth = Int(frame.width)
            tHeight = Int(frame.height)
            _descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.r8Unorm, width:tWidth, height:tHeight, mipmapped:false)
            _descriptor!.usage = .shaderRead
            _yTexture = device!.makeTexture(descriptor: _descriptor!)
        }

        try _yTexture!.replace(region: MTLRegionMake2D(0, 0, tWidth, tHeight), mipmapLevel:0, withBytes: buffer.dataY, bytesPerRow: Int(buffer.strideY))

        // Chroma textures
        // For savety pinning to the frame size
        if ((_chromaDescriptor == nil) || _chromaWidth != frame.width / 2 || _chromaHeight != frame.height / 2) {
            _chromaWidth = Int(frame.width / 2)
            _chromaHeight = Int(frame.height / 2)
            _chromaDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:MTLPixelFormat.r8Unorm, width:_chromaWidth, height:_chromaHeight, mipmapped:false)
            _chromaDescriptor!.usage =  .shaderRead
            _uTexture = device!.makeTexture(descriptor: _chromaDescriptor!)
            _vTexture = device!.makeTexture(descriptor: _chromaDescriptor!)
        }

        _uTexture!.replace(region: MTLRegionMake2D(0, 0, _chromaWidth, _chromaHeight), mipmapLevel:0, withBytes:buffer.dataU, bytesPerRow:Int(buffer.strideU))
        _vTexture!.replace(region: MTLRegionMake2D(0, 0, _chromaWidth, _chromaHeight), mipmapLevel:0, withBytes:buffer.dataV, bytesPerRow:Int(buffer.strideV))
        return  _uTexture != nil && _yTexture != nil && _vTexture != nil
    }
    
    override func uploadTexturesToRenderEncoder(renderEncoder : MTLRenderCommandEncoder){
        renderEncoder.setFragmentTexture(_yTexture, index:0)
        renderEncoder.setFragmentTexture(_uTexture, index:1)
        renderEncoder.setFragmentTexture(_vTexture, index:2)
    }
}
