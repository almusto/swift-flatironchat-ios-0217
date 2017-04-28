//
//  Channel.swift
//  FlatironChat
//
//

import Foundation
import Firebase

struct Channel {
    var name: String
    var lastMsg: String?
    var numberOfParticipants: Int

    init(from dict: FIRDataSnapshot) {
        let channel = dict.value as! [String:Any]
        self.name = dict.key
        self.lastMsg = channel["lastMessage"] as! String?
        let participants = channel["participants"] as! [String:Any]
        self.numberOfParticipants = participants.count
    }
}
