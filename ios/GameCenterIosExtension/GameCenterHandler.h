//
//  GameCenterHandler.h
//  GameCenterIosExtension
//
//  Created by Richard Lord on 18/06/2012.
//  Copyright (c) 2012 Stick Sports Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "FlashRuntimeExtensions.h"
#import "FRETypeConversion.h"
#import "JSONKit.h"


@protocol GCHelperDelegate
- (void)matchStarted;
- (void)matchEnded;
//- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID;
- (void)inviteReceived;
@end

@interface GameCenterHandler : NSObject <GKMatchDelegate> {
    BOOL gameCenterAvailable;
    BOOL userAuthenticated;
    
    GKMatch *match;
    BOOL isMatchStarted;
    NSMutableDictionary *playersDict;
    GKInvite *pendingInvite;
    NSArray *pendingPlayersToInvite;
    
    uint32_t ourRandom;
    BOOL receivedRandom;
    NSString *otherPlayerID;
    
}

@property (assign, readonly) BOOL gameCenterAvailable;
@property (assign, readonly) BOOL isMatchStarted;
@property (retain) GKMatch *match;
@property (retain) NSMutableDictionary *playersDict;
@property (retain) GKInvite *pendingInvite;
@property (retain) NSArray *pendingPlayersToInvite;

+ (GameCenterHandler *)sharedInstance;
- (id)initWithContext:(FREContext)extensionContext;
- (void)lookupPlayers;

// Add findMatch function
- (FREObject) showMatchMaker:(FREObject)minPlayers maxPlayers:(FREObject)maxPlayers;

- (FREObject) isSupported;
- (FREObject) authenticateLocalPlayer;
- (FREObject) getLocalPlayer;
- (FREObject) reportScore:(FREObject)asScore inCategory:(FREObject)asCategory;
- (FREObject) showStandardLeaderboard;
- (FREObject) showStandardLeaderboardWithCategory:(FREObject)asCategory;
- (FREObject) showStandardLeaderboardWithTimescope:(FREObject)asTimescope;
- (FREObject) showStandardLeaderboardWithCategory:(FREObject)asCategory andTimescope:(FREObject)asTimescope;
- (FREObject) getLeaderboardWithCategory:(FREObject)asCategory playerScope:(FREObject)asPlayerScope timeScope:(FREObject)asTimeScope rangeMin:(FREObject)asRangeMin rangeMax:(FREObject)asRangeMax;
- (FREObject) reportAchievement:(FREObject)asId withValue:(FREObject)asValue andBanner:(FREObject)asBanner;
- (FREObject) showStandardAchievements;
- (FREObject) getAchievements;
- (FREObject) getLocalPlayerFriends;
- (FREObject) getLocalPlayerScoreInCategory:(FREObject)asCategory playerScope:(FREObject)asPlayerScope timeScope:(FREObject)asTimeScope;
- (FREObject) getStoredLocalPlayerScore:(FREObject)asKey;
- (FREObject) getStoredLeaderboard:(FREObject)asKey;
- (FREObject) getStoredAchievements:(FREObject)asKey;
- (FREObject) getStoredPlayers:(FREObject)asKey;
- (FREObject) sendData:(FREObject)msg;

@end
