//
//  GameKitHandler.m
//  GameKitIosExtension
//
//  Created by Richard Lord on 18/06/2012.
//  Copyright (c) 2012 Stick Sports Ltd. All rights reserved.
//

#import "GameKitHandler.h"
#import <GameKit/GameKit.h>
#import "GC_NativeMessages.h"
#import "GC_BoardsController.h"
#import "GC_BoardsControllerPhone.h"
#import "GC_BoardsControllerPad.h"
#import "GC_LeaderboardWithNames.h"
#import "GC_TypeConversion.h"

#define DISPATCH_STATUS_EVENT(extensionContext, code, status) FREDispatchStatusEventAsync((extensionContext), (uint8_t*)code, (uint8_t*)status)

#define ASLocalPlayer "com.icestar.gamekit.GCLocalPlayer"
#define ASLeaderboard "com.icestar.gamekit.GCLeaderboard"
#define ASVectorScore "Vector.<com.icestar.gamekit.GCScore>"
#define ASVectorAchievement "Vector.<com.icestar.gamekit.GCAchievement>"
// connection status
#define AVAILABLE 1
#define CONNECTING 2
#define CONNECTED 3
#define DISCONNECTED 4
#define UNAVAILABLE 5

@interface GameKitHandler () {
    GKPeerPickerController *picker;
}
@property (retain)NSMutableDictionary* returnObjects;
@property (retain)id<BoardsController> boardsController;
@property (retain)TypeConversion* converter;
@property(retain) __attribute__((NSObject)) NSString *displayName;
@property(retain) __attribute__((NSObject)) GKSession *gameSession;

@end

@implementation GameKitHandler

@synthesize returnObjects, boardsController, converter;
@synthesize gameCenterAvailable;
@synthesize isMatchStarted;
@synthesize playersDict;
@synthesize pendingInvite;
@synthesize pendingPlayersToInvite;
@synthesize match;
@synthesize expectedPlayerCount;
@synthesize isHost;

static FREContext context;
static GameKitHandler * _sharedHelper = nil;
static NSString * appId;
+ (GameKitHandler *) sharedInstance {
    return _sharedHelper;
}

/**
 Returns a system language identifier,
 */
- (FREObject) getSystemLocaleLanguage {
    NSString *lan = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    FREObject reVal;
    FRENewObjectFromUTF8((uint32_t)[lan length], (const uint8_t*)[lan UTF8String], &reVal);
    // [lan release];
    return reVal;
};

- (id)initWithContext:(FREContext)extensionContext
{
    self = [super init];
    appId = [[NSBundle mainBundle] bundleIdentifier];
    _sharedHelper = self;
    if( self )
    {
        context = extensionContext;
        returnObjects = [[NSMutableDictionary alloc] init];
        converter = [[TypeConversion alloc] init];
    }
    return self;
}

- (void) createBoardsController
{
    if( !boardsController )
    {
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            boardsController = [[BoardsControllerPad alloc] initWithContext:context];
        }
        else
        {
            boardsController = [[BoardsControllerPhone alloc] initWithContext:context];
        }
    }
}

- (NSString*) storeReturnObject:(id)object
{
    NSString* key;
    do
    {
        key = [NSString stringWithFormat: @"%ld", random()];
    } while ( [self.returnObjects valueForKey:key] != nil );
    [self.returnObjects setValue:object forKey:key];
    return key;
}

- (id) getReturnObject:(NSString*) key
{
    id object = [self.returnObjects valueForKey:key];
    [self.returnObjects setValue:nil forKey:key];
    return object;
}

- (FREObject) isSupported
{
    // Check for presence of GKLocalPlayer class.
    BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
    
    // The device must be running iOS 4.1 or later.
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    gameCenterAvailable = localPlayerClassAvailable && osVersionSupported;
    uint32_t retValue = gameCenterAvailable ? 1 : 0;
    
    FREObject result;
    if ( FRENewObjectFromBool(retValue, &result ) == FRE_OK )
    {
        return result;
    }
    return nil;
}

