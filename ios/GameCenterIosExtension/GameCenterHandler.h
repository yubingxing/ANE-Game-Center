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


@protocol GameCenterDelegate
- (void)matchStarted;
- (void)matchEnded;
- (void)inviteReceived;
@end

@interface GameCenterHandler : NSObject <GKMatchDelegate,GKSessionDelegate,GKPeerPickerControllerDelegate,GameCenterDelegate> {
    BOOL gameCenterAvailable;
    BOOL userAuthenticated;
    
    GKMatch *match;
    GKSession *gameSession;
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
@property (retain) GKSession *gameSession;
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
// Add p2p connection func
- (FREObject) sendData:(FREObject)msg;
- (FREObject) requestPeerMatch:(FREObject)name;
- (FREObject) joinServer:(FREObject)peerId;
- (FREObject) acceptPeer:(FREContext)peerId;
- (FREObject) denyPeer:(FREContext)peerId;
@end
