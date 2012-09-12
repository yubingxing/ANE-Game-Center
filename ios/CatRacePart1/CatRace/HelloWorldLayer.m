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
    if (gameState == kGameStateActive) {
        [debugLabel setString:@"Active"];
    } else if (gameState == kGameStateDone) {
        [debugLabel setString:@"Done"];
    } 
    
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
        [self setGameState:kGameStateActive];
        
        AppDelegate * delegate = (AppDelegate *) [UIApplication sharedApplication].delegate;                
        [[GCHelper sharedInstance] findMatchWithMinPlayers:2 maxPlayers:2 viewController:delegate.viewController delegate:self];
        		
	}
	return self;
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
       
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
        
}

- (void)update:(ccTime)dt {
    
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

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

#pragma mark GCHelperDelegate

- (void)matchStarted {    
    CCLOG(@"Match started");        
}

- (void)matchEnded {    
    CCLOG(@"Match ended");    
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {
    CCLOG(@"Received data");
}

@end
