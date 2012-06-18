//
//  GameCenterIosExtension
//  GameCenterIosExtension.m
//
//  Created by Richard Lord on 19/12/2011.
//  Copyright (c) 2012 Stick Sports Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlashRuntimeExtensions.h"
#import <GameKit/GameKit.h>
#import "GameCenterMessages.h"
#import "BoardsController.h"
#import "BoardsControllerPhone.h"
#import "BoardsControllerPad.h"
#import "FRETypeConversion.h"
#import "LeaderboardWithNames.h"

#define DEFINE_ANE_FUNCTION(fn) FREObject (fn)(FREContext context, void* functionData, uint32_t argc, FREObject argv[])

#define DISPATCH_STATUS_EVENT(extensionContext, code, status) FREDispatchStatusEventAsync((extensionContext), (uint8_t*)code, (uint8_t*)status)

#define MAP_FUNCTION(fn, data) { (const uint8_t*)(#fn), (data), &(fn) }

id<BoardsController> GC_boardsController;
NSMutableDictionary* GC_returnObjects;

void GC_createBoardsController( FREContext context )
{
    if( !GC_boardsController )
    {
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            GC_boardsController = [[BoardsControllerPad alloc] initWithContext:context];
        }
        else
        {
            GC_boardsController = [[BoardsControllerPhone alloc] initWithContext:context];
        }
    }
}

NSString* GC_storeReturnObject( id object )
{
    NSString* key;
    do
    {
        key = [NSString stringWithFormat: @"%i", random()];
    } while ( [GC_returnObjects valueForKey:key] != nil );
    [GC_returnObjects setValue:object forKey:key];
    return key;
}

id GC_getReturnObject( NSString* key )
{
    id object = [GC_returnObjects valueForKey:key];
    [GC_returnObjects setValue:nil forKey:key];
    return object;
}

FREResult FRENewObjectFromGKPlayer( GKPlayer* player, FREObject* asPlayer )
{
    FREResult result;
    
    result = FRENewObject( ASPlayer, 0, NULL, asPlayer, NULL);
    if( result != FRE_OK ) return result;
    
    result = GC_FRESetObjectPropertyString( *asPlayer, "id", player.playerID );
    if( result != FRE_OK ) return result;
    
    result = GC_FRESetObjectPropertyString( *asPlayer, "alias", player.alias );
    if( result != FRE_OK ) return result;
    
    result = GC_FRESetObjectPropertyBool( *asPlayer, "isFriend", player.isFriend );
    if( result != FRE_OK ) return result;
    
    return FRE_OK;
}

FREResult FRENewObjectFromGKScore( GKScore* score, GKPlayer* player, FREObject* asScore )
{
    FREResult result;
    FREObject asPlayer;
    
    result = FRENewObject( ASScore, 0, NULL, asScore, NULL);
    if( result != FRE_OK ) return result;
    
    result = GC_FRESetObjectPropertyString( *asScore, "category", score.category );
    if( result != FRE_OK ) return result;
    
    result = GC_FRESetObjectPropertyInt( *asScore, "value", score.value );
    if( result != FRE_OK ) return result;
    
    result = GC_FRESetObjectPropertyString( *asScore, "formattedValue", score.formattedValue );
    if( result != FRE_OK ) return result;
    
    result = GC_FRESetObjectPropertyDate( *asScore, "date", score.date );
    if( result != FRE_OK ) return result;
    
    result = FRENewObjectFromGKPlayer( player, &asPlayer );
    if( result != FRE_OK ) return result;
    result = FRESetObjectProperty( *asScore, "player", asPlayer, NULL );
    if( result != FRE_OK ) return result;
    
    result = GC_FRESetObjectPropertyInt( *asScore, "rank", score.rank );
    if( result != FRE_OK ) return result;
    
    return FRE_OK;
}

FREResult FRENewObjectFromGKAchievement( GKAchievement* achievement, FREObject* asAchievement )
{
    FREResult result;
    
    result = FRENewObject( ASAchievement, 0, NULL, asAchievement, NULL);
    if( result != FRE_OK ) return result;
    
    result = GC_FRESetObjectPropertyString( *asAchievement, "id", achievement.identifier );
    if( result != FRE_OK ) return result;
    
    result = GC_FRESetObjectPropertyNum( *asAchievement, "value", achievement.percentComplete / 100.0 );
    if( result != FRE_OK ) return result;
    
    return FRE_OK;
}

