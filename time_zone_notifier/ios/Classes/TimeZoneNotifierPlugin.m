// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "TimeZoneNotifierPlugin.h"

@implementation FLTTimeZoneNotifierPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel =
      [FlutterMethodChannel methodChannelWithName:@"com.taqo.survey/time_zone_notifier"
                                  binaryMessenger:[registrar messenger]
                                            codec:[FlutterJSONMethodCodec sharedInstance]];
  FLTTimeZoneNotifierPlugin* instance = [[FLTTimeZoneNotifierPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  result(FlutterMethodNotImplemented);
}

@end
