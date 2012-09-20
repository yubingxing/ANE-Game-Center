//
//  BoardsViewController.h
//  GameCenterIosExtension
//
//  Created by Richard Lord on 20/12/2011.
//  Copyright (c) 2011 Stick Sports Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import "FlashRuntimeExtensions.h"
#import "GC_BoardsController.h"
#import "GameCenterHandler.h"

@interface BoardsControllerPhone : UIViewController <BoardsController,GKLeaderboardViewControllerDelegate,GKAchievementViewControllerDelegate,GKMatchmakerViewControllerDelegate>
{
    
}
-(id) initWithContext:(FREContext)context;
-(void) displayLeaderboard;
-(void) displayLeaderboardWithCategory:(NSString*)category;
-(void) displayLeaderboardWithCategory:(NSString*)category andTimescope:(int)timeScope;
-(void) displayLeaderboardWithTimescope:(int)timeScope;
-(void) displayAchievements;
-(void) displayMatchMaker:(uint32_t)min max:(uint32_t)max;
@end
