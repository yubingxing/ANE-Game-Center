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
#import "JSONKit.h"


@protocol GCHelperDelegate
- (void)matchStarted;
- (void)matchEnded;
//- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID;
- (void)inviteReceived;
@end

@interface GameCenterHandler : NSObject <GKMatchmakerViewControllerDelegate, GKMatchDelegate> {
    BOOL gameCenterAvailable;
    BOOL userAuthenticated;
    
    UIViewController *presentingViewController;
    GKMatch *match;
    BOOL matchStarted;
    NSMutableDictionary *playersDict;
    GKInvite *pendingInvite;
    NSArray *pendingPlayersToInvite;
    
    uint32_t ourRandom;
    BOOL receivedRandom;
    NSString *otherPlayerID;
    
}

@property (assign, readonly) BOOL gameCenterAvailable;
@property (retain) UIViewController *presentingViewController;
@property (retain) GKMatch *match;
@property (retain) NSMutableDictionary *playersDict;
@property (retain) GKInvite *pendingInvite;
@property (retain) NSArray *pendingPlayersToInvite;

- (id)initWithContext:(FREContext)extensionContext;
// Add findMatch function
- (FREObject)findMatchWithMinPlayers:(FREObject)minPlayers maxPlayers:(FREObject)maxPlayers;

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
