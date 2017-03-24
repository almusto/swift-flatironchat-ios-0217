//
//  FirebaseManager.swift
//  FlatironChat
//
//  Created by Alessandro Musto on 3/24/17.
//  Copyright © 2017 Johann Kerr. All rights reserved.
//

import Foundation
import FirebaseAuth
import Firebase
import JSQMessagesViewController

final class FirebaseManager {
  static let shared = FirebaseManager()
  private init() {}

  private var dbRef: FIRDatabaseReference {
    return FIRDatabase.database().reference()
  }

  func anonymousSignIn(completion: @escaping (String?) -> ()) {
    FIRAuth.auth()?.signInAnonymously() { (user, error) in
      if error != nil {
        completion(nil)
      } else {
        guard let user = user else { completion(nil); return
        }
        completion(user.uid)
      }
    }
  }

  func getChannels(completion: @escaping ([Channel]) -> ()) {
    dbRef.child("channels").observe(.value, with: { snapshot in
      let channels = snapshot.children.flatMap { (child) -> Channel? in
        guard let snapshot = child as? FIRDataSnapshot else { return nil }
        return Channel(from: snapshot)
      }
      completion(channels)
    })
  }

  func createChannel(named channel: String, withUser user: String, completion: @escaping (Bool) -> ()) {
    print("create chan")
    dbRef.child("channels").observeSingleEvent(of: .value, with: { (snapshot) in
      if snapshot.hasChild(channel) { completion(false); return }
      self.dbRef.child("channels").child(channel).child("participants").setValue([user:true])
      completion(true)
    })
  }

  func add(channel: String, toUser user: String) {
    dbRef.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
      if snapshot.hasChild(user) {
        self.dbRef.child("users").child(user).child("channels").updateChildValues([channel: true])
      } else {
        self.dbRef.child("users").child(user).child("channels").setValue([channel: true])
      }
    })
  }

  func getMessages(forChannel channel: String, completion: @escaping ([JSQMessage])-> ()) {
    dbRef.child("messages").child(channel).observe(.value, with: { snapshot in
      var messages = [JSQMessage]()
      for case let snapshots as FIRDataSnapshot in snapshot.children {
        let dict = snapshots.value as! [String:String]
        let body = dict["content"]
        let name = dict["from"] 
        let message = JSQMessage(senderId: name, displayName: name, text: body)
        messages.append(message!)
      }
      completion(messages)
    })
  }

  func add(message: String, fromUser user: String, toChannel channel: String) {
    self.add(channel: channel, toUser: user)
    dbRef.child("channels").child(channel).child("participants").updateChildValues([user: true])
    dbRef.child("channels").child(channel).updateChildValues(["lastMessage":message])
    dbRef.child("messages").observeSingleEvent(of: .value, with: { (snapshot) in
      self.dbRef.child("messages").child(channel).childByAutoId().setValue(["content":message,
                                                                              "from":user])
    })
  }
}
