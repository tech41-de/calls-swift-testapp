//
//  VideoDevices.swift
//  calls-swift-testApp
//
//  Created by mat on 8/22/24.
//

import Foundation
import AVFoundation

class VideoDeviceManager{
    
    func setup(){
        findDevices() 
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
