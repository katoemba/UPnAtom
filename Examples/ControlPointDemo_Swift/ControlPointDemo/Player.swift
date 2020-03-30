//
//  Player.swift
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

protocol DLNAPlayerDelegate: NSObjectProtocol {
    func player(_ player: DLNAPlayer, didChanged state: DLNAPlayerState)
    func player(_ player: DLNAPlayer, didChanged totalSeconds: Double, elapsedSeconds: Double)
    func playerDidEndPlayback(_ player: DLNAPlayer)
    func player(_ player: DLNAPlayer, playFailed error: Error)
    func player(_ player: DLNAPlayer, pauseFailed error: Error)
    func player(_ player: DLNAPlayer, stopFailed error: Error)
}

enum DLNAPlayerState {
    case unknown
    case stopped
    case playing
    case paused
}

private let _PlayerSharedInstance = DLNAPlayer()

class DLNAPlayer {
    class var sharedInstance: DLNAPlayer {
        return _PlayerSharedInstance
    }
    var mediaServer: MediaServer1Device?
    var mediaRenderer: MediaRenderer1Device? {
        didSet {
            didSetRenderer(oldRenderer: oldValue, newRenderer: mediaRenderer)
        }
    }
    
    private var _avTransportEventObserver: AnyObject?

    private var _playerState: DLNAPlayerState = .stopped {
        didSet {
            playerStateDidChange()
        }
    }
    
    private var _avTransportInstanceID = "0"

    weak var delegate: DLNAPlayerDelegate?
    
    init() {

    }

    func startPlayback(uri: String) {
        mediaRenderer?.avTransportService?.setAVTransportURI(instanceID: _avTransportInstanceID,
                                                             currentURI: uri,
                                                             currentURIMetadata: "",
                                                             success: { [weak self] in
                                                                self?.play(success: {}, failure: { [weak self] error in
                                                                    guard let self = self else { return }
                                                                    self.delegate?.player(self, playFailed: error as Error)
                                                                })

            }, failure: { [weak self] error in
                guard let self = self else { return }
                self.delegate?.player(self, playFailed: error as Error)
        })
    }

    func startNextPlayback(uri: String) {
        mediaRenderer?.avTransportService?.setNextAVTransportURI(instanceID: _avTransportInstanceID,
                                                                 nextURI: uri,
                                                                 nextURIMetadata: "",
                                                                 success: {},
                                                                 failure: { error in
                                                                    print("Error: \(error)")
        })
    }

    func playPauseButtonTapped() {
        switch _playerState {
        case .playing:
            pause(success: { }, failure: { [weak self] error in
                guard let self = self else { return }
                self.delegate?.player(self, pauseFailed: error as Error)
            })
        case .paused, .stopped:
            play(success: { }, failure: { [weak self] error in
                guard let self = self else { return }
                self.delegate?.player(self, playFailed: error as Error)
            })
        default:
            self.delegate?.player(self, playFailed: "Play/pause button cannot be used in this state.")
        }
    }
    
    func stopButtonTapped() {

        switch _playerState {
        case .playing, .paused:
            stop(success: { }, failure: { [weak self] error in
                guard let self = self else { return }
                self.delegate?.player(self, stopFailed: error as Error)
            })
        default:
            self.delegate?.player(self, stopFailed: "Stop button cannot be used in this state.")
        }
    }
    
    private func didSetRenderer(oldRenderer: MediaRenderer1Device?, newRenderer: MediaRenderer1Device?) {
        if let avTransportEventObserver: AnyObject = _avTransportEventObserver {
            oldRenderer?.avTransportService?.removeEventObserver(avTransportEventObserver)
        }
        
        _avTransportEventObserver = newRenderer?.avTransportService?.addEventObserver(OperationQueue.current, callBackBlock: { (event: UPnPEvent) -> Void in
            if let avTransportEvent = event as? AVTransport1Event,
                let transportState = (avTransportEvent.instanceState["TransportState"] as? String)?.lowercased() {
                if transportState.range(of: "playing") != nil {
                    self._playerState = .playing
                } else if transportState.range(of: "paused") != nil {
                    self._playerState = .paused
                } else if transportState.range(of: "stopped") != nil {
                    self._playerState = .stopped
                } else {
                    self._playerState = .unknown
                }
            } else {
                print(event)
            }
        })
    }

    private var infoPollingTimer: Timer?
    private func playerStateDidChange() {
        if self._playerState == .playing {
            self.startPollingForInfo()
        } else {
            self.stopPollingForInfo()
        }
        self.delegate?.player(self, didChanged: self._playerState)
        if self._playerState == .stopped, triggerFinishOnNextStop {
            self.delegate?.playerDidEndPlayback(self)
            self.triggerFinishOnNextStop = false
        }
    }

    private func startPollingForInfo() {
        stopPollingForInfo()
        guard infoPollingTimer == nil else { return }
        self.infoPollingTimer = Timer.scheduledTimer(timeInterval: 1,
                                                     target: self,
                                                     selector: #selector(startPollingForInfoTimer),
                                                     userInfo: nil,
                                                     repeats: true)
    }
    var triggerFinishOnNextStop = false
    @objc func startPollingForInfoTimer() {
        self.mediaRenderer?.avTransportService?.getPositionInfo(instanceID: _avTransportInstanceID,
                                                                success: { [weak self] (track, trackDuration,  trackMetaData, trackURI, relativeTime, absoluteTime, relativeCount, absoluteCount) in
                                                                    guard let self = self,
                                                                        let totalSeconds = trackDuration?.inSeconds,
                                                                        let elapsedSeconds = relativeTime?.inSeconds else { return }
                                                                    self.delegate?.player(self, didChanged: totalSeconds, elapsedSeconds: elapsedSeconds)
                                                                    self.triggerFinishOnNextStop = totalSeconds - elapsedSeconds <= 1.5
            }, failure: { (error) in
                print("Error: \(error)")
        })
    }

    private func stopPollingForInfo() {
        infoPollingTimer?.invalidate()
        infoPollingTimer = nil
    }
    
    private func play(success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        self.mediaRenderer?.avTransportService?.play(instanceID: _avTransportInstanceID, speed: "1", success: success, failure: failure)
    }
    
    private func pause(success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        self.mediaRenderer?.avTransportService?.pause(instanceID: _avTransportInstanceID, success: success, failure: failure)
    }
    
    private func stop(success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        self.mediaRenderer?.avTransportService?.stop(instanceID: _avTransportInstanceID, success: success, failure: failure)
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

extension String {
    /**
     Converts a string of format HH:mm:ss into seconds
     ### Expected string format ###
     ````
     HH:mm:ss or mm:ss
     ````
     ### Usage ###
     ````
     let string = "1:10:02"
     let seconds = string.inSeconds  // Output: 4202
     ````
     - Returns: Seconds in Int or if conversion is impossible, 0
     */
    var inSeconds : Double {
        var total = 0.0
        let secondRatio: [Double] = [1, 60, 3600]    // ss:mm:HH
        for (i, item) in self.components(separatedBy: ":").reversed().enumerated() {
            if i >= secondRatio.count { break }
            total = total + (Double(item) ?? 0) * secondRatio[i]
        }
        return total
    }
}
