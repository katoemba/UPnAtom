//
//  SSDPExplorerDiscoveryAdapter.swift
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

import Foundation

class SSDPExplorerDiscoveryAdapter: AbstractSSDPDiscoveryAdapter {
    lazy fileprivate var _ssdpExplorer = SSDPExplorer()
    /// Must be accessed and updated within dispatch_sync() or dispatch_async() to a serial queue
    fileprivate var _ssdpDiscoveries = [UniqueServiceName: SSDPDiscovery]()
    
    required init(queue: DispatchQueue) {
        super.init(queue: queue)
        _ssdpExplorer.delegate = self
    }
    
    override func start() {
        super.start()
        
        var types = [SSDPType]() // TODO: Should ideally be a Set<SSDPType>, see Github issue #13
        for rawSSDPType in rawSSDPTypes {
            if let ssdpType = SSDPType(rawValue: rawSSDPType) {
                types.append(ssdpType)
            }
        }
        if let resultError = _ssdpExplorer.initialize(forTypes: types).error {
            failed🔰()
            delegateQueue.async {
                self.delegate?.ssdpDiscoveryAdapter(self, didFailWithError: resultError as NSError)
            }
        }
    }
    
    override func stop() {
        _ssdpExplorer.deinitialize()
        
        delegateQueue.async {
            self._ssdpDiscoveries.removeAll(keepingCapacity: false)
            self.delegate?.ssdpDiscoveryAdapter(self, didUpdateSSDPDiscoveries: Array(self._ssdpDiscoveries.values))
        }
        
        super.stop()
    }
    
    override func search() {
        _ssdpExplorer.searchRequest()
    }
    
    override func failed🔰() {
        NSLog("SSDPExplorerDiscoveryAdapter failed()")
        super.failed🔰()
        self.stop()
        
    }
}

extension SSDPExplorerDiscoveryAdapter: SSDPExplorerDelegate {
    func ssdpExplorer(_ explorer: SSDPExplorer, didMakeDiscovery discovery: SSDPDiscovery) {
        delegateQueue.async {
            self._ssdpDiscoveries[discovery.usn] = discovery
            self.delegate?.ssdpDiscoveryAdapter(self, didUpdateSSDPDiscoveries: Array(self._ssdpDiscoveries.values))
        }
    }
    
    func ssdpExplorer(_ explorer: SSDPExplorer, didRemoveDiscovery discovery: SSDPDiscovery) {
        delegateQueue.async {
            if let discovery = self._ssdpDiscoveries[discovery.usn] {
                self._ssdpDiscoveries.removeValue(forKey: discovery.usn)
                self.delegate?.ssdpDiscoveryAdapter(self, didUpdateSSDPDiscoveries: Array(self._ssdpDiscoveries.values))
            }
        }
    }
    
    func ssdpExplorer(_ explorer: SSDPExplorer, didFailWithError error: NSError) {
        failed🔰()
        delegateQueue.async {
            self.delegate?.ssdpDiscoveryAdapter(self, didFailWithError: error)
        }
    }
}