DEFINE_ANE_FUNCTION( isSupported )
{
    // Check for presence of GKLocalPlayer class.
    BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
    
    // The device must be running iOS 4.1 or later.
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    
    uint32_t retValue = (localPlayerClassAvailable && osVersionSupported) ? 1 : 0;

    FREObject result;
    if ( FRENewObjectFromBool(retValue, &result ) == FRE_OK )
    {
        return result;
    }
    return NULL;
}

DEFINE_ANE_FUNCTION( authenticateLocalPlayer )
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( localPlayer )
    {
        if ( localPlayer.isAuthenticated )
        {
            DISPATCH_STATUS_EVENT( context, "", localPlayerAuthenticated );
            return NULL;
        }
        else
        {
            [localPlayer authenticateWithCompletionHandler:^(NSError *error) {
                if( localPlayer.isAuthenticated )
                {
                    DISPATCH_STATUS_EVENT( context, "", localPlayerAuthenticated );
                }
                else
                {     
                    DISPATCH_STATUS_EVENT( context, "", localPlayerNotAuthenticated );
                }
            }];
        }
    }
    return NULL;
}

DEFINE_ANE_FUNCTION( getLocalPlayer )
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if ( localPlayer && localPlayer.isAuthenticated )
    {
        FREObject asPlayer;
        if ( FRENewObject( ASLocalPlayer, 0, NULL, &asPlayer, NULL ) == FRE_OK
            && GC_FRESetObjectPropertyString( asPlayer, "id", localPlayer.playerID ) == FRE_OK
            && GC_FRESetObjectPropertyString( asPlayer, "alias", localPlayer.alias ) == FRE_OK )
        {
            return asPlayer;
        }
    }
    else
    {
        DISPATCH_STATUS_EVENT( context, "", notAuthenticated );
    }
    return NULL;
}

DEFINE_ANE_FUNCTION( reportScore )
{
    NSString* category;
    if( GC_FREGetObjectAsString( argv[0], &category ) != FRE_OK ) return NULL;
    
    int32_t scoreValue = 0;
    if( FREGetObjectAsInt32( argv[1], &scoreValue ) != FRE_OK ) return NULL;
    
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, "", notAuthenticated );
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
                DISPATCH_STATUS_EVENT( context, "", scoreReported );
            }
            else
            {
                DISPATCH_STATUS_EVENT( context, "", scoreNotReported );
            }
        }];
    }
    return NULL;
}

DEFINE_ANE_FUNCTION( showStandardLeaderboard )
{
    GC_createBoardsController( context );
    [GC_boardsController displayLeaderboard];
    return NULL;
}

DEFINE_ANE_FUNCTION( showStandardLeaderboardWithCategory )
{
    NSString* category;
    if( GC_FREGetObjectAsString( argv[0], &category ) != FRE_OK ) return NULL;
    
    GC_createBoardsController( context );
    [GC_boardsController displayLeaderboardWithCategory:category];
    return NULL;
}

DEFINE_ANE_FUNCTION( showStandardLeaderboardWithTimescope )
{
    int timeScope;
    if( FREGetObjectAsInt32( argv[1], &timeScope ) != FRE_OK ) return NULL;
    
    GC_createBoardsController( context );
    [GC_boardsController displayLeaderboardWithTimescope:timeScope];
    return NULL;
}

DEFINE_ANE_FUNCTION( showStandardLeaderboardWithCategoryAndTimescope )
{
    NSString* category;
    if( GC_FREGetObjectAsString( argv[0], &category ) != FRE_OK ) return NULL;
    int timeScope;
    if( FREGetObjectAsInt32( argv[1], &timeScope ) != FRE_OK ) return NULL;
    
    GC_createBoardsController( context );
    [GC_boardsController displayLeaderboardWithCategory:category andTimescope:timeScope];
    return NULL;
}

