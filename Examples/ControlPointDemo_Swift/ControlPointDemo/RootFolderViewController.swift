//
//  RootFolderViewController.swift
//
//  Copyright (c) 2015 David Robles
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit
import UPnAtom

class RootFolderViewController: UIViewController {
    private var _discoveredDeviceUSNs = [UniqueServiceName]()
    private var _discoveredUPnPObjectCache = [UniqueServiceName: AbstractUPnP]()
    private var _archivedDeviceUSNs = [UniqueServiceName]()
    private var _archivedUPnPObjectCache = [UniqueServiceName: AbstractUPnP]()
    private static let upnpObjectArchiveKey = "upnpObjectArchiveKey"
    private var _toolbarLabel: UILabel!
    private var _timeLabel: UILabel!
    @IBOutlet private weak var _tableView: UITableView!
    private let _archivingUnarchivingQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Archiving and unarchiving queue"
        return queue
    }()

    var playPauseButton: UIBarButtonItem!
    var stopButton: UIBarButtonItem!

    let dlnaPlayer = DLNAPlayer.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        playPauseButton = UIBarButtonItem(image: UIImage(named: "play_button"), style: .plain, target: self, action: #selector(playPauseButtonTapped(_:)))
       stopButton = UIBarButtonItem(image: UIImage(named: "stop_button"), style: .plain, target: self, action: #selector(stopButtonTapped(_:)))
        
        // initialize
        UPnAtom.sharedInstance.ssdpTypes = [
            SSDPTypeConstant.All.rawValue,
            SSDPTypeConstant.MediaServerDevice1.rawValue,
            SSDPTypeConstant.MediaRendererDevice1.rawValue,
            SSDPTypeConstant.ContentDirectory1Service.rawValue,
            SSDPTypeConstant.ConnectionManager1Service.rawValue,
            SSDPTypeConstant.RenderingControl1Service.rawValue,
            SSDPTypeConstant.AVTransport1Service.rawValue
        ]
        
        loadArchivedUPnPObjects()
        
        self.title = "Control Point Demo"
        
        _toolbarLabel = UILabel()
        _toolbarLabel.font = UIFont(name: "Helvetica", size: 16)
        _toolbarLabel.backgroundColor = UIColor.red

        _timeLabel = UILabel()

        let barButton = UIBarButtonItem(customView: UIStackView(arrangedSubviews: [_toolbarLabel, _timeLabel]))
        self.toolbarItems = [playPauseButton, stopButton, barButton]
        
        self.navigationController?.isToolbarHidden = false

        dlnaPlayer.delegate = self
    }

    @objc func playPauseButtonTapped(_ sender: Any) {
        dlnaPlayer.playPauseButtonTapped()
    }

    @objc func stopButtonTapped(_ sender: Any) {
        dlnaPlayer.stopButtonTapped()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(RootFolderViewController.deviceWasAdded(_:)), name: NSNotification.Name(rawValue: UPnPRegistry.UPnPDeviceAddedNotification()), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RootFolderViewController.deviceWasRemoved(_:)), name: NSNotification.Name(rawValue: UPnPRegistry.UPnPDeviceRemovedNotification()), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RootFolderViewController.serviceWasAdded(_:)), name: NSNotification.Name(rawValue: UPnPRegistry.UPnPServiceAddedNotification()), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RootFolderViewController.serviceWasRemoved(_:)), name: NSNotification.Name(rawValue: UPnPRegistry.UPnPServiceRemovedNotification()), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UPnPRegistry.UPnPDeviceAddedNotification()), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UPnPRegistry.UPnPDeviceRemovedNotification()), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UPnPRegistry.UPnPServiceAddedNotification()), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UPnPRegistry.UPnPServiceRemovedNotification()), object: nil)
        
        super.viewDidDisappear(animated)
        UPnAtom.sharedInstance.stop()
    }
    
    @IBAction func discoverButtonTapped(_ sender: AnyObject) {
        performSSDPDiscovery()
    }
    
    @IBAction func archiveButtonTapped(_ sender: AnyObject) {
        archiveUPnPObjects()
    }

    @objc private func deviceWasAdded(_ notification: NSNotification) {
        if let upnpDevice = notification.userInfo?[UPnPRegistry.UPnPDeviceKey()] as? AbstractUPnPDevice {
            print("Added device: \(upnpDevice.className) - \(upnpDevice.friendlyName)")
            
            _discoveredUPnPObjectCache[upnpDevice.usn] = upnpDevice
            insertDevice(deviceUSN: upnpDevice.usn, inSection: 1)
        }
    }
    
    @objc private func deviceWasRemoved(_ notification: NSNotification) {
        if let upnpDevice = notification.userInfo?[UPnPRegistry.UPnPDeviceKey()] as? AbstractUPnPDevice {
            print("Removed device: \(upnpDevice.className) - \(upnpDevice.friendlyName)")
            
            _discoveredUPnPObjectCache.removeValue(forKey: upnpDevice.usn)
            deleteDevice(deviceUSN: upnpDevice.usn, inSection: 1)
        }
    }
    
    @objc private func serviceWasAdded(_ notification: NSNotification) {
        if let upnpService = notification.userInfo?[UPnPRegistry.UPnPServiceKey()] as? AbstractUPnPService {
            let friendlyName = (upnpService.device != nil) ? upnpService.device!.friendlyName : "Service's device object not created yet"
            print("Added service: \(upnpService.className) - \(friendlyName)")
            
            _discoveredUPnPObjectCache[upnpService.usn] = upnpService
        }
    }
    
    @objc private func serviceWasRemoved(_ notification: NSNotification) {
        if let upnpService = notification.userInfo?[UPnPRegistry.UPnPServiceKey()] as? AbstractUPnPService {
            let friendlyName = (upnpService.device != nil) ? upnpService.device!.friendlyName : "Service's device object not created yet"
            print("Removed service: \(upnpService.className) - \(friendlyName)")
            
            _discoveredUPnPObjectCache[upnpService.usn] = upnpService
        }
    }
    
    private func deviceCountForTableSection(section: Int) -> Int {
        return section == 0 ? _archivedDeviceUSNs.count : _discoveredDeviceUSNs.count
    }
    
    private func deviceForIndexPath(indexPath: IndexPath) -> AbstractUPnPDevice {
        let deviceUSN = indexPath.section == 0 ? _archivedDeviceUSNs[indexPath.row] : _discoveredDeviceUSNs[indexPath.row]
        let deviceCache = indexPath.section == 0 ? _archivedUPnPObjectCache : _discoveredUPnPObjectCache
        return deviceCache[deviceUSN] as! AbstractUPnPDevice
    }
    
    private func insertDevice(deviceUSN: UniqueServiceName, inSection section: Int) {
        var devices = _discoveredDeviceUSNs
        if section == 0 {
            devices = _archivedDeviceUSNs
        }
        let index = devices.count
        devices.insert(deviceUSN, at: index)
        if section == 0 {
            _archivedDeviceUSNs = devices
        } else {
            _discoveredDeviceUSNs = devices
        }
        let indexPath = IndexPath(row: index, section: section)
        self._tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    private func deleteDevice(deviceUSN: UniqueServiceName, inSection section: Int) {
        var devices = _discoveredDeviceUSNs
        if section == 0 {
            devices = _archivedDeviceUSNs
        }
        if let index = devices.firstIndex(of: deviceUSN) {
            devices.remove(at: index)
            if section == 0 {
                _archivedDeviceUSNs = devices
            } else {
                _discoveredDeviceUSNs = devices
            }
            let indexPath = IndexPath(row: index, section: section)
            self._tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    private func performSSDPDiscovery() {
        if UPnAtom.sharedInstance.ssdpDiscoveryRunning() {
            UPnAtom.sharedInstance.restart()
        }
        else {
            UPnAtom.sharedInstance.start()
        }
        UPnAtom.sharedInstance.search()
    }
    
    private func archiveUPnPObjects() {
        _archivingUnarchivingQueue.addOperation { () -> Void in
            // archive discovered objects
            var upnpArchivables = [UPnPArchivableAnnex]()
            for (_, upnpObject) in self._discoveredUPnPObjectCache {
                var friendlyName = "Unknown"
                if let upnpDevice = upnpObject as? AbstractUPnPDevice {
                    friendlyName = upnpDevice.friendlyName
                }
                else if let upnpService = upnpObject as? AbstractUPnPService,
                    let name = upnpService.device?.friendlyName {
                        friendlyName = name
                }
                
                let upnpArchivable = upnpObject.archivable(customMetadata: ["upnpType": upnpObject.className, "friendlyName": friendlyName])
                upnpArchivables.append(upnpArchivable)
            }
            
            let upnpArchivablesData = NSKeyedArchiver.archivedData(withRootObject: upnpArchivables)
            UserDefaults.standard.set(upnpArchivablesData, forKey: RootFolderViewController.upnpObjectArchiveKey)
            
            // show archive complete alert
            OperationQueue.main.addOperation({ () -> Void in
                let alertController = UIAlertController(title: "Archive Complete!", message: "Load archive and reload table view? If cancelled you'll see the archived devices on the next launch.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                    self.loadArchivedUPnPObjects()
                }))
                self.present(alertController, animated: true, completion: nil)
            })
        }
    }
    
    private func loadArchivedUPnPObjects() {
        // clear previously loaded archive devices
        if _archivedDeviceUSNs.count > 0 {
            var currentArchivedDeviceIndexes = [IndexPath]()
            for i: Int in 0 ..< _archivedDeviceUSNs.count {
                currentArchivedDeviceIndexes.append(IndexPath(row: i, section: 0))
            }
            
            _archivedDeviceUSNs.removeAll(keepingCapacity: false)
            _tableView.deleteRows(at: currentArchivedDeviceIndexes, with: .automatic)
        }
        
        // clear archive model
        _archivedUPnPObjectCache.removeAll(keepingCapacity: false)
        
        _archivingUnarchivingQueue.addOperation { () -> Void in
            // load archived objects
            if let upnpArchivablesData = UserDefaults.standard.object(forKey: RootFolderViewController.upnpObjectArchiveKey) as? NSData {
                let upnpArchivables = NSKeyedUnarchiver.unarchiveObject(with: upnpArchivablesData as Data) as! [UPnPArchivableAnnex]
                
                for upnpArchivable in upnpArchivables {
                    let upnpType = upnpArchivable.customMetadata["upnpType"]
                    let friendlyName = upnpArchivable.customMetadata["friendlyName"]
                    print("Unarchived upnp object from cache \(upnpType) - \(friendlyName)")
                    
                    UPnAtom.sharedInstance.upnpRegistry.createUPnPObject(upnpArchivable: upnpArchivable, callbackQueue: OperationQueue.main, success: { (upnpObject: AbstractUPnP) -> Void in
                        print("Re-created upnp object \(upnpObject.className) - \(friendlyName)")
                        
                        self._archivedUPnPObjectCache[upnpObject.usn] = upnpObject
                        
                        if let upnpDevice = upnpObject as? AbstractUPnPDevice {
                            upnpDevice.serviceSource = self
                            
                            self.insertDevice(deviceUSN: upnpDevice.usn, inSection: 0)
                        }
                        else if let upnpService = upnpObject as? AbstractUPnPService {
                            upnpService.deviceSource = self
                        }
                        }, failure: { (error: NSError) -> Void in
                            print("Failed to create UPnP Object from archive")
                    })
                }
            }
            else {
                OperationQueue.main.addOperation({ () -> Void in
                    self.performSSDPDiscovery()
                })
            }
        }
    }
}