- (FREObject) authenticateLocalPlayer
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( localPlayer )
    {
        if ( localPlayer.isAuthenticated )
        {
            userAuthenticated = YES;
            DISPATCH_STATUS_EVENT( context, [localPlayer JSONString], localPlayerAuthenticated );
            return NULL;
        }
        else
        {
            [localPlayer authenticateWithCompletionHandler:^(NSError *error) {
                if( localPlayer.isAuthenticated )
                {
                    userAuthenticated = YES;
                    DISPATCH_STATUS_EVENT( context, [localPlayer JSONString], localPlayerAuthenticated );
                    [self handleInvitation];
                }
                else
                {
                    userAuthenticated = NO;
                    DISPATCH_STATUS_EVENT( context, [localPlayer JSONString], localPlayerNotAuthenticated );
                }
            }];
        }
    }
    return NULL;
}

- (FREObject) getLocalPlayer
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if ( localPlayer && localPlayer.isAuthenticated )
    {
        FREObject asPlayer;
        if ( FRENewObject( ASLocalPlayer, 0, NULL, &asPlayer, NULL ) == FRE_OK
            && [self.converter FRESetObject:asPlayer property:"id" toString:localPlayer.playerID] == FRE_OK
            && [self.converter FRESetObject:asPlayer property:"alias" toString:localPlayer.alias] == FRE_OK )
        {
            return asPlayer;
        }
    }
    else
    {
        DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", notAuthenticated );
    }
    return NULL;
}

- (FREObject) reportScore:(FREObject)asScore inCategory:(FREObject)asCategory
{
    NSString* category;
    if( [self.converter FREGetObject:asCategory asString:&category] != FRE_OK ) return NULL;
    
    int32_t scoreValue = 0;
    if( FREGetObjectAsInt32( asScore, &scoreValue ) != FRE_OK ) return NULL;
    
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", notAuthenticated );
        return NULL;
    }
    
    GKScore* score = [[[GKScore alloc] initWithCategory:category] autorelease];
    if( score )
    {
        score.value = scoreValue;
        [score reportScoreWithCompletionHandler:^(NSError* error)
         {
             if( error == nil )
             {
                 DISPATCH_STATUS_EVENT( context, nil, scoreReported );
             }
             else
             {
                 DISPATCH_STATUS_EVENT( context, nil, scoreNotReported );
             }
         }];
    }
    return NULL;
}

- (FREObject) showStandardLeaderboard
{
    [self createBoardsController];
    [self.boardsController displayLeaderboard];
    return NULL;
}

- (FREObject) showStandardLeaderboardWithCategory:(FREObject)asCategory
{
    NSString* category;
    if( [self.converter FREGetObject:asCategory asString:&category] != FRE_OK ) return NULL;
    
    [self createBoardsController];
    [self.boardsController displayLeaderboardWithCategory:category];
    return NULL;
}

- (FREObject) showStandardLeaderboardWithTimescope:(FREObject)asTimescope
{
    int timeScope;
    if( FREGetObjectAsInt32( asTimescope, &timeScope ) != FRE_OK ) return NULL;
    
    [self createBoardsController];
    [self.boardsController displayLeaderboardWithTimescope:timeScope];
    return NULL;
}

- (FREObject) showStandardLeaderboardWithCategory:(FREObject)asCategory andTimescope:(FREObject)asTimescope
{
    NSString* category;
    if( [self.converter FREGetObject:asCategory asString:&category] != FRE_OK ) return NULL;
    int timeScope;
    if( FREGetObjectAsInt32( asTimescope, &timeScope ) != FRE_OK ) return NULL;
    
    [self createBoardsController];
    [self.boardsController displayLeaderboardWithCategory:category andTimescope:timeScope];
    return NULL;
}

