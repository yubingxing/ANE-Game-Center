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
    kMessageTypeRandomNumber = 0,
    kMessageTypeGameBegin,
    kMessageTypeMove,
    kMessageTypeGameOver
} MessageType;

typedef struct {
    MessageType messageType;
} Message;

typedef struct {
    Message message;
    uint32_t randomNumber;
} MessageRandomNumber;

typedef struct {
    Message message;
} MessageGameBegin;

typedef struct {
    Message message;
} MessageMove;

typedef struct {
    Message message;
    BOOL player1Won;
} MessageGameOver;

typedef enum {
    kEndReasonWin,
    kEndReasonLose,
    kEndReasonDisconnect
} EndReason;

typedef enum {
    kGameStateWaitingForMatch = 0,
    kGameStateWaitingForRandomNumber,
    kGameStateWaitingForStart,
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
    
    uint32_t ourRandom;   
    BOOL receivedRandom;    
    NSString *otherPlayerID;
    
    CCLabelBMFont *player1Label;
    CCLabelBMFont *player2Label;
    
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
