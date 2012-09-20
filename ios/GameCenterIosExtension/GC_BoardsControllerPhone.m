//
//  BoardsViewController.m
//  GameCenterIosExtension
//
//  Created by Richard Lord on 20/12/2011.
//  Copyright (c) 2011 Stick Sports Ltd. All rights reserved.
//

#import "GC_BoardsControllerPhone.h"
#import "GC_NativeMessages.h"

@interface BoardsControllerPhone () {
}

@property (retain) UIWindow* win;
@property FREContext context;

@end

@implementation BoardsControllerPhone

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
    [self dismissModalViewControllerAnimated:YES];
    [self.view.superview removeFromSuperview];
    FREDispatchStatusEventAsync(context, (const uint8_t*)"", gameCenterViewRemoved);
}

- (void)achievementViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
    [self dismissModalViewControllerAnimated:YES];
    [self.view.superview removeFromSuperview];
    FREDispatchStatusEventAsync(context, (const uint8_t*)"", gameCenterViewRemoved);
}

-(void) displayLeaderboard
{
    GKLeaderboardViewController *leaderboardController = [[[GKLeaderboardViewController alloc] init] autorelease];
    if( leaderboardController != nil )
    {
        leaderboardController.leaderboardDelegate = self;
        [win addSubview:self.view];
        [self presentModalViewController: leaderboardController animated: YES];
    }
}

-(void) displayLeaderboardWithCategory:(NSString*)category
{
    GKLeaderboardViewController *leaderboardController = [[[GKLeaderboardViewController alloc] init] autorelease];
    if( leaderboardController != nil )
    {
        leaderboardController.category = category;
        leaderboardController.leaderboardDelegate = self;
        [win addSubview:self.view];
        [self presentModalViewController: leaderboardController animated: YES];
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
        [win addSubview:self.view];
        [self presentModalViewController: leaderboardController animated: YES];
    }
}

-(void) displayLeaderboardWithTimescope:(int)timeScope
{
    GKLeaderboardViewController *leaderboardController = [[[GKLeaderboardViewController alloc] init] autorelease];
    if( leaderboardController != nil )
    {
        leaderboardController.timeScope = timeScope;
        leaderboardController.leaderboardDelegate = self;
        [win addSubview:self.view];
        [self presentModalViewController: leaderboardController animated: YES];
    }
}

-(void) displayAchievements
{
    GKAchievementViewController *achievementController = [[[GKAchievementViewController alloc] init] autorelease];
    if( achievementController != nil )
    {
        achievementController.achievementDelegate = self;
        [win addSubview:self.view];
        [self presentModalViewController: achievementController animated: YES];
    }
}

-(void) displayMatchMaker:(uint32_t)min max:(uint32_t)max
{
    GameCenterHandler *gc = [GameCenterHandler sharedInstance];
    [[self presentingViewController] dismissModalViewControllerAnimated:NO];
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
    [win addSubview:self.view];
    [self presentModalViewController:mmvc animated:YES];
    gc.pendingInvite = nil;
    gc.pendingPlayersToInvite = nil;
}


#pragma mark GKMatchmakerViewControllerDelegate

// The user has cancelled matchmaking
- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController {
    [[self presentingViewController] dismissModalViewControllerAnimated:YES];
    [self dismissModalViewControllerAnimated:YES];
    [self.view.superview removeFromSuperview];
    FREDispatchStatusEventAsync(context, (const uint8_t*)"", gameCenterViewRemoved);
}

// Matchmaking has failed with an error
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
    [[self presentingViewController] dismissModalViewControllerAnimated:YES];
    NSLog(@"Error finding match: %@", error.localizedDescription);
}

// A peer-to-peer match has been found, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)theMatch {
    [[self presentingViewController] dismissModalViewControllerAnimated:YES];
    GameCenterHandler *gc = [GameCenterHandler sharedInstance];
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