- (FREObject) getLeaderboardWithCategory:(FREObject)asCategory playerScope:(FREObject)asPlayerScope timeScope:(FREObject)asTimeScope rangeMin:(FREObject)asRangeMin rangeMax:(FREObject)asRangeMax
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", notAuthenticated );
        return NULL;
    }
    
    GKLeaderboard* leaderboard = [[GKLeaderboard alloc] init];
    
    NSString* propertyString;
    if( [self.converter FREGetObject:asCategory asString:&propertyString] != FRE_OK ) return NULL;
    leaderboard.category = propertyString;
    
    int propertyInt;
    if( FREGetObjectAsInt32( asPlayerScope, &propertyInt ) != FRE_OK ) return NULL;
    leaderboard.playerScope = propertyInt;
    
    if( FREGetObjectAsInt32( asTimeScope, &propertyInt ) != FRE_OK ) return NULL;
    leaderboard.timeScope = propertyInt;
    
    int propertyInt2;
    if( FREGetObjectAsInt32( asRangeMin, &propertyInt ) != FRE_OK ) return NULL;
    if( FREGetObjectAsInt32( asRangeMax, &propertyInt2 ) != FRE_OK ) return NULL;
    leaderboard.range = NSMakeRange( propertyInt, propertyInt2 );
    
    [leaderboard loadScoresWithCompletionHandler:^( NSArray* scores, NSError* error )
     {
         if( error == nil && scores != nil )
         {
             LeaderboardWithNames* leaderboardWithNames = [[LeaderboardWithNames alloc] initWithLeaderboard:leaderboard];
             NSMutableArray* playerIds = [[[NSMutableArray alloc] initWithCapacity:scores.count] autorelease];
             int i = 0;
             for ( GKScore* score in scores )
             {
                 [playerIds insertObject:score.playerID atIndex:i];
                 ++i;
             }
             [GKPlayer loadPlayersForIdentifiers:playerIds withCompletionHandler:^(NSArray *playerDetails, NSError *error)
              {
                  if ( error == nil && playerDetails != nil )
                  {
                      NSMutableDictionary* names = [[[NSMutableDictionary alloc] init] autorelease];
                      for( GKPlayer* player in playerDetails )
                      {
                          [names setValue:player forKey:player.playerID];
                      }
                      leaderboardWithNames.names = names;
                      NSString* code = [self storeReturnObject:leaderboardWithNames];
                      DISPATCH_STATUS_EVENT( context, code.UTF8String, loadLeaderboardComplete );
                  }
                  else
                  {
                      [leaderboardWithNames release];
                      DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", loadLeaderboardFailed );
                  }
              }];
         }
         else
         {
             [leaderboard release];
             DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", loadLeaderboardFailed );
         }
     }];
    return NULL;
}

- (FREObject) reportAchievement:(FREObject)asId withValue:(FREObject)asValue andBanner:(FREObject)asBanner
{
    NSString* identifier;
    if( [self.converter FREGetObject:asId asString:&identifier] != FRE_OK ) return NULL;
    
    double value = 0;
    if( FREGetObjectAsDouble( asValue, &value ) != FRE_OK ) return NULL;
    
    uint32_t banner = 0;
    if( FREGetObjectAsBool( asBanner, &banner ) != FRE_OK ) return NULL;
    
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", notAuthenticated );
        return NULL;
    }
    
    GKAchievement* achievement = [[[GKAchievement alloc] initWithIdentifier:identifier] autorelease];
    if( achievement )
    {
        achievement.percentComplete = value * 100;
        if( [achievement respondsToSelector:@selector(showsCompletionBanner)] )
        {
            achievement.showsCompletionBanner = ( banner == 1 );
        }
        [achievement reportAchievementWithCompletionHandler:^(NSError* error)
         {
             if( error == nil )
             {
                 DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", achievementReported );
             }
             else
             {
                 DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", achievementNotReported );
             }
         }];
    }
    return nil;
}


- (FREObject) showStandardAchievements
{
    [self createBoardsController];
    [self.boardsController displayAchievements];
    return NULL;
}

- (FREObject) getAchievements
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", notAuthenticated );
        return NULL;
    }
    
    [GKAchievement loadAchievementsWithCompletionHandler:^( NSArray* achievements, NSError* error )
     {
         if( error == nil && achievements != nil )
         {
             [achievements retain];
             NSString* code = [self storeReturnObject:achievements];
             DISPATCH_STATUS_EVENT( context, code.UTF8String, loadAchievementsComplete );
         }
         else
         {
             DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", loadAchievementsFailed );
         }
     }];
    return NULL;
}

- (FREObject) getLocalPlayerFriends
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", notAuthenticated );
        return NULL;
    }
    [localPlayer loadFriendsWithCompletionHandler:^(NSArray *friendIds, NSError *error)
     {
         if ( error == nil && friendIds != nil )
         {
             if( friendIds.count == 0 )
             {
                 [friendIds retain];
                 NSString* code = [self storeReturnObject:friendIds];
                 DISPATCH_STATUS_EVENT( context, code.UTF8String, loadFriendsComplete );
             }
             else
             {
                 [GKPlayer loadPlayersForIdentifiers:friendIds withCompletionHandler:^(NSArray *friendDetails, NSError *error)
                  {
                      if ( error == nil && friendDetails != nil )
                      {
                          [friendDetails retain];
                          NSString* code = [self storeReturnObject:friendDetails];
                          DISPATCH_STATUS_EVENT( context, code.UTF8String, loadFriendsComplete );
                      }
                      else
                      {
                          DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", loadFriendsFailed );
                      }
                  }];
             }
         }
         else
         {
             DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", loadFriendsFailed );
         }
     }];
    return NULL;
}

