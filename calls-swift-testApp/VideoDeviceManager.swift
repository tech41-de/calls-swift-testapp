//
//  VideoDevices.swift
//  calls-swift-testApp
//
//  Created by mat on 8/22/24.
//

import Foundation
import AVFoundation
import WebRTC

class VideoDeviceManager{
    
    let model:Model
    init(model:Model){
        self.model = model
    }
    
    @MainActor
    func setup(){
        findDevices() 
    }
    
    func chooseFormat(device : AVCaptureDevice, width:CGFloat,fps :Int)-> (AVCaptureDevice.Format?, Int){
        let formats = (RTCCameraVideoCapturer.supportedFormats(for: device).sorted { (f1, f2) -> Bool in
            let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
            let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
            return width1 < width2
        })
        
        for f in formats{
            let w = CMVideoFormatDescriptionGetDimensions(f.formatDescription).width
            if w >= Int(width){
                let franges = f.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }
                for fr in franges{
                    if Int(fr.maxFrameRate) >= fps && Int(fr.minFrameRate) <= fps{
                        return (f,fps)
                    }else{
                        return (f,Int(fr.maxFrameRate))
                    }
                }
                break
            }
        }
        return (nil,0)
    }
    
    func getDevice(name:String) ->AVCaptureDevice?{ // .continuityCamera .external
        var items = [AVCaptureDevice.DeviceType.builtInWideAngleCamera, AVCaptureDevice.DeviceType.builtInWideAngleCamera]
#if os(macOS)
        if #available(macOS 14.0, *) {
            items.append(AVCaptureDevice.DeviceType.continuityCamera)
            items.append(AVCaptureDevice.DeviceType.external)
        }
        if #available(macOS 10.0, *) {
            items.append(AVCaptureDevice.DeviceType.deskViewCamera)
        }
#else
        
#endif
        let device = AVCaptureDevice.DiscoverySession.init(deviceTypes: items, mediaType: .video, position:.unspecified)
        for device in device.devices{
            if device.localizedName == name{
                return device
            }
        }
        return nil
    }
    
    @MainActor
    func findDevices() {
        AVCaptureDevice.requestAccess(for: .video) { isAuthorized in
            if !isAuthorized {
                print("we need access")
                return
            }
            
        }
        var items = [AVCaptureDevice.DeviceType.builtInWideAngleCamera, AVCaptureDevice.DeviceType.builtInWideAngleCamera]
#if os(macOS)
        if #available(macOS 14.0, *) {
            items.append(AVCaptureDevice.DeviceType.continuityCamera)
            items.append(AVCaptureDevice.DeviceType.external)
        }
        if #available(macOS 10.0, *) {
            items.append(AVCaptureDevice.DeviceType.deskViewCamera)
        }
#else
        
#endif
        let devices = AVCaptureDevice.DiscoverySession.init(deviceTypes: items, mediaType: .video, position:.unspecified)
        model.videoDevices.removeAll()
        for device in devices.devices {
            model.videoDevices.append(ADevice(uid:device.uniqueID, name:device.localizedName))
        }
        
        // this is for iPhone
        if model.videoDevices.count > 1 && model.videoDevices[1].name == "Front Camera"{
            model.camera = model.videoDevices[1].name
        }else{
            model.camera = model.videoDevices[0].name
        }
    }
}
