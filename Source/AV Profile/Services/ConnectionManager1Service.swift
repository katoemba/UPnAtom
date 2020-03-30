//
//  ConnectionManager1Service.swift
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

@objcMembers public class ConnectionManager1Service: AbstractUPnPService {
    public func getProtocolInfo(_ success: @escaping (_ source: [String], _ sink: [String]) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetProtocolInfo", serviceURN: urn, arguments: nil)
        
        soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
            let responseObject = responseObject as? [String: String]
            success(responseObject?["Source"]?.components(separatedBy: ",") ?? [String](), responseObject?["Sink"]?.components(separatedBy: ",") ?? [String]())
            }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                failure(error as NSError)
        })
    }
    
    public func prepareForConnection(remoteProtocolInfo: String, peerConnectionManager: String, peerConnectionID: String, direction: String, success: @escaping (_ connectionID: String?, _ avTransportID: String?, _ renderingControlServiceID: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "RemoteProtocolInfo",remoteProtocolInfo,
            "PeerConnectionManager",peerConnectionManager,
            "PeerConnectionID",peerConnectionID,
            "Direction",direction]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "PrepareForConnection", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "PrepareForConnection" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(responseObject?["ConnectionID"], responseObject?["AVTransportID"], responseObject?["RcsID"])
                    }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                        failure(error as NSError)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(String(describing: self.device?.friendlyName))") as NSError)
            }
        }
    }
    
    public func connectionComplete(connectionID: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = ["ConnectionID",connectionID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "ConnectionComplete", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "ConnectionComplete" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
                    success()
                    }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                        failure(error as NSError)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(String(describing: self.device?.friendlyName))") as NSError)
            }
        }
    }
    
    public func getCurrentConnectionIDs(_ success: @escaping (_ connectionIDs: [String]) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetCurrentConnectionIDs", serviceURN: urn, arguments: nil)
        
        soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
            let responseObject = responseObject as? [String: String]
            success(responseObject?["ConnectionIDs"]?.components(separatedBy: ",") ?? [String]())
            }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                failure(error as NSError)
        })
    }
    
    public func getCurrentConnectionInfo(connectionID: String, success: @escaping (_ renderingControlServiceID: String?, _ avTransportID: String?, _ protocolInfo: String?, _ peerConnectionManager: String?, _ peerConnectionID: String?, _ direction: String?, _ status: String?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let arguments = ["ConnectionID",connectionID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetCurrentConnectionInfo", serviceURN: urn, arguments: arguments)
        soapSessionManager.requestSerializer.timeoutInterval = 3;
        soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
            let responseObject = responseObject as? [String: String]
            success(responseObject?["RcsID"], responseObject?["AVTransportID"], responseObject?["ProtocolInfo"], responseObject?["PeerConnectionManager"], responseObject?["PeerConnectionID"], responseObject?["Direction"], responseObject?["Status"])
            }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                failure(error as NSError)
        })
    }
}

/// for objective-c type checking
extension AbstractUPnP {
    public func isConnectionManager1Service() -> Bool {
        return self is ConnectionManager1Service
    }
}

/// overrides ExtendedPrintable protocol implementation
extension ConnectionManager1Service {
//    override public var className: String { return "\(type(of: self))" }
    override public var description: String {
        let properties = PropertyPrinter()
//        properties.add(super.className, property: super.description)
        return properties.description
    }
}
