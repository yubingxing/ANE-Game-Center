//
//  LeaderboardWithNames.m
//  GameCenterIosExtension
//
//  Created by Richard Lord on 03/04/2012.
//  Copyright (c) 2012 Stick Sports Ltd. All rights reserved.
//

#import "LeaderboardWithNames.h"

@implementation LeaderboardWithNames

@synthesize leaderboard, names;

-(id) initWithLeaderboard:(GKLeaderboard*)lb
{
    self = [super init];
    if( self )
    {
        leaderboard = lb;
    }
    return self;
}

-(void) dealloc
{
    [leaderboard release];
    [names release];
    [super dealloc];
}

@end
