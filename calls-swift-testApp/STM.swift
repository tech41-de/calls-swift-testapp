//
//  STM.swift
//  calls-swift-testApp
//
//  Created by mat on 8/24/24.
//

import Foundation

enum States{
    case BOOT
    case CONFIGURE
    case AUDIO_SETUP
    case VIDEOO_SETUP
}

class STM{
    static let  shared = STM()
    private init(){}
    let defaults = UserDefaults.standard
    let api = CloudflareCallsApi.shared
    
    func exec(state:States){
        switch(state){
        case .BOOT:
            if defaults.string(forKey: "appSecret") == nil{
                defaults.set("https://rtc.live.cloudflare.com/v1/apps/", forKey: "serverURL")
                defaults.set("", forKey: "appId")
                defaults.set("", forKey: "appSecret")
                defaults.set(false, forKey: "isHidden")
            }else{
                exec(state: .CONFIGURE)
            }
            break
            
        case .CONFIGURE:
            api.configure(serverUrl: defaults.string(forKey: "serverURL")!, appId: defaults.string(forKey: "appId")!, secret: defaults.string(forKey: "appSecret")!)
            exec(state: .AUDIO_SETUP)
            break
            
        case .AUDIO_SETUP:
            AudioDeviceManager().setup()
            exec(state: .VIDEOO_SETUP)
            break
            
        case .VIDEOO_SETUP:
            VideoDeviceManager().setup()
            break
        }
    }
}
