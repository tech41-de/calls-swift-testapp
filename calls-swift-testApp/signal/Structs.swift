//
//  Structs.swift
//  calls-swift-testApp
//
//  Created by mat on 8/28/24.
//

import Foundation

public struct Track : Codable{
    public var trackId : String
    public var mid : String
    public var type  :String
    
    public init(trackId : String, mid : String, type : String){
        self.trackId = trackId
        self.mid = mid
        self.type = type
    }
}

public struct Session: Codable{
    public var sessionId : String
    public var tracks : [Track]
    public var room : String
    
    public init(sessionId : String, tracks :[Track], room : String){
        self.sessionId = sessionId
        self.tracks = tracks
        self.room = room
    }
}

public struct SignalReq: Codable{
    public var cmd : String
    public var session :Session
    
    public init(cmd : String, session : Session){
        self.cmd = cmd
        self.session = session
    }
}

public struct SignalRes: Codable{
    public var cmd : String
    public var session :Session
    
    public init(cmd : String, session :Session){
        self.cmd = cmd
        self.session = session
    }
}
