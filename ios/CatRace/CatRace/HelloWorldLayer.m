//
//  HelloWorldLayer.m
//  CatRace
//
//  Created by Ray Wenderlich on 4/23/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "AppDelegate.h"
#import "RootViewController.h"

// HelloWorldLayer implementation
@implementation HelloWorldLayer

- (void)setGameState:(GameState)state {
    
    gameState = state;
    if (gameState == kGameStateWaitingForMatch) {
        [debugLabel setString:@"Waiting for match"];
    } else if (gameState == kGameStateWaitingForRandomNumber) {
        [debugLabel setString:@"Waiting for rand #"];
    } else if (gameState == kGameStateWaitingForStart) {
        [debugLabel setString:@"Waiting for start"];
    } else if (gameState == kGameStateActive) {
        [debugLabel setString:@"Active"];
    } else if (gameState == kGameStateDone) {
        [debugLabel setString:@"Done"];
    } 
    
}

- (void)sendData:(NSData *)data {
    NSError *error;
    BOOL success = [[GCHelper sharedInstance].match sendDataToAllPlayers:data withDataMode:GKMatchSendDataReliable error:&error];
    if (!success) {
        CCLOG(@"Error sending init packet");
        [self matchEnded];
    }
}

- (void)sendRandomNumber {
    
    MessageRandomNumber message;
    message.message.messageType = kMessageTypeRandomNumber;
    message.randomNumber = ourRandom;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageRandomNumber)];    
    [self sendData:data];
}

- (void)sendGameBegin {
    
    MessageGameBegin message;
    message.message.messageType = kMessageTypeGameBegin;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageGameBegin)];    
    [self sendData:data];
    
}

- (void)sendMove {
    
    MessageMove message;
    message.message.messageType = kMessageTypeMove;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageMove)];    
    [self sendData:data];
    
}

- (void)sendGameOver:(BOOL)player1Won {
    
    MessageGameOver message;
    message.message.messageType = kMessageTypeGameOver;
    message.player1Won = player1Won;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(MessageGameOver)];    
    [self sendData:data];
    
}

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
        // Get win size
        CGSize winSize = [CCDirector sharedDirector].winSize;
        
        // Add background
        CCSprite *bg = [CCSprite spriteWithFile:@"bg.png"];
        bg.anchorPoint = CGPointZero;
        [self addChild:bg z:-2];
        
        // Add batch node
        batchNode = [CCSpriteBatchNode batchNodeWithFile:@"CatSmash.png"];
        [self addChild:batchNode z:-1];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"CatSmash.plist"];
        
        // Create sprite for cat
        float catYOffset = 35;
        cat = [CCSprite spriteWithSpriteFrameName:@"cat_stand_1.png"];
        cat.position = ccp(winSize.width-cat.contentSize.width/2, cat.contentSize.height/2 + catYOffset);
        [batchNode addChild:cat z:1];
        
        // Create sprites for each player
        player1 = [[[PlayerSprite alloc] initWithType:kPlayerSpriteDog] autorelease];
        player2 = [[[PlayerSprite alloc] initWithType:kPlayerSpriteKid] autorelease];
        [batchNode addChild:player1 z:2];
        [batchNode addChild:player2 z:0];
        
        // Set positions of each player
        float maxWidth = MAX(player1.contentSize.width, player2.contentSize.width);        
        float playersYOffset = 50;     
        float playersXOffset = -(maxWidth-MIN(player1.contentSize.width, player2.contentSize.width)); 
        player1.position = ccp(maxWidth-player1.contentSize.width + player1.contentSize.width/2 + playersXOffset, 
                               player1.contentSize.height/2);
        player1.moveTarget = player1.position;
        player2.position = ccp(maxWidth-player2.contentSize.width + player2.contentSize.width/2 + playersXOffset, 
                               player1.contentSize.height/2 + playersYOffset);
        player2.moveTarget = player2.position;
        
        // Enable touches
        self.isTouchEnabled = YES;
        
        // Set up main loop to check for wins
        [self scheduleUpdate];       
        
        // Add a debug label to the scene to display current game state
        debugLabel = [CCLabelBMFont labelWithString:@"" fntFile:@"Arial.fnt"];
        debugLabel.position = ccp(winSize.width/2, 300);
        [self addChild:debugLabel];
        
        // Set ourselves as player 1 and the game to active
        isPlayer1 = YES;
        //[self setGameState:kGameStateActive];
        
        AppDelegate * delegate = (AppDelegate *) [UIApplication sharedApplication].delegate;                
        [[GCHelper sharedInstance] findMatchWithMinPlayers:2 maxPlayers:2 viewController:delegate.viewController delegate:self];
        
        ourRandom = arc4random();
        [self setGameState:kGameStateWaitingForMatch];
        		
	}
	return self;
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
       
    if (gameState != kGameStateActive) return;
    [self sendMove];
    
    // Move the appropriate player forward a bit
    if (isPlayer1) {
        [player1 moveForward];
    } else {
        [player2 moveForward];
    }
    
}

- (void)restartTapped:(id)sender {
    
    // Reload the current scene
    [[CCDirector sharedDirector] replaceScene:[CCTransitionZoomFlipX transitionWithDuration:0.5 scene:[HelloWorldLayer scene]]];
    
}