- (FREObject) getLocalPlayerScoreInCategory:(FREObject)asCategory playerScope:(FREObject)asPlayerScope timeScope:(FREObject)asTimeScope
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", notAuthenticated );
        return NULL;
    }
    
    GKLeaderboard* leaderboard = [[GKLeaderboard alloc] init];
    
    NSString* propertyString;
    if( [self.converter FREGetObject:asCategory asString:&propertyString] != FRE_OK ) return NULL;
    leaderboard.category = propertyString;
    
    int propertyInt;
    if( FREGetObjectAsInt32( asPlayerScope, &propertyInt ) != FRE_OK ) return NULL;
    leaderboard.playerScope = propertyInt;
    
    if( FREGetObjectAsInt32( asTimeScope, &propertyInt ) != FRE_OK ) return NULL;
    leaderboard.timeScope = propertyInt;
    
    leaderboard.range = NSMakeRange( 1, 1 );
    
    [leaderboard loadScoresWithCompletionHandler:^( NSArray* scores, NSError* error )
     {
         if( error == nil && scores != nil )
         {
             NSString* code = [self storeReturnObject:leaderboard];
             DISPATCH_STATUS_EVENT( context, code.UTF8String, loadLocalPlayerScoreComplete );
         }
         else
         {
             [leaderboard release];
             DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", loadLocalPlayerScoreFailed );
         }
     }];
    return NULL;
}

- (FREObject) getStoredLocalPlayerScore:(FREObject)asKey
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", notAuthenticated );
        return NULL;
    }
    
    NSString* key;
    if( [self.converter FREGetObject:asKey asString:&key] != FRE_OK ) return NULL;
    
    GKLeaderboard* leaderboard = [self getReturnObject:key];
    
    if( leaderboard == nil )
    {
        return NULL;
    }
    FREObject asLeaderboard;
    FREObject asScore;
    
    if ( FRENewObject( ASLeaderboard, 0, NULL, &asLeaderboard, NULL) == FRE_OK
        && [self.converter FRESetObject:asLeaderboard property:"timeScope" toInt:leaderboard.timeScope] == FRE_OK
        && [self.converter FRESetObject:asLeaderboard property:"playerScope" toInt:leaderboard.playerScope] == FRE_OK
        && [self.converter FRESetObject:asLeaderboard property:"category" toString:leaderboard.category] == FRE_OK
        && [self.converter FRESetObject:asLeaderboard property:"title" toString:leaderboard.title] == FRE_OK
        && [self.converter FRESetObject:asLeaderboard property:"rangeMax" toInt:leaderboard.maxRange] == FRE_OK )
    {
        if( leaderboard.localPlayerScore && [self.converter FREGetGKScore:leaderboard.localPlayerScore forPlayer:localPlayer asObject:&asScore] == FRE_OK )
        {
            FRESetObjectProperty( asLeaderboard, "localPlayerScore", asScore, NULL );
        }
        [leaderboard release];
        return asLeaderboard;
    }
    [leaderboard release];
    return NULL;
}