DEFINE_ANE_FUNCTION( getLeaderboard )
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, "", notAuthenticated );
        return NULL;
    }
    
    GKLeaderboard* leaderboard = [[GKLeaderboard alloc] init];
    
    NSString* propertyString;
    if( GC_FREGetObjectAsString( argv[0], &propertyString ) != FRE_OK ) return NULL;
    leaderboard.category = propertyString;
    
    int propertyInt;
    if( FREGetObjectAsInt32( argv[1], &propertyInt ) != FRE_OK ) return NULL;
    leaderboard.playerScope = propertyInt;
    
    if( FREGetObjectAsInt32( argv[2], &propertyInt ) != FRE_OK ) return NULL;
    leaderboard.timeScope = propertyInt;
    
    int propertyInt2;
    if( FREGetObjectAsInt32( argv[3], &propertyInt ) != FRE_OK ) return NULL;
    if( FREGetObjectAsInt32( argv[4], &propertyInt2 ) != FRE_OK ) return NULL;
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
                    NSString* code = GC_storeReturnObject( leaderboardWithNames );
                    DISPATCH_STATUS_EVENT( context, code.UTF8String, loadLeaderboardComplete );
                }
                else
                {
                    [leaderboardWithNames release];
                    DISPATCH_STATUS_EVENT( context, "", loadLeaderboardFailed );
                }
            }];
        }
        else
        {
            [leaderboard release];
            DISPATCH_STATUS_EVENT( context, "", loadLeaderboardFailed );
        }
    }];
    return NULL;
}

DEFINE_ANE_FUNCTION( reportAchievement )
{
    NSString* identifier;
    if( GC_FREGetObjectAsString( argv[0], &identifier ) != FRE_OK ) return NULL;
    
    double value = 0;
    if( FREGetObjectAsDouble( argv[1], &value ) != FRE_OK ) return NULL;
    
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, "", notAuthenticated );
        return NULL;
    }
    
    GKAchievement* achievement = [[[GKAchievement alloc] initWithIdentifier:identifier] autorelease];
    if( achievement )
    {
        achievement.percentComplete = value * 100;
        achievement.showsCompletionBanner = YES;
        [achievement reportAchievementWithCompletionHandler:^(NSError* error)
         {
             if( error == nil )
             {
                 DISPATCH_STATUS_EVENT( context, "", achievementReported );
             }
             else
             {
                 DISPATCH_STATUS_EVENT( context, "", achievementNotReported );
             }
         }];
    }
    return NULL;
}


DEFINE_ANE_FUNCTION( showStandardAchievements )
{
    GC_createBoardsController( context );
    [GC_boardsController displayAchievements];
    return NULL;
}

DEFINE_ANE_FUNCTION( getAchievements )
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, "", notAuthenticated );
        return NULL;
    }
    
    [GKAchievement loadAchievementsWithCompletionHandler:^( NSArray* achievements, NSError* error )
    {
        if( error == nil && achievements != nil )
        {
            [achievements retain];
            NSString* code = GC_storeReturnObject( achievements );
            DISPATCH_STATUS_EVENT( context, code.UTF8String, loadAchievementsComplete );
        }
        else
        {
            DISPATCH_STATUS_EVENT( context, "", loadAchievementsFailed );
        }
    }];
    return NULL;
}

DEFINE_ANE_FUNCTION( getLocalPlayerFriends )
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, "", notAuthenticated );
        return NULL;
    }
    [localPlayer loadFriendsWithCompletionHandler:^(NSArray *friendIds, NSError *error)
    {
        if ( error == nil && friendIds != nil )
        {
            if( friendIds.count == 0 )
            {
                [friendIds retain];
                NSString* code = GC_storeReturnObject( friendIds );
                DISPATCH_STATUS_EVENT( context, code.UTF8String, loadFriendsComplete );
            }
            else
            {
                [GKPlayer loadPlayersForIdentifiers:friendIds withCompletionHandler:^(NSArray *friendDetails, NSError *error)
                {
                    if ( error == nil && friendDetails != nil )
                    {
                        [friendDetails retain];
                        NSString* code = GC_storeReturnObject( friendDetails );
                        DISPATCH_STATUS_EVENT( context, code.UTF8String, loadFriendsComplete );
                    }
                    else
                    {
                        DISPATCH_STATUS_EVENT( context, "", loadFriendsFailed );
                    }
                }];
            }
        }
        else
        {
            DISPATCH_STATUS_EVENT( context, "", loadFriendsFailed );
        }
    }];
    return NULL;
}

