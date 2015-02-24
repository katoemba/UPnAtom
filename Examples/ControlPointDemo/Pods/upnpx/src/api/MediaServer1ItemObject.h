// **********************************************************************************
//
// BSD License.
// This file is part of upnpx.
//
// Copyright (c) 2010-2011, Bruno Keymolen, email: bruno.keymolen@gmail.com
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, 
// this list of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice, this 
// list of conditions and the following disclaimer in the documentation and/or other 
// materials provided with the distribution.
// Neither the name of "Bruno Keymolen" nor the names of its contributors may be 
// used to endorse or promote products derived from this software without specific 
// prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
// IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;LOSS OF USE, DATA, OR 
// PROFITS;OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
// POSSIBILITY OF SUCH DAMAGE.
//
// **********************************************************************************

#import <Foundation/Foundation.h>
#import "MediaServer1BasicObject.h"
#import "MediaServer1ItemRes.h"

@interface MediaServer1ItemObject : MediaServer1BasicObject {
    NSString *album;
    NSString *date;
    NSString *genre;
    NSString *originalTrackNumber;
    NSString *uri;//Use uriCollection (uri contains the last element of uriCollection)
    NSString *protocolInfo;//Use uriCollection (protocolInfo contains the last element of uriCollection)
    NSString *frequency;
    NSString *audioChannels;
    NSString *size;
    NSString *duration;
    NSString *icon;
    NSString *bitrate;
    int durationInSeconds;
    NSDictionary *uriCollection;//key: NSString* protocolinfo -> value:NSString* uri
    NSMutableArray *resources;//MediaServer1ItemRes[]
}

-(void)addRes:(MediaServer1ItemRes*) res;

@property(retain, nonatomic) NSString *album;
@property(retain, nonatomic) NSString *date;
@property(retain, nonatomic) NSString *genre;
@property(retain, nonatomic) NSString *originalTrackNumber;
@property(retain, nonatomic) NSString *uri;
@property(retain, nonatomic) NSString *protocolInfo;
@property(retain, nonatomic) NSString *frequency;
@property(retain, nonatomic) NSString *audioChannels;
@property(retain, nonatomic) NSString *size;
@property(retain, nonatomic) NSString *duration;
@property(retain, nonatomic) NSString *icon;
@property(retain, nonatomic) NSString *bitrate;
@property(readwrite) int durationInSeconds;
@property(retain, nonatomic) NSDictionary *uriCollection;
@property(readonly) NSMutableArray *resources;

@property (readwrite, retain) NSMutableArray *creators;
@property (readwrite, retain) NSMutableArray *authors;
@property (readwrite, retain) NSMutableArray *directors;
@property (readwrite, retain) NSString *longDescription;
@property (readwrite, retain) NSString *lastPlaybackPosition;
@property (readwrite, retain) NSString *lastPlaybacktime;
@property (readwrite, retain) NSString *playbackCount;

@end