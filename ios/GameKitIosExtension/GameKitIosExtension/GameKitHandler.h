//
//  GameKitHandler.h
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


@interface GameKitHandler : NSObject <GKMatchDelegate,GKSessionDelegate,GKPeerPickerControllerDelegate> {
    BOOL gameCenterAvailable;
    BOOL userAuthenticated;
    
    NSMutableDictionary *playersDict;
    GKInvite *pendingInvite;
    NSArray *pendingPlayersToInvite;
}

@property (assign, readonly) BOOL gameCenterAvailable;
@property (assign, readonly) BOOL isMatchStarted;
@property (retain) NSMutableDictionary *playersDict;
@property (retain) GKInvite *pendingInvite;
@property (retain) NSArray *pendingPlayersToInvite;
@property (retain) __attribute__((NSObject)) GKMatch *match;

@property BOOL isHost;
@property uint32_t expectedPlayerCount;

void receiveFromPeer(NSData *data, NSString *peer, GKSession *session, void *context);
void handleReceivedData(NSData * data);

+ (GameKitHandler *)sharedInstance;
- (id)initWithContext:(FREContext)extensionContext;
- (void) initializeMatchPlayers;
- (void) initializeSessionPlayers:(GKSession *) session peers:(NSArray *) peers;
- (void) handleInvitation;

// Add findMatch function
- (FREObject) showMatchMaker:(FREObject)minPlayers maxPlayers:(FREObject)maxPlayers;
- (FREObject) sendDataToGCPlayers:(FREObject)playerIds msg:(FREObject)msg;
- (FREObject) disconnectFromGCMatch;
// Add report scores and show achievement and show leaderboard
- (FREObject) alert:(FREObject) title msg:(FREObject)msg;
- (FREObject) getSystemLocaleLanguage;
- (FREObject) isBluetoothAvailable;
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
- (FREObject) requestPeerMatch:(FREObject)myName sessionMode:(FREObject)sessionMode expectedPlayerCount:(FREObject)expectedPlayerCount;
- (FREObject) showPeerPicker: (FREObject)myName sessionMode:(FREObject)mode;
- (FREObject) joinServer:(FREObject)peerId;
- (FREObject) acceptPeer:(FREContext)peerId;
- (FREObject) denyPeer:(FREContext)peerId;
- (FREObject) sendDataToPeers:(FREObject) playerIds msg:(FREObject) msg;
- (FREObject) lockSession;
- (FREObject) disconnectFromAllPeers;
- (FREObject) disconnectFromPeer:(FREObject) peerId;
@end