- (FREObject) getStoredLeaderboard:(FREObject)asKey
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, (const uint8_t *)"", notAuthenticated );
        return NULL;
    }
    
    NSString* key;
    if( [self.converter FREGetObject:asKey asString:&key] != FRE_OK ) return NULL;
    
    LeaderboardWithNames* leaderboardWithNames = [self getReturnObject:key];
    GKLeaderboard* leaderboard = leaderboardWithNames.leaderboard;
    NSDictionary* names = leaderboardWithNames.names;
    
    if( leaderboard == nil || names == nil )
    {
        return NULL;
    }
    FREObject asLeaderboard;
    FREObject asLocalScore;
    
    if ( FRENewObject( ASLeaderboard, 0, NULL, &asLeaderboard, NULL) == FRE_OK
        && [self.converter FRESetObject:asLeaderboard property:"timeScope" toInt:leaderboard.timeScope] == FRE_OK
        && [self.converter FRESetObject:asLeaderboard property:"playerScope" toInt:leaderboard.playerScope] == FRE_OK
        && [self.converter FRESetObject:asLeaderboard property:"category" toString:leaderboard.category] == FRE_OK
        && [self.converter FRESetObject:asLeaderboard property:"title" toString:leaderboard.title] == FRE_OK
        && [self.converter FRESetObject:asLeaderboard property:"rangeMax" toInt:leaderboard.maxRange] == FRE_OK
        && [self.converter FRESetObject:asLeaderboard property:"rangeStart" toInt:leaderboard.range.location] == FRE_OK
        && [self.converter FRESetObject:asLeaderboard property:"rangeLength" toInt:leaderboard.range.length] == FRE_OK
        )
    {
        if( leaderboard.localPlayerScore && [self.converter FREGetGKScore:leaderboard.localPlayerScore forPlayer:localPlayer asObject:&asLocalScore] == FRE_OK )
        {
            FRESetObjectProperty( asLeaderboard, "localPlayerScore", asLocalScore, NULL );
        }
        if( leaderboard.scores )
        {
            FREObject asScores;
            if ( FRENewObject( ASVectorScore, 0, NULL, &asScores, NULL ) == FRE_OK && FRESetArrayLength( asScores, leaderboard.scores.count ) == FRE_OK )
            {
                int nextIndex = 0;
                for( GKScore* score in leaderboard.scores )
                {
                    GKPlayer* player = [names valueForKey:score.playerID];
                    if( player != nil )
                    {
                        FREObject asScore;
                        if( [self.converter FREGetGKScore:score forPlayer:player asObject:&asScore] == FRE_OK )
                        {
                            FRESetArrayElementAt( asScores, nextIndex, asScore );
                            ++nextIndex;
                        }
                    }
                }
                FRESetObjectProperty( asLeaderboard, "scores", asScores, NULL );
            }
        }
        [leaderboardWithNames release];
        return asLeaderboard;
    }
    [leaderboardWithNames release];
    return NULL;
}

- (FREObject) getStoredAchievements:(FREObject)asKey
{
    NSString* key;
    if( [self.converter FREGetObject:asKey asString:&key] != FRE_OK ) return NULL;
    
    NSArray* achievements = [self getReturnObject:key];
    if( achievements == nil )
    {
        return NULL;
    }
    FREObject asAchievements;
    if ( FRENewObject( ASVectorAchievement, 0, NULL, &asAchievements, NULL ) == FRE_OK && FRESetArrayLength( asAchievements, achievements.count ) == FRE_OK )
    {
        int nextIndex = 0;
        for( GKAchievement* achievement in achievements )
        {
            FREObject asAchievement;
            if( [self.converter FREGetGKAchievement:achievement asObject:&asAchievement] == FRE_OK )
            {
                FRESetArrayElementAt( asAchievements, nextIndex, asAchievement );
                ++nextIndex;
            }
        }
        [achievements release];
        return asAchievements;
    }
    [achievements release];
    return NULL;
}

- (FREObject) getStoredPlayers:(FREObject)asKey
{
    NSString* key;
    if( [self.converter FREGetObject:asKey asString:&key] != FRE_OK ) return NULL;
    
    NSArray* friendDetails = [self getReturnObject:key];
    if( friendDetails == nil )
    {
        return NULL;
    }
    FREObject friends;
    if ( FRENewObject( "Array", 0, NULL, &friends, NULL ) == FRE_OK && FRESetArrayLength( friends, friendDetails.count ) == FRE_OK )
    {
        int nextIndex = 0;
        for( GKPlayer* friend in friendDetails )
        {
            FREObject asPlayer;
            if( [self.converter FREGetGKPlayer:friend asObject:&asPlayer] == FRE_OK )
            {
                FRESetArrayElementAt( friends, nextIndex, asPlayer );
                ++nextIndex;
            }
        }
        [friendDetails release];
        return friends;
    }
    [friendDetails release];
    return NULL;
}

#pragma mark User functions

// start match maker request and show the matchmaker view
- (FREObject)showMatchMaker:(FREObject)minPlayers maxPlayers:(FREObject)maxPlayers {
    
    if (!gameCenterAvailable) return NULL;
    
    isMatchStarted = NO;
    self.match = nil;
    
    [self createBoardsController];
    uint32_t min = 0;
    uint32_t max = 0;
    FREGetObjectAsInt32(minPlayers, &min);
    FREGetObjectAsInt32(maxPlayers, &max);
    [self.boardsController displayMatchMaker:min max:max];
    return nil;
}

