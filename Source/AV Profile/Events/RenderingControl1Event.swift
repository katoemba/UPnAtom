//
//  RenderingControl1Event.swift
//  AFNetworking
//
//  Created by 허행 on 2017. 12. 12..
//

import Ono

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
    
    override func parse(document: ONOXMLDocument) -> EmptyResult {
        let result: EmptyResult = .success
        
        // procedural vs series of nested if let's
        guard let lastChangeXMLString = document.firstChild(withXPath: "/e:propertyset/e:property/LastChange")?.stringValue else {
            return .failure(createError("No LastChange element in UPnP service event XML"))
        }
        
        LogVerbose("Parsing LastChange XML:\nSTART\n\(lastChangeXMLString)\nEND")
        
        guard let lastChangeEventDocument = try? ONOXMLDocument(string: lastChangeXMLString, encoding: String.Encoding.utf8.rawValue) else {
            return .failure(createError("Unable to parse LastChange XML"))
        }
        
        lastChangeEventDocument.definePrefix("rcs", forDefaultNamespace: "urn:schemas-upnp-org:metadata-1-0/RCS/")
        lastChangeEventDocument.enumerateElements(withXPath: "/rcs:Event/rcs:InstanceID/*") { [unowned self] (element, index, bool) in

            if let stateValue = element.value(forAttribute: "val") as? String, !stateValue.isEmpty {
                if element.tag.range(of: "MetaData") != nil {
                    guard let metadataDocument = try? ONOXMLDocument(string: stateValue, encoding: String.Encoding.utf8.rawValue) else {
                        return
                    }
                    
                    LogVerbose("Parsing MetaData XML:\nSTART\n\(stateValue)\nEND")
                    
                    var metaData = [String: String]()
                    
                    metadataDocument.definePrefix("didllite", forDefaultNamespace: "urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/")
                    metadataDocument.enumerateElements(withXPath: "/didllite:DIDL-Lite/didllite:item/*") { (metadataElement, index, bool) in
                        if let elementStringValue = metadataElement.stringValue, !elementStringValue.isEmpty {
                            metaData[metadataElement.tag] = elementStringValue
                        }
                    }
                    
                    self._instanceState[element.tag] = metaData as AnyObject
                } else {
                    self._instanceState[element.tag] = stateValue as AnyObject
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
