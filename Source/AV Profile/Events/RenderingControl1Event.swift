//
//  RenderingControl1Event.swift
//  AFNetworking
//
//  Created by 허행 on 2017. 12. 12..
//

import Foundation
import Fuzi

@objcMembers public class RenderingControl1Event: UPnPEvent {
    public var instanceState = [String: AnyObject]()
    
    override public init(eventXML: Data, service: AbstractUPnPService) {
        super.init(eventXML: eventXML, service: service)
        
        if let parsedInstanceState = RenderingControl1EventParser().parse(eventXML: eventXML).value {
            instanceState = parsedInstanceState
        }
    }

}
extension UPnPEvent {
    public func isRenderingControl1Event() -> Bool {
        return self is RenderingControl1Event
    }
}

class RenderingControl1EventParser: AbstractDOMXMLParser {
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
        
        lastChangeEventDocument.definePrefix("rcs", forNamespace: "urn:schemas-upnp-org:metadata-1-0/RCS/")
        for element in lastChangeEventDocument.xpath("/rcs:Event/rcs:InstanceID/*") {
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
