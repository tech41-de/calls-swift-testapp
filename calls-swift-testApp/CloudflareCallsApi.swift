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
        let desc = Calls.SessionDescription( type:"offer", sdp:sdp)
        let req =  Calls.NewTracksLocal(sessionDescription: desc, tracks:localTracks)
        await api.newLocalTracks(sessionId: sessionId, newTracks: req){newTracksResponse, error in
            let sdpStr = newTracksResponse!.sessionDescription.sdp
            let sdp = RTCSessionDescription(type: .answer, sdp: sdpStr)
            Model.shared.webRtcClientA?.set(remoteSdp: sdp){err in
                print(err)
            }
        }
    }
    
    func renegotiate(sessionId:String, sdp:String, type:String) {
        Task{
            let sdpReq = Calls.NewReq(sdp: sdp, type: type)
            let newDesc = Calls.NewDesc(sessionDescription: sdpReq)
            await api.renegotiate(sessionId: sessionId, sdp: newDesc){  error in
                print(error)
            }
        }
    }
    
    func SetRemoteTracks(sessionId:String, mid:String, trackName:String) {
            Task{
                let remoteTrack =  Calls.RemoteTrack(location:"remote",sessionId:sessionId, trackName: trackName)
                var remoteTracks =  [Calls.RemoteTrack]()
                remoteTracks.append(remoteTrack)
                let req = Calls.NewTracksRemote(tracks:remoteTracks)
                await api.newTracks(sessionId:Model.shared.sessionId, newTracksRemote: req){ res, error in
                    if error.count > 0{
                        print (error)
                    }
                    if res != nil{
                        let tracks = res!.tracks
                        let mid = tracks[0].mid
                        let sessionId = tracks[0].sessionId
                        let trackName = tracks[0].trackName
                        print(mid)
                        print(sessionId)
                        print(trackName)
                        
                        let sessioneDesc = res!.sessionDescription
                        let desc = RTCSessionDescription(type: .offer, sdp: sessioneDesc.sdp)
                        Model.shared.webRtcClientA?.set(remoteSdp: desc){_ in
                            let doRenegotiate = res!.requiresImmediateRenegotiation
                            print(doRenegotiate)
                            
                            if(doRenegotiate){
                                let type = res!.sessionDescription.type
                                
                                if(type == "answer"){
                                    print("errorm=, we should only see an offer")
                                    return
                                }
                                if(type == "offer"){
                                    self.renegotiate(sessionId: sessionId!, sdp: Model.shared.sdpLocal, type:"answer")
                                }
                            }
                        }
                       
                    }
                }
            }
        }
}