// Helper code to show a menu to restart the level
// From Cat Nap tutorial
- (void)endScene:(EndReason)endReason {
        
    if (gameState == kGameStateDone) return;
    [self setGameState:kGameStateDone];
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    NSString *message;
    if (endReason == kEndReasonWin) {
        message = @"You win!";
    } else if (endReason == kEndReasonLose) {
        message = @"You lose!";
    }
    
    CCLabelBMFont *label = [CCLabelBMFont labelWithString:message fntFile:@"Arial.fnt"];
    label.scale = 0.1;
    label.position = ccp(winSize.width/2, 180);
    [self addChild:label];
    
    CCLabelBMFont *restartLabel = [CCLabelBMFont labelWithString:@"Restart" fntFile:@"Arial.fnt"];    
    
    CCMenuItemLabel *restartItem = [CCMenuItemLabel itemWithLabel:restartLabel target:self selector:@selector(restartTapped:)];
    restartItem.scale = 0.1;
    restartItem.position = ccp(winSize.width/2, 140);
    
    CCMenu *menu = [CCMenu menuWithItems:restartItem, nil];
    menu.position = CGPointZero;
    [self addChild:menu];
    
    [restartItem runAction:[CCScaleTo actionWithDuration:0.5 scale:1.0]];
    [label runAction:[CCScaleTo actionWithDuration:0.5 scale:1.0]];
        
    if (isPlayer1) {
        if (endReason == kEndReasonWin) {
            [self sendGameOver:true];
        } else if (endReason == kEndReasonLose) {
            [self sendGameOver:false];
        }
    }
    
}

- (void)update:(ccTime)dt {
    
    player1Label.position = player1.position;
    player2Label.position = player2.position;
    
    if (!isPlayer1) return;
    
    // Check to see if player 1 or player 2 has passed the cat's center
    if (player1.position.x + player1.contentSize.width/2 > cat.position.x) {
        if (isPlayer1) {
            [self endScene:kEndReasonWin];
        } else {
            [self endScene:kEndReasonLose];
        }
    } else if (player2.position.x + player2.contentSize.width/2 > cat.position.x) {
        if (isPlayer1) {
            [self endScene:kEndReasonLose];
        } else {
            [self endScene:kEndReasonWin];
        }
    }

}

- (void)tryStartGame {
    
    if (isPlayer1 && gameState == kGameStateWaitingForStart) {
        [self setGameState:kGameStateActive];
        [self sendGameBegin];
        [self setupStringsWithOtherPlayerId:otherPlayerID];
    }
    
}

- (void)setupStringsWithOtherPlayerId:(NSString *)playerID {
    
    if (isPlayer1) {
        
        player1Label = [CCLabelBMFont labelWithString:[GKLocalPlayer localPlayer].alias fntFile:@"Arial.fnt"];
        [self addChild:player1Label];
        
        GKPlayer *player = [[GCHelper sharedInstance].playersDict objectForKey:playerID];
        player2Label = [CCLabelBMFont labelWithString:player.alias fntFile:@"Arial.fnt"];
        [self addChild:player2Label];
        
    } else {
        
        player2Label = [CCLabelBMFont labelWithString:[GKLocalPlayer localPlayer].alias fntFile:@"Arial.fnt"];
        [self addChild:player2Label];
        
        GKPlayer *player = [[GCHelper sharedInstance].playersDict objectForKey:playerID];
        player1Label = [CCLabelBMFont labelWithString:player.alias fntFile:@"Arial.fnt"];
        [self addChild:player1Label];
        
    }
    
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
    [otherPlayerID release];
    otherPlayerID = nil;
    
	// don't forget to call "super dealloc"
	[super dealloc];
}

 

- (void)matchStarted {    
    CCLOG(@"Match started");        
    if (receivedRandom) {
        [self setGameState:kGameStateWaitingForStart];
    } else {
        [self setGameState:kGameStateWaitingForRandomNumber];
    }
    [self sendRandomNumber];
    [self tryStartGame];
}

- (void)inviteReceived {
    [self restartTapped:nil];    
}

- (void)matchEnded {    
    CCLOG(@"Match ended");    
    [[GCHelper sharedInstance].match disconnect];
    [GCHelper sharedInstance].match = nil;
    [self endScene:kEndReasonDisconnect];
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {
    
    // Store away other player ID for later
    if (otherPlayerID == nil) {
        otherPlayerID = [playerID retain];
    }
    
    Message *message = (Message *) [data bytes];
    if (message->messageType == kMessageTypeRandomNumber) {
        
        MessageRandomNumber * messageInit = (MessageRandomNumber *) [data bytes];
        CCLOG(@"Received random number: %ud, ours %ud", messageInit->randomNumber, ourRandom);
        bool tie = false;
        
        if (messageInit->randomNumber == ourRandom) {
            CCLOG(@"TIE!");
            tie = true;
            ourRandom = arc4random();
            [self sendRandomNumber];
        } else if (ourRandom > messageInit->randomNumber) {            
            CCLOG(@"We are player 1");
            isPlayer1 = YES;            
        } else {
            CCLOG(@"We are player 2");
            isPlayer1 = NO;
        }
        
        if (!tie) {
            receivedRandom = YES;    
            if (gameState == kGameStateWaitingForRandomNumber) {
                [self setGameState:kGameStateWaitingForStart];
            }
            [self tryStartGame];        
        }
        
    } else if (message->messageType == kMessageTypeGameBegin) {        
        
        [self setGameState:kGameStateActive];
        [self setupStringsWithOtherPlayerId:playerID];
        
    } else if (message->messageType == kMessageTypeMove) {     
        
        CCLOG(@"Received move");
        
        if (isPlayer1) {
            [player2 moveForward];
        } else {
            [player1 moveForward];
        }        
    } else if (message->messageType == kMessageTypeGameOver) {        
        
        MessageGameOver * messageGameOver = (MessageGameOver *) [data bytes];
        CCLOG(@"Received game over with player 1 won: %d", messageGameOver->player1Won);
        
        if (messageGameOver->player1Won) {
            [self endScene:kEndReasonLose];    
        } else {
            [self endScene:kEndReasonWin];    
        }
        
    }
}


@end
