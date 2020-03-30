//
//  UPnpTest.m
//  UPnpAtom
//
//  Created by henry on 15/04/2019.
//  Copyright © 2019 Kakao. All rights reserved.
//

#import "UPnpTest.h"
#import "UPnpAtom-Swift.h"
@implementation UPnpTest
-(void)start {
    [UPnAtom sharedInstance].ssdpTypes = [[NSSet alloc] initWithArray:@[
                                                                        @"ssdp:all",
                                                                        @"urn:schemas-upnp-org:device:MediaRenderer:1",
                                                                        @"urn:schemas-upnp-org:service:ConnectionManager:1",
                                                                        @"urn:schemas-upnp-org:service:RenderingControl:1",
                                                                        @"urn:schemas-upnp-org:service:AVTransport:1"
                                                                        ]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceWasAdded:) name:[UPnPRegistry UPnPDeviceAddedNotification] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceWasRemoved:) name:[UPnPRegistry UPnPDeviceRemovedNotification] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serviceWasAdded:) name:[UPnPRegistry UPnPServiceAddedNotification] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serviceWasRemoved:) name:[UPnPRegistry UPnPServiceRemovedNotification] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoveryError:) name:[UPnPRegistry UPnPDiscoveryErrorNotification] object:nil];
    
}
@end
