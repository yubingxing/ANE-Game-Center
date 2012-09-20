//
//  TypeConversion.h
//  GameCenterIosExtension
//
//  Created by Richard Lord on 18/06/2012.
//  Copyright (c) 2012 Stick Sports Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "FlashRuntimeExtensions.h"

@interface GKPlayer (JSONKitSerializing)
- (uint8_t *)JSONString;
@end
@interface TypeConversion : NSObject

- (FREResult) FREGetObject:(FREObject)object asString:(NSString**)value;

- (FREResult) FREGetString:(NSString*)string asObject:(FREObject*)asString;
- (FREResult) FREGetDate:(NSDate*)date asObject:(FREObject*)asDate;

- (FREResult) FRESetObject:(FREObject)asObject property:(const uint8_t*)propertyName toString:(NSString*)value;
- (FREResult) FRESetObject:(FREObject)asObject property:(const uint8_t*)propertyName toBool:(uint32_t)value;
- (FREResult) FRESetObject:(FREObject)asObject property:(const uint8_t*)propertyName toInt:(int32_t)value;
- (FREResult) FRESetObject:(FREObject)asObject property:(const uint8_t*)propertyName toDouble:(double)value;
- (FREResult) FRESetObject:(FREObject)asObject property:(const uint8_t*)propertyName toDate:(NSDate*)value;

- (FREResult) FREGetGKPlayer:(GKPlayer*)player asObject:(FREObject*)asPlayer;
- (FREResult) FREGetGKScore:(GKScore*)score forPlayer:(GKPlayer*)player asObject:(FREObject*)asScore;
- (FREResult) FREGetGKAchievement:(GKAchievement*)achievement asObject:(FREObject*)asAchievement;

@end
