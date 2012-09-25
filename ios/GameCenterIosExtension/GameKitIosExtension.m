//
//  GameKitIosExtension
//  GameKitIosExtension.m
//
//  Created by Richard Lord on 19/12/2011.
//  Copyright (c) 2012 Stick Sports Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlashRuntimeExtensions.h"
#import "GameKitHandler.h"
#import "GC_NativeMessages.h"

#define DEFINE_ANE_FUNCTION(fn) FREObject (fn)(FREContext context, void* functionData, uint32_t argc, FREObject argv[])

#define MAP_FUNCTION(fn, data) { (const uint8_t*)(#fn), (data), &(fn) }

GameKitHandler* GC_handler;

DEFINE_ANE_FUNCTION( GC_isSupported )
{
    return [GC_handler isSupported];
}

DEFINE_ANE_FUNCTION( GC_authenticateLocalPlayer )
{
    return [GC_handler authenticateLocalPlayer];
}

DEFINE_ANE_FUNCTION( GC_getLocalPlayer )
{
    return [GC_handler getLocalPlayer];
}

DEFINE_ANE_FUNCTION( GC_reportScore )
{
    return [GC_handler reportScore:argv[1] inCategory:argv[0]];
}

DEFINE_ANE_FUNCTION( GC_showStandardLeaderboard )
{
    return [GC_handler showStandardLeaderboard];
}

DEFINE_ANE_FUNCTION( GC_showStandardLeaderboardWithCategory )
{
    return [GC_handler showStandardLeaderboardWithCategory:argv[0]];
}

DEFINE_ANE_FUNCTION( GC_showStandardLeaderboardWithTimescope )
{
    return [GC_handler showStandardLeaderboardWithTimescope:argv[0]];
}

DEFINE_ANE_FUNCTION( GC_showStandardLeaderboardWithCategoryAndTimescope )
{
    return [GC_handler showStandardLeaderboardWithCategory:argv[0] andTimescope:argv[1]];
}

DEFINE_ANE_FUNCTION( GC_getLeaderboard )
{
    return [GC_handler getLeaderboardWithCategory:argv[0] playerScope:argv[1] timeScope:argv[2] rangeMin:argv[3] rangeMax:argv[4]];
}

DEFINE_ANE_FUNCTION( GC_reportAchievement )
{
    return [GC_handler reportAchievement:argv[0] withValue:argv[1] andBanner:argv[2]];
}

DEFINE_ANE_FUNCTION( GC_showStandardAchievements )
{
    return [GC_handler showStandardAchievements];
}

DEFINE_ANE_FUNCTION( GC_getAchievements )
{
    return [GC_handler getAchievements];
}

DEFINE_ANE_FUNCTION( GC_getLocalPlayerFriends )
{
    return [GC_handler getLocalPlayerFriends];
}

DEFINE_ANE_FUNCTION( GC_getLocalPlayerScore )
{
    return [GC_handler getLocalPlayerScoreInCategory:argv[0] playerScope:argv[1] timeScope:argv[2]];
}

DEFINE_ANE_FUNCTION( GC_getStoredLocalPlayerScore )
{
    return [GC_handler getStoredLocalPlayerScore:argv[0]];
}

DEFINE_ANE_FUNCTION( GC_getStoredLeaderboard )
{
    return [GC_handler getStoredLeaderboard:argv[0]];
}

DEFINE_ANE_FUNCTION( GC_getStoredAchievements )
{
    return [GC_handler getStoredAchievements:argv[0]];
}

DEFINE_ANE_FUNCTION( GC_getStoredPlayers )
{
    return [GC_handler getStoredPlayers:argv[0]];
}

DEFINE_ANE_FUNCTION( GC_alert )
{
    return [GC_handler alert:argv[0] msg:argv[1]];
}

DEFINE_ANE_FUNCTION( GC_getSystemLocaleLanguage )
{
    return [GC_handler getSystemLocaleLanguage];
}

DEFINE_ANE_FUNCTION( GC_isBluetoothAvailable)
{
    return [GC_handler isBluetoothAvailable];
}
//============================add GameKit match func================================
DEFINE_ANE_FUNCTION( GC_showMatchMaker )
{
    return [GC_handler showMatchMaker:argv[0] maxPlayers:argv[1]];
}

