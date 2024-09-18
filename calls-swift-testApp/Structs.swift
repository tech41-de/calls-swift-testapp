//
//  Structs.swift
//  calls-swift-testApp
//
//  Created by mat on 8/28/24.
//

import Foundation

enum States{
    case COLD
    case BOOT
    case CONFIGURE
    case AUDIO_SETUP
    case VIDEOO_SETUP
    case START_STREAM
    case START_SESSION // setup Peer
    case NEW_SESSION // Cloudflare New Session
    case NEW_LOCAL_TRACKS
    case START_SIGNALING
    case INVITE
    case NEW_REMOTE_TRACKS
    case RUNNING
}

public struct ADevice : Hashable{
    var uid = ""
    var name = ""
    var id :UInt32 = 0
}

public struct Track : Codable{
    public var trackId : String
    public var mid : String
    public var type  :String
    public var kind  :String
    
    public init(trackId : String, mid : String, type : String, kind:String){
        self.trackId = trackId
        self.mid = mid
        self.type = type
        self.kind = kind
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
    public var receiver : String
    public var session :Session
    
    public init(cmd : String, receiver:String, session : Session){
        self.cmd = cmd
        self.receiver = receiver // empty if broadcast
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

public enum MsgType :Codable{
    case chat
    case ping
    case pong
}

public protocol PeerMsg :Codable{}

public struct AnyEncodable:Encodable{
    private let encodeClosure:(Encoder) throws-> Void
    
    public init<T:Encodable>(_ value: T){
        encodeClosure = { encoder in
            try value.encode(to: encoder)
        }
    }
        
    public func encode(to encoder:Encoder)throws {
        try encodeClosure(encoder)
    }
}

public struct ChannelMsg: Codable{
    public var type : MsgType
    public var sender : String
    public var reciever : String
    public var obj :PeerMsg
    public var sendDate : Int
    
    enum CodingKeys: String, CodingKey {
        case type
        case sender
        case reciever
        case obj
        case sendDate
    }
    
    public init(type: MsgType, sender:String, reciever:String, obj:PeerMsg, sendDate: Int){
        self.type = type
        self.sender = sender
        self.reciever = reciever
        self.obj = obj
        self.sendDate = sendDate
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(MsgType.self, forKey: .type)
        sender = try container.decode(String.self, forKey: .sender)
        reciever = try container.decode(String.self, forKey: .reciever)
        sendDate = try container.decode(Int.self, forKey: .sendDate)
        switch(type){
            
        case .chat:
            obj = try container.decode(ChatMsg.self, forKey: .obj)
            break
            
        case .ping:
            obj = try container.decode(PingMsg.self, forKey: .obj)
            break
            
        case .pong:
            obj = try container.decode(PongMsg.self, forKey: .obj)
            break
        }
    }
    
    public func encode(to encoder: any Encoder) throws{
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(sender, forKey: .sender)
        try container.encode(reciever, forKey: .reciever)
        try container.encode(sendDate, forKey: .sendDate)
        
        switch(type){
        
        case .chat:
            try container.encode(obj as? ChatMsg, forKey: .obj)
           break
            
        case .ping:
            try container.encode(obj as? PingMsg, forKey: .obj)
            break
            
        case .pong:
            try container.encode(obj as? PongMsg, forKey: .obj)
            break
        }
    }
}

public struct PingMsg: PeerMsg{}

public struct PongMsg: PeerMsg{}

public struct ChatMsg: PeerMsg{
    public var text : String
}

public struct FileMsg: PeerMsg{
    public var fid : String
    public var name : String
    public var mime : String
    public var blobCount : Int
    public var startTime : Int
    public var length : Int
    public var checkSume : String
}

enum DisplayMode{
    case NONE
    case HOME
    case DEBUG
    case OFFER
    case ANSWER
}