DEFINE_ANE_FUNCTION( getLocalPlayerScore )
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, "", notAuthenticated );
        return NULL;
    }
    
    GKLeaderboard* leaderboard = [[GKLeaderboard alloc] init];

    NSString* propertyString;
    if( GC_FREGetObjectAsString( argv[0], &propertyString ) != FRE_OK ) return NULL;
    leaderboard.category = propertyString;

    int propertyInt;
    if( FREGetObjectAsInt32( argv[1], &propertyInt ) != FRE_OK ) return NULL;
    leaderboard.playerScope = propertyInt;
    
    if( FREGetObjectAsInt32( argv[2], &propertyInt ) != FRE_OK ) return NULL;
    leaderboard.timeScope = propertyInt;
    
    leaderboard.range = NSMakeRange( 1, 1 );
    
    [leaderboard loadScoresWithCompletionHandler:^( NSArray* scores, NSError* error )
    {
        if( error == nil && scores != nil )
        {
            NSString* code = GC_storeReturnObject( leaderboard );
            DISPATCH_STATUS_EVENT( context, code.UTF8String, loadLocalPlayerScoreComplete );
        }
        else
        {
            [leaderboard release];
            DISPATCH_STATUS_EVENT( context, "", loadLocalPlayerScoreFailed );
        }
    }];
    return NULL;
}

DEFINE_ANE_FUNCTION( getStoredLocalPlayerScore )
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, "", notAuthenticated );
        return NULL;
    }

    NSString* key;
    if( GC_FREGetObjectAsString( argv[0], &key ) != FRE_OK ) return NULL;

    GKLeaderboard* leaderboard = GC_getReturnObject( key );
    
    if( leaderboard == nil )
    {
        return NULL;
    }
    FREObject asLeaderboard;
    FREObject asScore;
    
    if ( FRENewObject( ASLeaderboard, 0, NULL, &asLeaderboard, NULL) == FRE_OK
        && GC_FRESetObjectPropertyInt( asLeaderboard, "timeScope", leaderboard.timeScope ) == FRE_OK
        && GC_FRESetObjectPropertyInt( asLeaderboard, "playerScope", leaderboard.playerScope ) == FRE_OK
        && GC_FRESetObjectPropertyString( asLeaderboard, "category", leaderboard.category ) == FRE_OK
        && GC_FRESetObjectPropertyString( asLeaderboard, "title", leaderboard.title ) == FRE_OK
        && GC_FRESetObjectPropertyInt( asLeaderboard, "rangeMax", leaderboard.maxRange ) == FRE_OK )
    {
        if( leaderboard.localPlayerScore && FRENewObjectFromGKScore( leaderboard.localPlayerScore, localPlayer, &asScore ) == FRE_OK )
        {
            FRESetObjectProperty( asLeaderboard, "localPlayerScore", asScore, NULL );
        }
        [leaderboard release];
        return asLeaderboard;
    }
    [leaderboard release];
    return NULL;
}