extension RootFolderViewController: DLNAPlayerDelegate {

    func player(_ player: DLNAPlayer, didChanged state: DLNAPlayerState) {
        switch state {
        case .stopped, .paused, .unknown:
            playPauseButton.image = UIImage(named: "play_button")
        case .playing:
            playPauseButton.image = UIImage(named: "pause_button")
        }
    }

    func player(_ player: DLNAPlayer, playFailed error: Error) {
        print("Error: \(error)")
    }

    func player(_ player: DLNAPlayer, pauseFailed error: Error) {
        print("Error: \(error)")
    }

    func player(_ player: DLNAPlayer, stopFailed error: Error) {
        print("Error: \(error)")
    }

    func player(_ player: DLNAPlayer, didChanged totalSeconds: Double, elapsedSeconds: Double) {
        DispatchQueue.main.async { [_timeLabel] in
            _timeLabel?.text = "\(elapsedSeconds)/\(totalSeconds)"
        }
    }

    func playerDidEndPlayback(_ player: DLNAPlayer) {
        dlnaPlayer.startPlayback(uri: "http://192.168.1.2:7383/1562345153.mp4")
    }

}

extension RootFolderViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Archived Devices" : "Discovered Devices"
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceCountForTableSection(section: section)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell")!
        cell.backgroundColor = .white
        let device = deviceForIndexPath(indexPath: indexPath)
        cell.textLabel?.text = device.friendlyName
        cell.accessoryType = device is MediaServer1Device ? .disclosureIndicator : .none
        
        return cell
    }
}

