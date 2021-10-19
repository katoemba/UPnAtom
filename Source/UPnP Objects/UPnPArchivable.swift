//
//  UPnPArchivable.swift
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

@objcMembers public class UPnPArchivable: NSObject, NSCoding, Codable {
    public let usn: String
    public let descriptionURL: URL
    
    init(usn: String, descriptionURL: URL) {
        self.usn = usn
        self.descriptionURL = descriptionURL
    }
    
    required public init?(coder decoder: NSCoder) {
        self.usn = decoder.decodeObject(forKey: "usn") as! String
        self.descriptionURL = decoder.decodeObject(forKey: "descriptionURL") as! URL
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(usn, forKey: "usn")
        coder.encode(descriptionURL, forKey: "descriptionURL")
    }
}

extension AbstractUPnP {
    public func archivable() -> UPnPArchivable {
        return UPnPArchivable(usn: usn.rawValue, descriptionURL: descriptionURL as URL)
    }
}

@objcMembers public class UPnPArchivableAnnex: UPnPArchivable {
    enum CodingKeys: String, CodingKey {
        case customMetaData = "customMetaData"
    }
    
    /// Use the custom metadata dictionary to re-populate any missing data fields from a custom device or service subclass. While it's not enforced by the compiler, the contents of the meta data must conform to the NSCoding protocol in order to be archivable. Avoided using Swift generics in order to allow compatability with Obj-C.
    public private(set) var customMetadata: [String: String] = [:]
    
    init(usn: String, descriptionURL: URL, customMetadata: [String: String]) {
        self.customMetadata = customMetadata
        super.init(usn: usn, descriptionURL: descriptionURL)
    }
    
    required public init?(coder decoder: NSCoder) {
        self.customMetadata = decoder.decodeObject(forKey: "customMetadata") as! [String: String]
        super.init(coder: decoder)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.customMetadata = try container.decode([String: String].self, forKey: .customMetaData)
    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.customMetadata, forKey: .customMetaData)
    }
    
    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(customMetadata, forKey: "customMetadata")
    }
}

extension AbstractUPnP {
    public func archivable(customMetadata: [String: String]) -> UPnPArchivableAnnex {
        return UPnPArchivableAnnex(usn: usn.rawValue, descriptionURL: descriptionURL as URL, customMetadata: customMetadata)
    }
}

