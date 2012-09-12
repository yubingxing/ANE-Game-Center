//
//  HelloWorldLayer.h
//  CatRace
//
//  Created by Ray Wenderlich on 4/23/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "PlayerSprite.h"
#import "GCHelper.h"

typedef enum {
    kEndReasonWin,
    kEndReasonLose
} EndReason;

typedef enum {
    kGameStateActive,
    kGameStateDone
} GameState;

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer <GCHelperDelegate>
{
    CCSpriteBatchNode *batchNode;
    
    CCSprite *cat;
    PlayerSprite *player1;
    PlayerSprite *player2;
    BOOL isPlayer1;        
    CCLabelBMFont *debugLabel;
    GameState gameState;
    
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
