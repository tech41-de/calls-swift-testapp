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
            print(f)
            let w = CMVideoFormatDescriptionGetDimensions(f.formatDescription).width
            print(w)
            if w >= Int(width){
                let franges = f.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }
                print(franges.count)
                for fr in franges{
                    print(fr)
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
        print("Video devices found \(devices.devices.count)")
        
        Model.shared.videoDevices.removeAll()
        for device in devices.devices {
            Model.shared.videoDevices.append(ADevice(uid:device.uniqueID, name:device.localizedName))
        }
        
        /*
        if (UserDefaults.standard.string(forKey: "videoIn") != nil){
            Model.shared.camera = UserDefaults.standard.string(forKey: "videoIn")!
        }else{
            Model.shared.camera = Model.shared.videoDevices[Model.shared.videoDevices.count - 1].name
        }
         */
        Model.shared.camera = Model.shared.videoDevices[0].name
        print("Using camera \(Model.shared.camera)")
    }
}
