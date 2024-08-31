//
//  Controller.swift
//  RSession2
//
//  Created by mat on 8/11/24.
//

import SwiftUI

struct TransferJob{
    var jid :Int32 = 0
    let created = Date()
    var data : Data?
    var length = 0
    var sendPointer = 0
}

struct BlobMessage{
    var jid : Int32 = 0
    var blockId : Int32 = 0
    var sendPointer : Int32 = 0
    var length : Int32 = 0
    var checksum : Int32 = 0
    var data : Data?
    
    func getData() ->Data{
        var dsum = withUnsafeBytes(of: jid) { Data($0) }
        dsum += withUnsafeBytes(of: blockId) { Data($0) }
        dsum += withUnsafeBytes(of: sendPointer) { Data($0) }
        dsum += withUnsafeBytes(of: length) { Data($0) }
        dsum += withUnsafeBytes(of: checksum) { Data($0) }
        dsum += data!
        return dsum
    }
    
    init(){
        
    }
    
    init(data:Data){
         jid = data[0...3].int32
         blockId = data[4...7].int32
         sendPointer = data[8...11].int32
         length = data[12...15].int32
         checksum = data[16...19].int32
        self.data = data[20...19 + length]
    }
}

extension Data {
    var int32: Int32 { withUnsafeBytes({ $0.load(as: Int32.self) }) }
    var float32: Float32 { withUnsafeBytes({ $0.load(as: Float32.self) }) }
}

class Controller{
    
    let BLOCKSIZE = 1500
    
    var jobId :Int32 = 0
    
    static let shared = Controller()
    
    let jsonDecoder = JSONDecoder()
    let jsonEncoder = JSONEncoder()
    var pingSendAt = 0
    
    var transferJobs = [TransferJob]()
    
    func send(blob:BlobMessage){
        print(blob)
        // todo message header - throwtling - checkusm rerequest message - check delivered thread
        Model.shared.webRtcClient.sendData(blob.getData())
    }
    
    func sendFile(url:URL){
        Task{
            do {
                var job = TransferJob()
                job.jid = jobId
                jobId += 1
                let data = try Data(contentsOf: url)
                job.data = data
                transferJobs.append(job)
               
                // var blockCount = job.data!.count / BLOCKSIZE
                var blockId :Int32 = 0
                while(job.sendPointer < job.data!.count){
                    let lengtToSend  = abs(min(BLOCKSIZE, job.data!.count - Int(job.sendPointer)))
                    var bm = BlobMessage()
                    bm.jid = job.jid
                    bm.blockId = blockId
                    bm.sendPointer = Int32(job.sendPointer)
                    bm.length = Int32(lengtToSend)
                    bm.checksum = Int32(lengtToSend)
                    let myrange : Range<Data.Index> = job.sendPointer..<(job.sendPointer + lengtToSend)
                    bm.data = job.data!.subdata(in:myrange)
                    send(blob: bm)
                    blockId += 1
                    job.sendPointer += BLOCKSIZE
                }
            }
            catch {
                print(error)
            }
        }
    }
    
    func setRemoteTracks(){
        Task{
            await Model.shared.webRtcClient.remoteTracks()
        }
    }
    
    func chatSend(text:String){
        Task{
            do{
                let chatMsg = ChatMsg(text: text)
                let msg = ChannelMsg(type: .chat, sender: Model.shared.sessionId, reciever: "", obj: chatMsg, sendDate: Int(Date().timeIntervalSince1970 * 1000.0))
                let datas = try jsonEncoder.encode(msg)
                let jsons = String(decoding: datas, as: UTF8.self)
                Model.shared.webRtcClient.sendText(json: jsons)
            }
            catch{
                print(error)
            }
        }
    }
    
    func handleBinary(data:Data){
        var blob = BlobMessage(data: data)
        print("id \(blob.blockId) jid \(blob.jid)  sendPointer \(blob.length)  id \(blob.length) checksum \(blob.checksum)")
        print("Data \(data.count)")
    }
    
    func handle(json:String){
        do{
            let data = json.data(using: .utf8)
            let msg : ChannelMsg = try jsonDecoder.decode(ChannelMsg.self, from:data! )
            switch(msg.type){
                
            case .chat:
                let chatMsg = msg.obj as? ChatMsg
                DispatchQueue.main.async {
                    Model.shared.chatReceived += chatMsg!.text + "\n"
                }
                break
                
            case .ping:
                Task{
                    pingSendAt = Int(Date().timeIntervalSince1970 * 1000.0)
                    let msg = ChannelMsg(type: .pong, sender: Model.shared.sessionId, reciever: "", obj: PongMsg(), sendDate:pingSendAt)
                    sendMsg(msg:msg)
                }
                break
                
            case .pong:
                DispatchQueue.main.async {
                    let now = Int(Date().timeIntervalSince1970 * 1000.0)
                    Model.shared.pongLatency = now - msg.sendDate
                }
                break
                
            case .file:
                break
            }
        }catch{
            print(error)
        }
    }
    
    func ping(){
        let msg = ChannelMsg(type: .ping, sender: Model.shared.sessionId, reciever: "", obj: PingMsg(), sendDate:Int(Date().timeIntervalSince1970))
        sendMsg(msg:msg)
    }

    func sendMsg(msg:ChannelMsg){
        Task{
            do{
                let data = try jsonEncoder.encode(msg)
                let json = String(decoding: data, as: UTF8.self)
                Model.shared.webRtcClient.sendText(json: json)
            }
            catch{
                print(error)
            }
        }
    }
    
    func sendInviteSignal(){
        let session = Session(sessionId: Model.shared.sessionId, tracks:Model.shared.tracks, room: Model.shared.room)
        let req = SignalReq(cmd:"invite" ,receiver:"", session:session )
        SignalClient.shared.send(req: req)
    }
    
    func sendUpdateSignal(receiver:String){
        let session = Session(sessionId: Model.shared.sessionId, tracks:Model.shared.tracks, room: Model.shared.room)
        let req = SignalReq(cmd:"update", receiver:receiver, session:session )
        SignalClient.shared.send(req: req)
    }
    
    func updateAudioInputDevice(name:String){
        guard let device = Model.shared.getAudioInDevice(name: name)else{
            return
        }
        Model.shared.audioInDevice = name
        UserDefaults.standard.set(name, forKey: "audioIn")
        AudioDeviceManager().setInputDevice(uid: device.id)
    }
    
    func updateAudioOutputDevice(name:String){
        guard let device = Model.shared.getAudioInDevice(name: name)else{
            return
        }
        Model.shared.audioOutDevice = name
        UserDefaults.standard.set(name, forKey: "audioOut")
        AudioDeviceManager().setOutputDevice(uid: device.id)
    }
}
