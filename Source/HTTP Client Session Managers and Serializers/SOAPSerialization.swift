//
//  SOAPSerialization.swift
//  ControlPointDemo
//
//  SOAPSerialization.swift
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
import AFNetworking
import Fuzi

@objcMembers public class SOAPRequestSerializer: AFHTTPRequestSerializer {
    @objcMembers public class Parameters {
        let soapAction: String
        let serviceURN: String
        let arguments: [String]?
        
        public init(soapAction: String, serviceURN: String, arguments: [String]?) {
            self.soapAction = soapAction
            self.serviceURN = serviceURN
            self.arguments = arguments
        }
    }
    
    override public func request(bySerializingRequest request: URLRequest, withParameters parameters: Any?, error: NSErrorPointer) -> URLRequest? {
        guard let requestParameters = parameters as? Parameters else {
            return nil
        }
        
        let mutableRequest: NSMutableURLRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        
        for (field, value) in self.httpRequestHeaders {
            if request.value(forHTTPHeaderField: field) == nil {
                mutableRequest.setValue(value, forHTTPHeaderField: field)
            }
        }
        
        if mutableRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            if let charSet = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(String.Encoding.utf8.rawValue)) {
                mutableRequest.setValue("text/xml; charset=\"\(charSet)\"", forHTTPHeaderField: "Content-Type")
            }
        }

        let urn = requestParameters.serviceURN
        
        mutableRequest.setValue("\"\(urn)#\(requestParameters.soapAction)\"", forHTTPHeaderField: "SOAPACTION")
        
        var body = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
        body += "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
        body += "<s:Body>"
        body += "<u:\(requestParameters.soapAction) xmlns:u=\"\(urn)\">"
        if let arguments = requestParameters.arguments {
            let argumentsArray = stride(from: 0, to: arguments.count, by: 2).map {
                Array(arguments[$0..<Swift.min($0 + 2, arguments.count)])
            }
            
            for argument in argumentsArray {
                body += "<\(argument[0])>\(argument[1])</\(argument[0])>"
            }
//            for (key, value) in arguments {
//                body += "<\(key)>\(value)</\(key)>"
//            }
        }
        body += "</u:\(requestParameters.soapAction)>"
        body += "</s:Body></s:Envelope>"
        LogVerbose("SOAP request body: \(body)")
        
        mutableRequest.setValue("\(body.utf8.count)", forHTTPHeaderField: "Content-Length")
        
        mutableRequest.httpBody = body.data(using: String.Encoding.utf8, allowLossyConversion: false)
        
        return mutableRequest as URLRequest
    }
}

@objcMembers public class SOAPResponseSerializer: AFXMLParserResponseSerializer {
    override public func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {
        do {
            try validate(response as? HTTPURLResponse, data: data)
        } catch {
            return nil
        }
        let xmlParser = SOAPResponseParser()
        
        guard let data = data else {
            return nil
        }
        
        switch xmlParser.parse(soapResponseData: data) {
        case .success(let value):
            return value
        case .failure(_):
            return nil
        }
    }
}

class SOAPResponseParser: AbstractDOMXMLParser {
    fileprivate var _responseParameters = [String: String]()
    
    override func parse(document: Fuzi.XMLDocument) -> EmptyResult {
        var result: EmptyResult = .success
        for element in document.xpath("/s:Envelope/s:Body/*/*") {
            if let tag = element.tag,
               tag.count > 0 && element.stringValue.count > 0 && element.stringValue != "NOT_IMPLEMENTED" {
                _responseParameters[tag] = element.stringValue
            }

            result = .success
            
        }
        
        LogVerbose("SOAP response values: \(prettyPrint(_responseParameters))")
        
        return result
    }
    
    func parse(soapResponseData: Data) -> Result<[String: String]> {
        switch super.parse(data: soapResponseData) {
        case .success:
            return .success(_responseParameters)
        case .failure(let error):
            return .failure(error as NSError)
        }
    }
}