#pragma mark GKMatchDelegate

// The match received data sent from the player.
- (void)match:(GKMatch *)theMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {
    if (match != theMatch) return;
    
    handleReceivedData(playerID, data);
}

// The player state changed (eg. connected or disconnected)
- (void)match:(GKMatch *)theMatch player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state {
    
    if (match != theMatch) return;
    NSMutableString* retXML = [[NSMutableString alloc] initWithString:@"{"];
    [retXML appendFormat:@"\"id\":\"%@\"",playerID];
    
    switch (state)
    {
        case GKPlayerStateConnected:
            // handle a new player connection.
            [retXML appendFormat:@"\"status\":%d", CONNECTED];
            break;
        case GKPlayerStateDisconnected:
            [retXML appendFormat:@"\"status\":%d", DISCONNECTED];
            isMatchStarted = NO;
            // a player just disconnected.
            break;
    }
    
    DISPATCH_STATUS_EVENT(context, (const uint8_t *)[retXML UTF8String], player_status_changed);
    
    if (!isMatchStarted && match.expectedPlayerCount == 0)
    {
        [self initializeMatchPlayers];
    }
}

// The match was unable to connect with the player due to an error.
- (void)match:(GKMatch *)theMatch connectionWithPlayerFailed:(NSString *)playerID withError:(NSError *)error {
    
    if (match != theMatch) return;
    
    NSLog(@"Failed to connect to player with error: %@", error.localizedDescription);
    isMatchStarted = NO;
    NSString *ret = [playerID stringByAppendingFormat:@"::%@", [error description]];
    DISPATCH_STATUS_EVENT(context, (const uint8_t *)[ret UTF8String], connection_failed );
}

// The match was unable to be established with any players due to an error.
- (void)match:(GKMatch *)theMatch didFailWithError:(NSError *)error {
    
    if (match != theMatch) return;
    
    NSLog(@"Match failed with error: %@", error.localizedDescription);
    isMatchStarted = NO;
    DISPATCH_STATUS_EVENT(context, (const uint8_t *)[[error description] UTF8String], connection_failed );
}

// This method is called when the match is interrupted; if it returns YES, a new invite will be sent to attempt reconnection. This is supported only for 1v1 games
- (BOOL)match:(GKMatch *)match shouldReinvitePlayer:(NSString *)playerID {
    
    return FALSE;
}

- (void) handleInvitation {
    [GKMatchmaker sharedMatchmaker].inviteHandler = ^(GKInvite *acceptedInvite, NSArray *playersToInvite) {
        self.pendingInvite = acceptedInvite;
        self.pendingPlayersToInvite = playersToInvite;
        [self createBoardsController];
        [self.boardsController displayMatchMaker:2 max:4];
    };
}

/**
 Broadcast a message to selected Game Center match players.
 */
- (FREObject) sendDataToGCPlayers:(FREObject)playerIds msg:(FREObject)msg {
    //创建msg来寄存发送的信息
    const uint8_t* _msg = nil;
    uint32_t len = -1;
    
    //将信息寄存在msg中
    FREGetObjectAsUTF8(msg, &len, &_msg);
    const char* datachar = (const char*) _msg;
    
    NSString *_playerIds = nil;
    GC_FREGetObjectAsString(playerIds, &_playerIds);
    
    //创建players来寄存接收玩家列表
    NSArray *players = [_playerIds componentsSeparatedByString:@","];
    
    
    //将发送的信息保存在一个NSData中
    NSData *packet = [NSData dataWithBytes:datachar length:strlen(datachar)];
    //使用GKMatch的sendData方法将信息发送给指定的玩家们
    [self.match sendData:packet toPlayers:players withDataMode:GKSendDataUnreliable error:nil];
    return nil;
}

/**
 Boardcast a message to all Session peers.
 */
- (FREObject) sendDataToPeers:(FREObject) playerIds msg:(FREObject) msg {
    const uint8_t* _msg = nil;
    uint32_t len = -1;
    
    FREGetObjectAsUTF8(msg, &len, &_msg);
    const char* datachar = (const char*) _msg;
        
    NSString *playerIDStr = nil;
    GC_FREGetObjectAsString(playerIds, &playerIDStr);

    NSArray *players = [playerIDStr componentsSeparatedByString:@","];
    //[playerIDStr release];
    
    NSError *error;
    NSData *packet = [NSData dataWithBytes:datachar length:strlen(datachar)];
    [self.gameSession sendData:packet toPeers:players withDataMode:GKSendDataUnreliable error:&error];
    
//    NSLog([NSString stringWithUTF8String:(const char*)_msg]);
    return nil;
}
/**
 Disconnect from Game Center Match;
 */