DEFINE_ANE_FUNCTION( GC_sendDataToGCPlayers ) {
    return [GC_handler sendDataToGCPlayers:argv[0] msg:argv[1]];
}

DEFINE_ANE_FUNCTION( GC_sendData ) {
    return [GC_handler sendData:argv[0]];
}
//=============================add local p2p func==================================
DEFINE_ANE_FUNCTION( LP_requestPeerMatch ) {
    return [GC_handler requestPeerMatch:argv[0] sessionMode:argv[1] expectedPlayerCount:argv[2]];
}

DEFINE_ANE_FUNCTION( LP_joinServer ) {
    return [GC_handler joinServer:argv[0]];
}

DEFINE_ANE_FUNCTION( LP_acceptPeer ) {
    return [GC_handler acceptPeer:argv[0]];
}

DEFINE_ANE_FUNCTION( LP_denyPeer ) {
    return [GC_handler denyPeer:argv[0]];
}

void GameKitContextInitializer( void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToSet, const FRENamedFunction** functionsToSet )
{
    static FRENamedFunction functionMap[] = {
        //======================add GameKit match func=====================
        MAP_FUNCTION( GC_showMatchMaker, NULL ),
        MAP_FUNCTION( GC_sendData, NULL ),
        MAP_FUNCTION( GC_sendDataToGCPlayers, NULL),
        //======================add local p2p connection======================
        MAP_FUNCTION( LP_requestPeerMatch, NULL ),
        MAP_FUNCTION( LP_joinServer, NULL ),
        MAP_FUNCTION( LP_acceptPeer, NULL ),
        MAP_FUNCTION( LP_denyPeer, NULL ),
        //======================leaderboard and achievement support=====================
        MAP_FUNCTION( GC_isSupported, NULL ),
        MAP_FUNCTION( GC_authenticateLocalPlayer, NULL ),
        MAP_FUNCTION( GC_getLocalPlayer, NULL ),
        MAP_FUNCTION( GC_reportScore, NULL ),
        MAP_FUNCTION( GC_reportAchievement, NULL ),
        MAP_FUNCTION( GC_showStandardLeaderboard, NULL ),
        MAP_FUNCTION( GC_showStandardLeaderboardWithCategory, NULL ),
        MAP_FUNCTION( GC_showStandardLeaderboardWithTimescope, NULL ),
        MAP_FUNCTION( GC_showStandardLeaderboardWithCategoryAndTimescope, NULL ),
        MAP_FUNCTION( GC_showStandardAchievements, NULL ),
        MAP_FUNCTION( GC_getLocalPlayerFriends, NULL ),
        MAP_FUNCTION( GC_getLocalPlayerScore, NULL ),
        MAP_FUNCTION( GC_getLeaderboard, NULL ),
        MAP_FUNCTION( GC_getStoredLeaderboard, NULL ),
        MAP_FUNCTION( GC_getStoredLocalPlayerScore, NULL ),
        MAP_FUNCTION( GC_getStoredPlayers, NULL ),
        MAP_FUNCTION( GC_getAchievements, NULL ),
        MAP_FUNCTION( GC_getStoredAchievements, NULL ),
        MAP_FUNCTION( GC_alert, NULL ),
        MAP_FUNCTION( GC_isBluetoothAvailable, NULL ),
        MAP_FUNCTION( GC_getSystemLocaleLanguage, NULL)
    };
    
	*numFunctionsToSet = sizeof( functionMap ) / sizeof( FRENamedFunction );
	*functionsToSet = functionMap;
    
    GC_handler = [[GameKitHandler alloc] initWithContext:ctx];
}

void GameKitContextFinalizer( FREContext ctx )
{
    NSLog(@"Context Distroyed");
	return;
}

void GameKitExtensionInitializer( void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet ) 
{
    NSLog(@"Context Initialized");
    extDataToSet = NULL;  // This example does not use any extension data.
    *ctxInitializerToSet = &GameKitContextInitializer;
    *ctxFinalizerToSet = &GameKitContextFinalizer;
}

void GameKitExtensionFinalizer()
{
    NSLog(@"Context Distroyed");
    return;
}
