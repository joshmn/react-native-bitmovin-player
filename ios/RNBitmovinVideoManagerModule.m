//
//  RNBitmovinVideoManagerModule.m
//  RNBitmovinPlayer
//
//  Created by HugoDuarte on 21/01/20.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RNBitmovinVideoManagerModule.h"
#import <BitmovinPlayer/BMPOfflineManagerListener.h>
#import <React/RCTLog.h>

BMPSourceItem *sourceItem;
BMPOfflineManager *offlineManager;

@implementation RNBitmovinVideoManagerModule

RCT_EXPORT_MODULE();

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"onDownloadCompleted", @"onDownloadProgress", @"onDownloadError", @"onDownloadCanceled", @"onDownloadSuspended", @"onState"];
}

RCT_EXPORT_METHOD(download: (nonnull NSDictionary *)configuration){

    if (!configuration[@"url"]) {
        [self sendEventWithName:@"onDownloadError" body:@"URL is not provided"];
        return ;
    }

    [BMPOfflineManager initializeOfflineManager];
    offlineManager = [BMPOfflineManager sharedInstance];

    sourceItem = [[BMPSourceItem alloc] initWithUrl:(NSURL *) [NSURL URLWithString:configuration[@"url"]]];

    if(configuration[@"title"]){
        sourceItem.itemTitle = configuration[@"title"];
    }

    Boolean isPlayable = [offlineManager isSourceItemPlayableOffline:(BMPSourceItem *) sourceItem];
    Boolean downloaded = [offlineManager offlineStateForSourceItem:sourceItem] == 0;

    if (isPlayable && downloaded){
        [self sendEventWithName:@"onDownloadCompleted" body:@{@"source": [sourceItem toJsonData]}];
        return ;
    }

//    check if the status is downloaded
    if (downloaded) {
        [offlineManager deleteOfflineDataForSourceItem:sourceItem];
    }

    [offlineManager addListener:self forSourceItem:sourceItem];
    [offlineManager downloadSourceItem:sourceItem];
}

- (void)offlineManager:(nonnull BMPOfflineManager *)offlineManager didFailWithError:(nullable NSError *)error {
    offlineManager = offlineManager;
    [self sendEventWithName:@"onDownloadError" body:[error description]];
}

- (void)offlineManager:(nonnull BMPOfflineManager *)offlineManager didProgressTo:(double)progress {
    offlineManager = offlineManager;

    if (progress > 100) {
        [self sendEventWithName:@"onDownloadProgress" body:[NSNumber numberWithInt:100]];
    } else {
        [self sendEventWithName:@"onDownloadProgress" body:[NSNumber numberWithDouble:progress]];
    }
}

- (void)offlineManager:(nonnull BMPOfflineManager *)offlineManager didResumeDownloadWithProgress:(double)progress {
    offlineManager = offlineManager;

    [self sendEventWithName:@"onDownloadSuspended" body:@false];
    [self sendEventWithName:@"onDownloadProgress" body:[NSNumber numberWithDouble:progress]];
}

- (void)offlineManagerDidCancelDownload:(nonnull BMPOfflineManager *)offlineManager {
    offlineManager = offlineManager;

    [self sendEventWithName:@"onDownloadCanceled" body:@{@"": @""}];
}

- (void)offlineManagerDidFinishDownload:(nonnull BMPOfflineManager *)offlineManager {
    offlineManager = offlineManager;

    [self sendEventWithName:@"onDownloadCompleted" body:@{@"source": [sourceItem toJsonData]}];
}

- (void)offlineManagerDidRenewOfflineLicense:(nonnull BMPOfflineManager *)offlineManager {
    offlineManager = offlineManager;
}

- (void)offlineManagerDidSuspendDownload:(nonnull BMPOfflineManager *)offlineManager {
    offlineManager = offlineManager;

    [self sendEventWithName:@"onDownloadSuspended" body:@true];
}

RCT_EXPORT_METHOD(getState: (nonnull NSString *) url ) {
    [BMPOfflineManager initializeOfflineManager];
    offlineManager = [BMPOfflineManager sharedInstance];

    sourceItem = [[BMPSourceItem alloc] initWithUrl:(NSURL *) [NSURL URLWithString:url]];

    switch ([offlineManager offlineStateForSourceItem:sourceItem]) {
        case 0:
            [self sendEventWithName:@"onState" body:@"DOWNLOADED"];
            break;
        case 1:
            [self sendEventWithName:@"onState" body:@"DOWNLOADING"];
            break;
        case 2:
            [self sendEventWithName:@"onState" body:@"SUSPENDED"];
            break;
        case 3:
            [self sendEventWithName:@"onState" body:@"NOT_DOWNLOADED"];
            break;
        case 4:
            [self sendEventWithName:@"onState" body:@"CANCELING"];
            break;
        default:
            [self sendEventWithName:@"onState" body:@"STATE_UNAVAILABLE"];
            break;
    }
}

RCT_EXPORT_METHOD(delete: (nonnull NSDictionary *)itemToDelete) {
    if (!itemToDelete[@"source"]) {
        [self sendEventWithName:@"onDeleteError" body:@"Source is not provided"];
        return ;
    }

    [BMPOfflineManager initializeOfflineManager];
    offlineManager = [BMPOfflineManager sharedInstance];

    BMPSourceItem *sourceItemToDelete = [BMPSourceItem fromJsonData:itemToDelete[@"source"] error:NULL ];
    [offlineManager deleteOfflineDataForSourceItem:sourceItemToDelete];
}

RCT_EXPORT_METHOD(pauseDownload) {
    if(!sourceItem || !offlineManager) {
        return ;
    }

    [offlineManager suspendDownloadForSourceItem:sourceItem];
}

RCT_EXPORT_METHOD(resumeDownload) {
    if(!sourceItem || !offlineManager) {
        return ;
    }

    [offlineManager resumeDownloadForSourceItem:sourceItem];
}

RCT_EXPORT_METHOD(cancelDownload) {
    if(!sourceItem || !offlineManager) {
        return ;
    }

    [offlineManager cancelDownloadForSourceItem:sourceItem];
}



@end