DEFINE_ANE_FUNCTION( getStoredLeaderboard )
{
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    if( !localPlayer.isAuthenticated )
    {
        DISPATCH_STATUS_EVENT( context, "", notAuthenticated );
        return NULL;
    }

    NSString* key;
    if( GC_FREGetObjectAsString( argv[0], &key ) != FRE_OK ) return NULL;

    LeaderboardWithNames* leaderboardWithNames = GC_getReturnObject( key );
    GKLeaderboard* leaderboard = leaderboardWithNames.leaderboard;
    NSDictionary* names = leaderboardWithNames.names;
    
    if( leaderboard == nil || names == nil )
    {
        return NULL;
    }
    FREObject asLeaderboard;
    FREObject asLocalScore;
    
    if ( FRENewObject( ASLeaderboard, 0, NULL, &asLeaderboard, NULL) == FRE_OK
        && GC_FRESetObjectPropertyInt( asLeaderboard, "timeScope", leaderboard.timeScope ) == FRE_OK
        && GC_FRESetObjectPropertyInt( asLeaderboard, "playerScope", leaderboard.playerScope ) == FRE_OK
        && GC_FRESetObjectPropertyString( asLeaderboard, "category", leaderboard.category ) == FRE_OK
        && GC_FRESetObjectPropertyString( asLeaderboard, "title", leaderboard.title ) == FRE_OK
        && GC_FRESetObjectPropertyInt( asLeaderboard, "rangeMax", leaderboard.maxRange ) == FRE_OK
        && GC_FRESetObjectPropertyInt( asLeaderboard, "rangeStart", leaderboard.range.location ) == FRE_OK
        && GC_FRESetObjectPropertyInt( asLeaderboard, "rangeLength", leaderboard.range.length ) == FRE_OK
        )
    {
        if( leaderboard.localPlayerScore && FRENewObjectFromGKScore( leaderboard.localPlayerScore, localPlayer, &asLocalScore ) == FRE_OK )
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
                        if( FRENewObjectFromGKScore( score, player, &asScore ) == FRE_OK )
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

DEFINE_ANE_FUNCTION( getStoredAchievements )
{
    NSString* key;
    if( GC_FREGetObjectAsString( argv[0], &key ) != FRE_OK ) return NULL;
    
    NSArray* achievements = GC_getReturnObject( key );
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
            if( FRENewObjectFromGKAchievement( achievement, &asAchievement ) == FRE_OK )
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

DEFINE_ANE_FUNCTION( getStoredPlayers )
{
    NSString* key;
    if( GC_FREGetObjectAsString( argv[0], &key ) != FRE_OK ) return NULL;

    NSArray* friendDetails = GC_getReturnObject( key );
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
            if( FRENewObjectFromGKPlayer( friend, &asPlayer ) == FRE_OK )
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

void GameCenterContextInitializer( void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToSet, const FRENamedFunction** functionsToSet )
{
    static FRENamedFunction functionMap[] = {
        MAP_FUNCTION( isSupported, NULL ),
        MAP_FUNCTION( authenticateLocalPlayer, NULL ),
        MAP_FUNCTION( getLocalPlayer, NULL ),
        MAP_FUNCTION( reportScore, NULL ),
        MAP_FUNCTION( reportAchievement, NULL ),
        MAP_FUNCTION( showStandardLeaderboard, NULL ),
        MAP_FUNCTION( showStandardLeaderboardWithCategory, NULL ),
        MAP_FUNCTION( showStandardLeaderboardWithTimescope, NULL ),
        MAP_FUNCTION( showStandardLeaderboardWithCategoryAndTimescope, NULL ),
        MAP_FUNCTION( showStandardAchievements, NULL ),
        MAP_FUNCTION( getLocalPlayerFriends, NULL ),
        MAP_FUNCTION( getLocalPlayerScore, NULL ),
        MAP_FUNCTION( getLeaderboard, NULL ),
        MAP_FUNCTION( getStoredLeaderboard, NULL ),
        MAP_FUNCTION( getStoredLocalPlayerScore, NULL ),
        MAP_FUNCTION( getStoredPlayers, NULL ),
        MAP_FUNCTION( getAchievements, NULL ),
        MAP_FUNCTION( getStoredAchievements, NULL )
    };
    
	*numFunctionsToSet = sizeof( functionMap ) / sizeof( FRENamedFunction );
	*functionsToSet = functionMap;
}

void GameCenterContextFinalizer( FREContext ctx )
{
	return;
}

void GameCenterExtensionInitializer( void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet ) 
{ 
    extDataToSet = NULL;  // This example does not use any extension data. 
    *ctxInitializerToSet = &GameCenterContextInitializer;
    *ctxFinalizerToSet = &GameCenterContextFinalizer;
    GC_returnObjects = [[NSMutableDictionary alloc] init];
}

void GameCenterExtensionFinalizer()
{
    return;
}
