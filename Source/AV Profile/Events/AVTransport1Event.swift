//
//  AVTransport1Event.swift
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
import Fuzi

@objcMembers public class AVTransport1Event: UPnPEvent {
    public var instanceState = [String: AnyObject]()
    
    override public init(eventXML: Data, service: AbstractUPnPService) {
        super.init(eventXML: eventXML, service: service)
        
        if let parsedInstanceState = AVTransport1EventParser().parse(eventXML: eventXML).value {
            instanceState = parsedInstanceState
        }
    }
}

/// for objective-c type checking
extension UPnPEvent {
    public func isAVTransport1Event() -> Bool {
        return self is AVTransport1Event
    }
}

class AVTransport1EventParser: AbstractDOMXMLParser {
    fileprivate var _instanceState = [String: AnyObject]()
    
    override func parse(document: Fuzi.XMLDocument) -> EmptyResult {
        let result: EmptyResult = .success
        
        // procedural vs series of nested if let's
        guard let lastChangeXMLString = document.firstChild(xpath: "/e:propertyset/e:property/LastChange")?.stringValue else {
            return .failure(createError("No LastChange element in UPnP service event XML"))
        }
        
        LogVerbose("Parsing LastChange XML:\nSTART\n\(lastChangeXMLString)\nEND")
        
        guard let lastChangeEventDocument = try? Fuzi.XMLDocument(string: lastChangeXMLString, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) else {
            return .failure(createError("Unable to parse LastChange XML"))
        }
        
        lastChangeEventDocument.definePrefix("avt", forNamespace: "urn:schemas-upnp-org:metadata-1-0/AVT/")
        for element in lastChangeEventDocument.xpath("/avt:Event/avt:InstanceID/*") {
            if let stateValue = element.attr("val"), !stateValue.isEmpty, let tag = element.tag {
                if tag.range(of: "MetaData") != nil {
                    guard let metadataDocument = try? Fuzi.XMLDocument(string: stateValue, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) else {
                        break
                    }
                    
                    LogVerbose("Parsing MetaData XML:\nSTART\n\(stateValue)\nEND")
                    
                    var metaData = [String: String]()
                    
                    metadataDocument.definePrefix("didllite", forNamespace: "urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/")
                    for metadataElement in metadataDocument.xpath("/didllite:DIDL-Lite/didllite:item/*") {
                        if let tag = metadataElement.tag, metadataElement.stringValue != "" {
                            metaData[tag] = metadataElement.stringValue
                        }
                    }
                    
                    _instanceState[tag] = metaData as AnyObject
                } else {
                    _instanceState[tag] = stateValue as AnyObject
                }
            }
        }
        
        return result
    }
    
    func parse(eventXML: Data) -> Result<[String: AnyObject]> {
        switch super.parse(data: eventXML) {
        case .success:
            return .success(_instanceState)
        case .failure(let error):
            return .failure(error as NSError)
        }
    }
}

