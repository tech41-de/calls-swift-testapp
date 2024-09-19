//
//  Extensions.swift
//  calls-swift-testApp
//
//  Created by mat on 9/6/24.
//

import Foundation
import AVFoundation
import WebRTC

@objc
public protocol MediaDevice: AnyObject {
    var deviceId: String { get }
    var name: String { get }
}

@objc
public class AudioDevice: NSObject, MediaDevice {
    public var deviceId: String { _ioDevice.deviceId }
    public var name: String { _ioDevice.name }
    public var isDefault: Bool { _ioDevice.isDefault }

    let _ioDevice: RTCIODevice

    init(ioDevice: RTCIODevice) {
        _ioDevice = ioDevice
    }
}

extension AudioDevice: Identifiable {
    public var id: String { deviceId }
}

public extension DispatchQueue{
    static let WebRTCQueue = DispatchQueue(label:"tech41.webRTC", qos:. default)
}



