//
//  InboxViewController.swift
//
//
//
//

import UIKit
import Firebase
import CoreBluetooth

class ChannelViewController: UITableViewController {

    let kTableViewReloadMaxTimeInterval = 1.0
    let kTargetService = "1A2B"
    let kTargetCharacteristic = "3C4D"

    var channels = [Channel]()
    var user = UserDefaults.standard.string(forKey: "screenName")!

    var centralManager: CBCentralManager!
    var allDiscovered = [String:DiscoveredPeripheral]()
    var restServices = [CBService]()
    var talkingPeripheral: CBPeripheral!
    var talkingCharacteristic: CBCharacteristic!
    var detailInfoString: String!

    var shouldStartTalking: Bool = false

    let firebaseManager = FirebaseManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCoreBlueTooth()

//    firebaseManager.getChannels() { channels in
//      self.channels = channels
//      self.tableView.reloadData()
//
//    }

        let view1 = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let mySwitch = UISwitch()
        mySwitch.center = view1.center
        mySwitch.setOn(false, animated: false)
        mySwitch.addTarget(self, action: #selector(onSwitch(_:)), for: .valueChanged)
        view1.addSubview(mySwitch)

        let barButton = UIBarButtonItem(customView: view1)

        navigationItem.rightBarButtonItem = barButton

    }

    func onSwitch(_ sender: UISwitch) {
        if sender.isOn {
            self.startScanning()
        } else {
            centralManager.stopScan()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if shouldStartTalking {
            shouldStartTalking = false
            centralManager.cancelPeripheralConnection(talkingPeripheral)
            allDiscovered = [:]
            restServices = []
        }

    }

    func startScan() {
        let services = [CBUUID]()
        let options = [CBCentralManagerScanOptionAllowDuplicatesKey:true]
        centralManager.scanForPeripherals(withServices: services, options: options)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "msgSegue" {
            if let dest = segue.destination as? MessageViewController {
                if let index = self.tableView.indexPathForSelectedRow?.row {
                    let channel = self.channels[index].name
                    dest.channelId = channel
                    dest.senderId = user
                    dest.senderDisplayName = user
                }
            }
        }
    }


    @IBAction func createBtnPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Create Channel", message: "Create a new channel", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "Channel Name"
        }

        let create = UIAlertAction(title: "Create", style: .default) { (action) in
            if let channel = alertController.textFields?[0].text {
                self.firebaseManager.createChannel(named: channel, withUser: self.user, completion: { (channelCreated) in
                    if channelCreated {
                        self.firebaseManager.add(channel: channel, toUser: self.user)
                    }
                })
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        }
        alertController.addAction(create)
        alertController.addAction(cancel)
        self.present(alertController, animated: true, completion: nil)
    }
}

//MARK: Tableview

extension ChannelViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allDiscovered.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath)
        let allKeys = Array(allDiscovered.keys)
        let target = allDiscovered[allKeys[indexPath.row]]!

        let desc = "\(target.peripheral.name), RSSI: \(target.lastRSSI)"
        let lastSeen = "Last seen\(Date.timeIntervalSince(target.lastSeenDate))"

        cell.textLabel?.text = desc
        cell.detailTextLabel?.text = lastSeen

//      cell.textLabel?.text = channels[indexPath.row].name
//      cell.detailTextLabel?.text = channels[indexPath.row].lastMsg

        return cell
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        shouldStartTalking = false
        connectWith(indexPath: indexPath)
    }

    func connectWith(indexPath: IndexPath) {
        let allKeys = Array(allDiscovered.keys)
        let target = allDiscovered[allKeys[indexPath.row]]!
        centralManager.connect(target.peripheral, options: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        shouldStartTalking = true
        connectWith(indexPath: indexPath)
    }
}

//MARK: CoreBlueTooth

extension ChannelViewController: CBCentralManagerDelegate, CBPeripheralDelegate  {


    func setupCoreBlueTooth() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        if state != .poweredOn {
            print("BLE not available: \(state)")
        }
    }

    func startScanning() {
        let services = [CBUUID]()
        let options = [CBCentralManagerScanOptionAllowDuplicatesKey:true]
        centralManager.scanForPeripherals(withServices: services, options: options)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let uuid = peripheral.identifier.uuidString
        let item = DiscoveredPeripheral(peripheral: peripheral, lastRSSI: RSSI.intValue, lastSeenDate: Date())
        allDiscovered[uuid] = item
        tableView.reloadData()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral: \(peripheral.name)")
        peripheral.delegate = self
        centralManager.stopScan()
        if shouldStartTalking == false {
            peripheral.discoverServices(nil)
        } else {
            let tagetService = CBUUID(string: kTargetService)
            peripheral.discoverServices([tagetService])
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("failed to connect \(error?.localizedDescription)")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnected from \(peripheral.name)")
        self.startScanning()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("discover error: \(error?.localizedDescription)")
            centralManager.cancelPeripheralConnection(peripheral)
            self.startScanning()
            shouldStartTalking = false
            return
        }
        let allServices = peripheral.services
        restServices = allServices!

        if shouldStartTalking == false {
            peripheral .discoverCharacteristics(nil, for: restServices.first!)
        } else if restServices.count > 0 {
            let targetCharacteristics = CBUUID(string: kTargetCharacteristic)
            peripheral.discoverCharacteristics([targetCharacteristics], for: restServices.first!)
        } else {
            centralManager.cancelPeripheralConnection(peripheral)
            self.startScanning()
            shouldStartTalking = false
        }
        if restServices.count > 0 { restServices.remove(at: 0) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("discover chat error: \(error?.localizedDescription)")
            centralManager.cancelPeripheralConnection(peripheral)
            self.startScanning()
            return
        }
        if shouldStartTalking {
            talkingPeripheral = peripheral
            talkingCharacteristic = service.characteristics![0]

            self.performSegue(withIdentifier: "startTalking", sender: nil)
            return
        }

        detailInfoString = "Peripheral: \(peripheral.name), \(peripheral.services?.count)\nService: \(service.uuid.uuidString), \(service.characteristics?.count)"

        for cbc in service.characteristics! {
            detailInfoString.append("\nCharacteristic: \(cbc.uuid.uuidString)")
        }

        if restServices.count == 0 {
            let alertVC = UIAlertController(title: "Results", message: detailInfoString, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                self.centralManager.cancelPeripheralConnection(peripheral)
                self.startScanning()
                self.detailInfoString = ""
            })
            alertVC.addAction(okAction)
            self.present(alertVC, animated: true, completion: nil)
        } else {
            detailInfoString.append("\n")
            peripheral.discoverCharacteristics(nil, for: restServices.first!)
            restServices.remove(at: 0)
        }
    }

}
