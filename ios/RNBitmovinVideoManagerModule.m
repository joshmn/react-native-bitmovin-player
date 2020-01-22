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
    return @[@"onDownloadCompleted", @"onDownloadProgress", @"onDownloadError", @"onDownloadCanceled", @"onDownloadSuspended"];
}

RCT_EXPORT_METHOD(download: (nonnull NSDictionary *)configuration){
    
    if (!configuration[@"url"]) {
        [self sendEventWithName:@"onDownloadError" body:@{@"message": @"URL is not provided"}];
        return ;
    }
    
    [BMPOfflineManager initializeOfflineManager];
    offlineManager = [BMPOfflineManager sharedInstance];
    
    sourceItem = [[BMPSourceItem alloc] initWithUrl:(NSURL *) [NSURL URLWithString:configuration[@"url"]]];
    
    if(configuration[@"title"]){
        sourceItem.itemTitle = configuration[@"title"];
    }

    Boolean isPlayable = [offlineManager isSourceItemPlayableOffline:(BMPSourceItem *) sourceItem];
    
    if (isPlayable){
        [self sendEventWithName:@"onDownloadCompleted" body:@{@"source": [sourceItem toJsonData]}];
        return ;
    }
    
//    check if the status is downloaded
    if ([offlineManager offlineStateForSourceItem:sourceItem] == 0) {
        [offlineManager deleteOfflineDataForSourceItem:sourceItem];
    }
    
    [offlineManager addListener:self forSourceItem:sourceItem];
    [offlineManager downloadSourceItem:sourceItem];
}

- (void)offlineManager:(nonnull BMPOfflineManager *)offlineManager didFailWithError:(nullable NSError *)error {
    [self sendEventWithName:@"onDownloadError" body:@{@"message": [error description]}];
}

- (void)offlineManager:(nonnull BMPOfflineManager *)offlineManager didProgressTo:(double)progress {
    [self sendEventWithName:@"onDownloadProgress" body:@{@"progress": [NSNumber numberWithDouble:progress]}];
}

- (void)offlineManager:(nonnull BMPOfflineManager *)offlineManager didResumeDownloadWithProgress:(double)progress {
    [self sendEventWithName:@"onDownloadSuspended" body:@{@"paused": @false}];
    [self sendEventWithName:@"onDownloadProgress" body:@{@"progress": [NSNumber numberWithDouble:progress]}];
}

- (void)offlineManagerDidCancelDownload:(nonnull BMPOfflineManager *)offlineManager {
    [self sendEventWithName:@"onDownloadCanceled" body:@{@"": @""}];
}

- (void)offlineManagerDidFinishDownload:(nonnull BMPOfflineManager *)offlineManager {
    [self sendEventWithName:@"onDownloadCompleted" body:@{@"source": [sourceItem toJsonData]}];
}

- (void)offlineManagerDidRenewOfflineLicense:(nonnull BMPOfflineManager *)offlineManager {
}

- (void)offlineManagerDidSuspendDownload:(nonnull BMPOfflineManager *)offlineManager {
    [self sendEventWithName:@"onDownloadSuspended" body:@{@"paused": @true}];
}

RCT_EXPORT_METHOD(delete: (nonnull NSDictionary *)itemToDelete) {
    if (!itemToDelete[@"source"]) {
        [self sendEventWithName:@"onDeleteError" body:@{@"message": @"Source is not provided"}];
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
