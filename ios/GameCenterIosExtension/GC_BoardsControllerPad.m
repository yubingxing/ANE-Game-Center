//
//  BoardsControllerPad.m
//  GameCenterIosExtension
//
//  Created by Richard Lord on 01/02/2012.
//  Copyright (c) 2012 Stick Sports Ltd. All rights reserved.
//

#import "GC_BoardsControllerPad.h"
#import "GC_NativeMessages.h"

@interface BoardsControllerPad () {
}

@property (retain) UIWindow* win;
@property FREContext context;

@end

@implementation BoardsControllerPad

@synthesize win,context;

- (id)initWithContext:(FREContext)extensionContext
{
    self = [super init];
    if( self )
    {
        win = [UIApplication sharedApplication].keyWindow;
        context = extensionContext;
    }
    return self;
}

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
    [win.rootViewController dismissModalViewControllerAnimated:YES];
    FREDispatchStatusEventAsync(context, (const uint8_t *)"", gameCenterViewRemoved);
}

- (void)achievementViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
    [win.rootViewController dismissModalViewControllerAnimated:YES];
    FREDispatchStatusEventAsync(context, (const uint8_t *)"", gameCenterViewRemoved);
}

-(void) displayLeaderboard
{
    GKLeaderboardViewController *leaderboardController = [[[GKLeaderboardViewController alloc] init] autorelease];
    if( leaderboardController != nil )
    {
        leaderboardController.leaderboardDelegate = self;
        [win.rootViewController presentModalViewController: leaderboardController animated: YES];
    }
}

-(void) displayLeaderboardWithCategory:(NSString*)category
{
    GKLeaderboardViewController *leaderboardController = [[[GKLeaderboardViewController alloc] init] autorelease];
    if( leaderboardController != nil )
    {
        leaderboardController.category = category;
        leaderboardController.leaderboardDelegate = self;
        [win.rootViewController presentModalViewController: leaderboardController animated: YES];
    }
}

-(void) displayLeaderboardWithCategory:(NSString*)category andTimescope:(int)timeScope
{
    GKLeaderboardViewController *leaderboardController = [[[GKLeaderboardViewController alloc] init] autorelease];
    if( leaderboardController != nil )
    {
        leaderboardController.category = category;
        leaderboardController.timeScope = timeScope;
        leaderboardController.leaderboardDelegate = self;
        [win.rootViewController presentModalViewController: leaderboardController animated: YES];
    }
}

-(void) displayLeaderboardWithTimescope:(int)timeScope
{
    GKLeaderboardViewController *leaderboardController = [[[GKLeaderboardViewController alloc] init] autorelease];
    if( leaderboardController != nil )
    {
        leaderboardController.timeScope = timeScope;
        leaderboardController.leaderboardDelegate = self;
        [win.rootViewController presentModalViewController: leaderboardController animated: YES];
    }
}

-(void) displayAchievements
{
    GKAchievementViewController *achievementController = [[[GKAchievementViewController alloc] init] autorelease];
    if( achievementController != nil )
    {
        achievementController.achievementDelegate = self;
        [win.rootViewController presentModalViewController: achievementController animated: YES];
    }
}

-(void) displayMatchMaker:(uint32_t)min max:(uint32_t)max
{
    GameKitHandler *gc = [GameKitHandler sharedInstance];
    [win.rootViewController dismissModalViewControllerAnimated:YES];
    GKMatchmakerViewController *mmvc = nil;
    if (gc.pendingInvite != nil) {
        mmvc = [[[GKMatchmakerViewController alloc] initWithInvite:gc.pendingInvite] autorelease];
    } else {
        GKMatchRequest *request = [[[GKMatchRequest alloc] init] autorelease];
        request.minPlayers = min;
        request.maxPlayers = max;
        request.playersToInvite = gc.pendingPlayersToInvite;
        mmvc = [[[GKMatchmakerViewController alloc] initWithMatchRequest:request] autorelease];
    }
    
    mmvc.matchmakerDelegate = self;
    [win.rootViewController presentModalViewController:mmvc animated:YES];
    gc.pendingInvite = nil;
    gc.pendingPlayersToInvite = nil;
}


#pragma mark GKMatchmakerViewControllerDelegate

// The user has cancelled matchmaking
- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController
{
    [win.rootViewController dismissModalViewControllerAnimated:YES];
    FREDispatchStatusEventAsync(context, (const uint8_t *)"", gameCenterViewRemoved);

}

// Matchmaking has failed with an error
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    [win.rootViewController dismissModalViewControllerAnimated:YES];
    NSLog(@"Error finding match: %@", error.localizedDescription);
}

// A peer-to-peer match has been found, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)theMatch
{
    [win.rootViewController dismissModalViewControllerAnimated:YES];
    GameKitHandler *gc = [GameKitHandler sharedInstance];
    gc.match = theMatch;
    theMatch.delegate = gc;
    if (!gc.isMatchStarted && theMatch.expectedPlayerCount == 0) {
        NSLog(@"Ready to start match!");
        [gc lookupPlayers];
    }
}


#pragma mark - Lifecycle

- (void)dealloc
{
    [super dealloc];
}

@end
