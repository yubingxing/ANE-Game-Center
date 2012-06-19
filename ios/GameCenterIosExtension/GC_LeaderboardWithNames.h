//
//  LeaderboardWithNames.h
//  GameCenterIosExtension
//
//  Created by Richard Lord on 03/04/2012.
//  Copyright (c) 2012 Stick Sports Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface LeaderboardWithNames : NSObject
{
}
@property (retain) GKLeaderboard* leaderboard;
@property (retain) NSDictionary* names;

-(id) initWithLeaderboard:(GKLeaderboard*)lb;
@end
