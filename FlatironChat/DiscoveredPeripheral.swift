//
//  DiscoveredPeripheral.swift
//  FlatironChat
//
//  Created by Alessandro Musto on 3/27/17.
//  Copyright © 2017 Johann Kerr. All rights reserved.
//

import Foundation
import CoreBluetooth

class DiscoveredPeripheral : NSObject {
    var peripheral: CBPeripheral
    var lastRSSI: Int
    var lastSeenDate: Date

    init(peripheral: CBPeripheral, lastRSSI: Int, lastSeenDate: Date) {
        self.peripheral = peripheral
        self.lastRSSI = lastRSSI
        self.lastSeenDate = lastSeenDate
    }
}
