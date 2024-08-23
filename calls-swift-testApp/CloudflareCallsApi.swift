//
//  CloudflareCallsApi.swift
//  calls-swift-testApp
//
//  Created by mat on 8/23/24.
//

import Foundation
import Calls_Swift
import WebRTC

class CloudflareCallsApi{
    
    static let shared = CloudflareCallsApi()
    
    let api : Calls
    private init(){
        api = Calls()
    }
    

    
    func configure(serverUrl: String, appId: String, secret: String){
        api.configure(serverUrl: serverUrl, appId: appId, secret: secret)
    }
    
    func SetLocalTracks(sessionId:String, sdp:String, mid:String, trackName:String) async {
        var localTracks =  [Calls.LocalTrack]()
        let localTrackVideo = Calls.LocalTrack(location: "local", mid: mid, trackName: trackName)
        localTracks.append(localTrackVideo)
        let desc = Calls.SessionDescription(sdp:sdp, type:"offer")
        let req =  Calls.NewTracksLocal(sessionDescription: desc, tracks:localTracks)
        
        await api.newLocalTracks(sessionId: sessionId, newTracks: req){newTracksResponse, error in
           print(newTracksResponse)
        }
    }
    
    func SetRemoteTracks(sessionId:String, trackName:String) {
        Task{
            let remoteTrack =  Calls.RemoteTrack(location:"remote",sessionId:sessionId, trackName: trackName)
            var remoteTracks =  [Calls.RemoteTrack]()
            remoteTracks.append(remoteTrack)
            let req = Calls.NewTracksRemote(tracks:remoteTracks)
            await api.newTracks(sessionId: Model.shared.sessionId, newTracksRemote: req){ newTracksResponse, error in
               print(newTracksResponse)
            }
        }
    }
}