- (FREObject) disconnectFromGCMatch {
    if(self.match!=nil){
        [self.match disconnect];
        //[observer.myMatch release];
    }
    return nil;
}
/**
 Disconnect from certain session peer;
 */
- (FREObject) disconnectFromPeer:(FREObject) peerId {
    NSString *peerID = nil;
    GC_FREGetObjectAsString(peerId, &peerID);
    if([self gameSession]!=nil){
        [[self gameSession] disconnectPeerFromAllPeers:peerID];
    }
    return nil;
}

/**
 Disconnect from all other session peers;
 */
- (FREObject) disconnectFromAllPeers {
    if([self gameSession]!=nil){
        [[self gameSession] disconnectFromAllPeers];
        [self gameSession].available = NO;
        [[self gameSession] setDataReceiveHandler: nil withContext: nil];
        [self gameSession].delegate = nil;
        // [[observer gameSession] release];
    }
    return nil;
}
/**
 While entering match, you need to lock the session so nobody will search this session.
 */
- (FREObject) lockSession {
    if([self gameSession]!=nil){
        [self gameSession].available = NO;
    }
    return nil;
}

- (FREObject) alert:(FREObject) title msg:(FREObject)msg {
    //先定义两个变量，用来寄存标题和内容。
    NSString *_title = nil;
    NSString *_msg = nil;
    
    //使用FREGetObjectAsUTF8，从argv中取出相应的参数值，然后存放到title和msg对应的指针中。
    //这是通过FRE API实现从FREObject中向Native变量赋值的典型形式。
    GC_FREGetObjectAsString(title, &_title);
    GC_FREGetObjectAsString(msg, &_msg);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:_title message:_msg delegate:nil
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:nil,nil];
    [alert show];
    
    return nil;
}

-(void) initializeMatchPlayers {
    isMatchStarted = YES;
    [GKPlayer loadPlayersForIdentifiers:[self.match playerIDs] withCompletionHandler:^(NSArray *players, NSError *error) { 
        if(error){
            //Handler load player info error;
        }else{
            DISPATCH_STATUS_EVENT(context, getPlayersString(players), matchPlayersInitialized);
        };
    }];
}

#pragma mark Add local net p2p connect

- (void) initializeSessionPlayers:(GKSession *) session peers:(NSArray *) peers {
    DISPATCH_STATUS_EVENT(context, getPeersString(peers, session), matchPlayersInitialized);
}

/**
 Check whether Bluetooth is available on your device.
 */
- (FREObject) isBluetoothAvailable {
    FREObject reVal;
    FRENewObjectFromBool(YES,&reVal);
    return reVal;
}

/**
 Request a peer session, difference from server mode and client mode.
 */
- (FREObject) requestPeerMatch:(FREObject)myName sessionMode:(FREObject)sessionMode expectedPlayerCount:(FREObject)playerCount{
    NSString *_myName = nil;
    uint32_t _sessionMode = 1;
    uint32_t _expectedPlayerCount = 2;

    GC_FREGetObjectAsString(myName, &_myName);
    FREGetObjectAsUint32(playerCount, &_expectedPlayerCount);
    FREGetObjectAsUint32(sessionMode, &_sessionMode);

    

    self.displayName = _myName;
    self.expectedPlayerCount = _expectedPlayerCount;
    
    GKSession* session = [[GKSession alloc] initWithSessionID:[NSString stringWithFormat:@"%@_%d@", appId, _expectedPlayerCount]
                                                  displayName:_myName
                                                  sessionMode: (_sessionMode == 2) ? GKSessionModeServer : (_sessionMode == 1)? GKSessionModePeer : GKSessionModeClient];
    self.gameSession = session;
    
    [session setDataReceiveHandler:self withContext:nil];
    session.delegate = self;
    session.available = YES;  
    
    FREObject reVal;
    FRENewObjectFromUTF8((uint32_t)[session.peerID length], (const uint8_t*)[session.peerID UTF8String], &reVal);
    return reVal;
}

/**
 Accepts a connecting client as a server.
 */