extension RootFolderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = deviceForIndexPath(indexPath: indexPath)

        if let mediaServer = device as? MediaServer1Device {
            if mediaServer.contentDirectoryService == nil {
                print("\(mediaServer.friendlyName) - has no content directory service")
                return
            }
            
            let targetViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FolderViewControllerScene") as! FolderViewController
            targetViewController.configure(mediaServer: mediaServer, title: "Root", contentDirectoryID: "0")
            self.navigationController?.pushViewController(targetViewController, animated: true)
            
            dlnaPlayer.mediaServer = mediaServer
        }
        else if let mediaRenderer = device as? MediaRenderer1Device {
            if mediaRenderer.avTransportService == nil {
                print("\(mediaRenderer.friendlyName) - has no AV transport service")
                return
            }
            
            _toolbarLabel?.text = mediaRenderer.friendlyName
            dlnaPlayer.mediaRenderer = mediaRenderer
            dlnaPlayer.startPlayback(uri: "http://techslides.com/demos/sample-videos/small.webm")
        }
    }
}

extension RootFolderViewController: UPnPServiceSource {
    func service(forUSN usn: UniqueServiceName) -> AbstractUPnPService? {
        return _archivedUPnPObjectCache[usn] as? AbstractUPnPService
    }
}

extension RootFolderViewController: UPnPDeviceSource {
    func device(forUSN usn: UniqueServiceName) -> AbstractUPnPDevice? {
        return _archivedUPnPObjectCache[usn] as? AbstractUPnPDevice
    }
}