- (FREObject) acceptPeer:(FREContext)peerId {
    NSString *peerID = nil;
    GC_FREGetObjectAsString(peerId, &peerID);
    
    [self.gameSession acceptConnectionFromPeer:peerID error:nil];
    
    return nil;
}

/**
 Rejects a connecting client as a server.
 */
- (FREObject) denyPeer:(FREContext)peerId {
    NSString *peerID = nil;
    GC_FREGetObjectAsString(peerId, &peerID);
    
    [self.gameSession denyConnectionFromPeer:peerID];
    return nil;
}

/**
 Trying to connect a server as a client.
 */
- (FREObject) joinServer:(FREObject)peerId {
    NSString *peerID = nil;
    GC_FREGetObjectAsString(peerId, &peerID);
    
    uint32_t timeInterval = 10000;
    
    [self.gameSession connectToPeer:peerID withTimeout:timeInterval];
    return nil;
}

- (FREObject) showPeerPicker {
    if(picker)[picker dismiss];
    picker = [[[GKPeerPickerController alloc] init] autorelease];
    picker.delegate = self;
    [picker show];
    return nil;
}


#pragma mark GKSessionDelegate
/* Indicates a state change for the given peer.
 */
- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
    int status = 0;
    switch (state)
    {
        case GKPeerStateAvailable:
            status = AVAILABLE;
            break;
        case GKPeerStateConnecting:
            status = CONNECTING;
            break;
        case GKPeerStateConnected:
            status = CONNECTED;
            if([session sessionMode] == GKSessionModePeer){
                // NSLog(@"2");
                NSArray *connectedPeers = [session peersWithConnectionState:GKPeerStateConnected];
                if([connectedPeers count] == expectedPlayerCount-1){
                    // NSLog(@"3");
                    [self initializeSessionPlayers:session peers:connectedPeers];
                }
            }
            break;
        case GKPeerStateDisconnected:
            status = DISCONNECTED;
            break;
        case GKPeerStateUnavailable:
            status = UNAVAILABLE;
            break;
        default:
            break;
    }

    DISPATCH_STATUS_EVENT(context, getPlayerString(peerID, [session displayNameForPeer:peerID], status, nil), player_status_changed);

}

/* Indicates a connection request was received from another peer.
 
 Accept by calling -acceptConnectionFromPeer:
 Deny by calling -denyConnectionFromPeer:
 */
- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
    DISPATCH_STATUS_EVENT(context, getPlayerString(peerID, [session displayNameForPeer:peerID], 0, nil), received_client_request);
}

/* Indicates a connection error occurred with a peer, which includes connection request failures, or disconnects due to timeouts.
 */
- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {
    DISPATCH_STATUS_EVENT(context, getPlayerString(peerID, [session displayNameForPeer:peerID], 0, error), connection_failed);
}

/* Indicates an error occurred with the session such as failing to make available.
 */
- (void)session:(GKSession *)session didFailWithError:(NSError *)error {
    DISPATCH_STATUS_EVENT(context, getPlayerString([session peerID], [session displayNameForPeer:session.peerID], 0, error), connection_failed);
}

#pragma mark GKPeerPickerControllerDelegate

/* Notifies delegate that a connection type was chosen by the user.
 */
- (void)peerPickerController:(GKPeerPickerController *)picker didSelectConnectionType:(GKPeerPickerConnectionType)type {
    
}

/* Notifies delegate that the connection type is requesting a GKSession object.
 
 You should return a valid GKSession object for use by the picker. If this method is not implemented or returns 'nil', a default GKSession is created on the delegate's behalf.
 */
- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type {
    return nil;
}

/* Notifies delegate that the peer was connected to a GKSession.
 */
- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session {
    
}

/* Notifies delegate that the user cancelled the picker.
 */
- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker {
    
}

- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{
//    NSLog([NSString stringWithUTF8String:(const char*)[data bytes]]);
    handleReceivedData(peer, data);
}

void receiveFromPeer(NSData *data, NSString *peer, GKSession *session, void *context)
{
    handleReceivedData(peer, data);
}

void handleReceivedData(NSString * peer, NSData * data) {
    NSString *datastr = [NSString stringWithUTF8String:[data bytes]];
    datastr = [peer stringByAppendingFormat:@"%@::%@", peer, datastr];
    DISPATCH_STATUS_EVENT(context, (const uint8_t*)[datastr UTF8String], received_data_from);
}
@end
