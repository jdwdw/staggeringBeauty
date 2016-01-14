//
//  CMSpringyRopeLayer.m
//  DynamicXrayCatalog
//
//  Created by Chris Miles on 30/09/13.
//  Copyright (c) 2013-2014 Chris Miles. All rights reserved.
//
//  Based on CMTraerPhysics demo by Chris Miles, https://github.com/chrismiles/CMTraerPhysics
//  Based on traerAS3 example by Arnaud Icard, https://github.com/sqrtof5/traerAS3
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "CMSpringyRopeLayer.h"
#import "CMSpringyRopeParticle.h"
#import "CMSpringyRopeSmoothedPath.h"
#import <GameKit/GameKit.h>
@import CoreMotion;


//#import <DynamicXray/DynamicXray.h>


/*
    Physics Configuration
 */
static CGFloat const CMSpringyRopeDamping = 1.0f;
static CGFloat const CMSpringyRopeFrequency = 4.0f;
static CGFloat const CMSpringyRopeParticleDensity = 1.0f;
static CGFloat const CMSpringyRopeParticleResistance = 1.0f;

/*
    Visual Configuration
 */
static CGFloat const CMSpringyRopeLength =300.0f;
static NSUInteger const CMSpringyRopeSubdivisons = 8;
static CGFloat const CMSpringyRopeHandleRadius = 5.0f;




static CGFloat const stressNumber=1300;

/*
    Utility Functions
 */
static CGFloat CGPointDistance(CGPoint userPosition, CGPoint prevPosition)
{
    CGFloat dx = prevPosition.x - userPosition.x;
    CGFloat dy = prevPosition.y - userPosition.y;
    return sqrtf(dx*dx + dy*dy);
}


/*
    CMSpringyRopeLayer
 */
@interface CMSpringyRopeLayer ()

@property (assign, nonatomic) float rope_length;
@property (assign, nonatomic) NSUInteger subdivisions;

@property (assign, nonatomic) BOOL isDragging;
@property (assign, nonatomic) CGSize lastSize;

@property (assign, nonatomic) float gravityScale;
@property (strong, nonatomic) CMMotionManager *motionManager;

// Physics
@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) UIGravityBehavior *gravityBehavior;
@property (strong, nonatomic) UICollisionBehavior *collisionBehavior;
@property (strong, nonatomic) NSArray *particles;

@property (assign,nonatomic) CGFloat addGravite;

//support
@property (strong,nonatomic)NSArray *supports1;
@property (strong,nonatomic)NSArray *supports2;


@property (strong, nonatomic) UIAttachmentBehavior *anchorSpringBehavior;
@property (strong, nonatomic) CMSpringyRopeParticle *handleParticle;
@property (strong, nonatomic) UIAttachmentBehavior *handleSpringBehavior;
@property (strong, nonatomic) UIDynamicItemBehavior *particleBehavior;
//@property (strong, nonatomic) DynamicXray *dynamicXray;

// FPS
@property (assign, nonatomic) double fps_prev_time;
@property (assign, nonatomic) NSUInteger fps_count;
@property (assign,nonatomic) int eyesNumber;
@property (strong,nonatomic) UIColor* bodyColor;



@property(assign,nonatomic) CGFloat stress;

////Label
//@property(strong,nonatomic)UILabel *scoreLabel;
//@property(strong,nonatomic)UILabel *rankLabel;

@property(assign,nonatomic)CGFloat getPoint;



@property(assign,nonatomic)BOOL collsionIsON;

@end


@implementation CMSpringyRopeLayer

- (id)init
{
    self = [super init];
    _getPoint=0;


    if (self) {
	self.contentsScale = [UIScreen mainScreen].scale;
	
	_lastSize = self.bounds.size;
	
	_rope_length = CMSpringyRopeLength/600*[[UIScreen mainScreen]bounds].size.height;

        NSLog(@"%f",[[UIScreen mainScreen]bounds].size.height);
        
        
//        ////加label
//        CGPoint anchorPoint = CGPointMake(CGRectGetMinX(self.bounds)+10, CGRectGetMidY(self.bounds)+10);
//        
//        _rankLabel=[[UILabel alloc]initWithFrame:CGRectMake(anchorPoint.x, anchorPoint.y, 10, 40)];
//        _scoreLabel=[[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMidY(self.bounds), anchorPoint.y , 10, 40)];
//        
//        [_rankLabel setFont:[UIFont fontWithName:@"DB LCD Temp" size:10]];
//         [_scoreLabel setFont:[UIFont fontWithName:@"DB LCD Temp" size:10]];
//      _rankLabel.text=@"Rank:";
//        _scoreLabel.text=@"Score";


	_subdivisions = CMSpringyRopeSubdivisons;
	
	_motionManager = [[CMMotionManager alloc] init];
        _motionManager.deviceMotionUpdateInterval = 0.02; // 50 Hz
	
	_animator = [[UIDynamicAnimator alloc] init];
	_gravityBehavior = [[UIGravityBehavior alloc] initWithItems:nil];
	_gravityBehavior.gravityDirection = CGVectorMake(0.0, -0.5f);
	
	__weak CMSpringyRopeLayer *weakSelf = self;
	_gravityBehavior.action = ^{
	    __strong CMSpringyRopeLayer *strongSelf = weakSelf;
	    [strongSelf drawFrame];
	};
	[_animator addBehavior:_gravityBehavior];
	
	_particleBehavior = [[UIDynamicItemBehavior alloc] initWithItems:nil];
	_particleBehavior.density = CMSpringyRopeParticleDensity;
	_particleBehavior.resistance = CMSpringyRopeParticleResistance;
	
	[_animator addBehavior:_particleBehavior];

//        self.dynamicXray = [[DynamicXray alloc] init];
//        [self.animator addBehavior:self.dynamicXray];
    }
    return self;
    
}

- (void)layoutSublayers
{
    [super layoutSublayers];
    
    if (self.particles == nil) [self generateParticles];
}


#pragma mark - Set Up Physics

- (void)generateParticles
{
    NSMutableArray *particles = [NSMutableArray array];
    NSMutableArray *supports1=[NSMutableArray array];
    NSMutableArray *supports2=[NSMutableArray array];
    
    CGPoint anchorPoint = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetHeight(self.bounds));
    
    NSUInteger subdivisions = self.subdivisions;
    
    float sub_len = self.rope_length / subdivisions;
    for (NSUInteger i=1; i<=subdivisions; i++) {
	UIView *p = [[UIView alloc] initWithFrame:CGRectMake(anchorPoint.x, anchorPoint.y - i*sub_len, 10, 10)];
	[particles addObject:p];
        
        CMSpringyRopeParticle *support1=[[CMSpringyRopeParticle alloc]initWithCenterPosition:CGPointMake(anchorPoint.x, anchorPoint.y - (i-1)*sub_len)];
        [supports1 addObject:support1];
        
        CMSpringyRopeParticle *support2=[[CMSpringyRopeParticle alloc]initWithCenterPosition:CGPointMake(anchorPoint.x, anchorPoint.y - (i+1)*sub_len)];
        [supports2 addObject:support2];
	
	[self.particleBehavior addItem:p];
	[self.gravityBehavior addItem:p];
        
        
        
        [self.particleBehavior addItem:support1];
        [self.particleBehavior addItem:support2];
        
    }
    
    self.handleParticle = [particles objectAtIndex:1];
    NSUInteger particlesMaxIndex = [particles count] - 1;
    
    for (NSUInteger i=0; i<particlesMaxIndex; i++)  {
	if (i == 0) {
	    self.anchorSpringBehavior = [self addSpringBehaviorWithItem:particles[i] attachedToAnchor:anchorPoint];
	}
	
	UIAttachmentBehavior *springBehavior = [self addSpringBehaviorWithItem:particles[i] attachedToItem:particles[i+1]];
        
        UIAttachmentBehavior *support1SpringBehavior=[self addSuppotr1SpringBehaviorWithItem:supports1[i+1] attachedToItem:particles[i]];
        
        UIAttachmentBehavior *support2SpringBehavior=[self addSuppotr2SpringBehaviorWithItem: supports2[i]attachedToItem:particles[i+1]];
	
	if (i == 1) {
	    self.handleSpringBehavior = springBehavior;
	}
    }
    
//    UIView * leftconner=[[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMinY(self.bounds), 20, 20)];
//    
//     UIView * rightconner=[[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.bounds)-10, CGRectGetMinY(self.bounds), 10, CGRectGetMaxY(self.bounds))];
    
    self.particles = particles;
    self.supports1=supports1;
    self.supports2=supports2;
    
    
    [self addTheCollisonBehavior:particles];
    self.collsionIsON=YES;
    
    
    
    
//    NSMutableArray * collisonView=[NSMutableArray arrayWithArray:particles];
//    [collisonView addObject:leftconner];
//    [collisonView addObject:rightconner];
    
//    _collisionBehavior = [[UICollisionBehavior alloc] initWithItems:particles];
//    _collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
//    _collisionBehavior.collisionMode=UICollisionBehaviorModeEverything;
//    [_collisionBehavior addBoundaryWithIdentifier:@"line1" fromPoint:CGPointMake(CGRectGetMinX(self.bounds)+10, CGRectGetMinY(self.bounds)-400) toPoint:CGPointMake(CGRectGetMinX(self.bounds)+10,CGRectGetMaxY(self.bounds)+400)];
//    
//        [_collisionBehavior addBoundaryWithIdentifier:@"line2" fromPoint:CGPointMake(CGRectGetMaxX(self.bounds)-10, CGRectGetMinY(self.bounds)-400) toPoint:CGPointMake(CGRectGetMaxX(self.bounds)-10,CGRectGetMaxY(self.bounds)+400)];
//        [self.animator addBehavior:_collisionBehavior];
    
//    UICollisionBehavior *collisionBehavior2 = [[UICollisionBehavior alloc] initWithItems:@[leftconner,rightconner]];
//    collisionBehavior2.translatesReferenceBoundsIntoBoundary = YES;
//    collisionBehavior2.collisionMode=UICollisionBehaviorModeEverything;
//    
    
    

    //[self.animator addBehavior:collisionBehavior2];

    
    
    
    
}



-(void)addTheCollisonBehavior:(NSArray*)particles{
    _collisionBehavior = [[UICollisionBehavior alloc] initWithItems:particles];
    _collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    _collisionBehavior.collisionMode=UICollisionBehaviorModeEverything;
    [_collisionBehavior addBoundaryWithIdentifier:@"line1" fromPoint:CGPointMake(CGRectGetMinX(self.bounds)+10, CGRectGetMinY(self.bounds)-400) toPoint:CGPointMake(CGRectGetMinX(self.bounds)+10,CGRectGetMaxY(self.bounds)+400)];
    
    [_collisionBehavior addBoundaryWithIdentifier:@"line2" fromPoint:CGPointMake(CGRectGetMaxX(self.bounds)-10, CGRectGetMinY(self.bounds)-400) toPoint:CGPointMake(CGRectGetMaxX(self.bounds)-10,CGRectGetMaxY(self.bounds)+400)];
    [self.animator addBehavior:_collisionBehavior];
}

- (UIAttachmentBehavior *)addSpringBehaviorWithItem:(id<UIDynamicItem>)item attachedToAnchor:(CGPoint)anchorPoint
{
    UIAttachmentBehavior *springBehavior = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:anchorPoint];
    [self configureSpringBehavior:springBehavior];
    [self.animator addBehavior:springBehavior];
    return springBehavior;
}

- (UIAttachmentBehavior *)addSpringBehaviorWithItem:(id<UIDynamicItem>)itemA attachedToItem:(id<UIDynamicItem>)itemB
{
    UIAttachmentBehavior *springBehavior = [[UIAttachmentBehavior alloc] initWithItem:itemA attachedToItem:itemB];
    [self configureSpringBehavior:springBehavior];
    [self.animator addBehavior:springBehavior];
    return springBehavior;
}

- (UIAttachmentBehavior *)addSuppotr1SpringBehaviorWithItem:(id<UIDynamicItem>)itemA attachedToItem:(id<UIDynamicItem>)itemB
{
    UIAttachmentBehavior *springBehavior = [[UIAttachmentBehavior alloc] initWithItem:itemA attachedToItem:itemB];
    [self configureSupport1SpringBehavior:springBehavior];
    [self.animator addBehavior:springBehavior];
    return springBehavior;
}

- (UIAttachmentBehavior *)addSuppotr2SpringBehaviorWithItem:(id<UIDynamicItem>)itemA attachedToItem:(id<UIDynamicItem>)itemB
{
    UIAttachmentBehavior *springBehavior = [[UIAttachmentBehavior alloc] initWithItem:itemA attachedToItem:itemB];
    [self configureSupport2SpringBehavior:springBehavior];
    [self.animator addBehavior:springBehavior];
    return springBehavior;
}


- (void)configureSpringBehavior:(UIAttachmentBehavior *)springBehavior
{
    float sub_len = self.rope_length / self.subdivisions;
    springBehavior.length = sub_len;
    springBehavior.frequency = CMSpringyRopeFrequency;
    springBehavior.damping = CMSpringyRopeDamping;
}

- (void)configureSupport1SpringBehavior:(UIAttachmentBehavior *)springBehavior
{
   // float sub_len = self.rope_length / self.subdivisions;
    springBehavior.length = 0.0;
    springBehavior.frequency = CMSpringyRopeFrequency*7;
    springBehavior.damping = CMSpringyRopeDamping*2;
}

- (void)configureSupport2SpringBehavior:(UIAttachmentBehavior *)springBehavior
{
    //float sub_len = self.rope_length / self.subdivisions;
    springBehavior.length = 0.0;
    springBehavior.frequency = CMSpringyRopeFrequency*3;
    springBehavior.damping = CMSpringyRopeDamping*5;
}

#pragma mark - Custom property accessors

- (BOOL)isDeviceMotionAvailable
{
    return self.motionManager.isDeviceMotionAvailable;
}

- (void)setGravityByDeviceMotionEnabled:(BOOL)gravityByDeviceMotionEnabled
{
    if (gravityByDeviceMotionEnabled) {
        if ([self.motionManager isDeviceMotionAvailable]) {
            [self.motionManager startDeviceMotionUpdates];
        }
    }
    else {
        if ([self.motionManager isDeviceMotionActive]) {
            [self.motionManager stopDeviceMotionUpdates];
        }
    }
}

- (BOOL)isGravityByDeviceMotionEnabled
{
    return [self.motionManager isDeviceMotionActive];
}


#pragma mark - DynamicXray

//- (BOOL)isDynamicXrayEnabled
//{
//    return [self.dynamicXray isActive];
//}
//
//- (void)setDynamicXrayEnabled:(BOOL)dynamicXrayEnabled
//{
//    self.dynamicXray.active = dynamicXrayEnabled;
//}
//
//- (void)presentDynamicXrayConfigViewController
//{
//    [self.dynamicXray presentConfigurationViewController];
//}


#pragma mark - Handle touches

- (void)touchBeganAtLocation:(CGPoint)location
{
    //if (CGPointDistance(location, self.handleParticle.center) <= 40.0f) {
	[self moveHandleToLocation:location];
	self.isDragging = YES;
//    if (self.collsionIsON) {
//        [self addTheCollisonBehavior:self.particles];
//    }
    //}
}

- (void)touchMovedAtLocation:(CGPoint)location
{
    //if (self.isDragging) {
	[self moveHandleToLocation:location];
        NSUInteger particlesMaxIndex = [self.particles count];
        
        for (NSUInteger i=3; i<particlesMaxIndex; i++)
        {
            UIView *curPartice=self.particles[i];
            if (curPartice.center.x<CGRectGetMinX(self.bounds)+10||curPartice.center.x>CGRectGetMaxX(self.bounds)-10) {
                [self.animator removeBehavior:_collisionBehavior];
                self.collsionIsON=NO;
            }
            
        }
   // }
}

- (void)touchEndedAtLocation:(CGPoint)location
{
    if (self.isDragging) {
	[self moveHandleToLocation:location];
	//self.isDragging = NO;
        
        NSUInteger particlesMaxIndex = [self.particles count];
        
        for (NSUInteger i=3; i<particlesMaxIndex; i++)
        {
            CMSpringyRopeParticle *curPartice=self.particles[i];
            if (curPartice.center.x<CGRectGetMinX(self.bounds)+10||curPartice.center.x>CGRectGetMaxX(self.bounds)-10) {
                [self.animator removeBehavior:_collisionBehavior];
                self.collsionIsON=NO;
            }
            
        }
        
    }
}

- (void)touchCancelledAtLocation:(__unused CGPoint)location
{
    if (self.isDragging) {
	//self.isDragging = NO;
    }
}


#pragma mark - Dragging

- (void)setIsDragging:(BOOL)isDragging
{
    if (isDragging != _isDragging) {
	[self updateDynamicsWithHandleParticleDragging:isDragging];
	
	_isDragging = isDragging;
    }
}

- (void)updateDynamicsWithHandleParticleDragging:(BOOL)isDragging
{
   // [self.animator removeBehavior:self.handleSpringBehavior];
    
   // NSUInteger particlesMaxIndex = [self.particles count] - 1;
    
    UIAttachmentBehavior *springBehavior;
    
    if (isDragging) {
	// Create item<->anchor spring behavior
	
	springBehavior = [self addSpringBehaviorWithItem:self.particles[1]
				     attachedToAnchor:self.handleParticle.center];
	
	[self.gravityBehavior removeItem:self.handleParticle];
	[self.particleBehavior removeItem:self.handleParticle];
    }
    else {
	// Create item<->item spring behavior
	
	[self.animator updateItemUsingCurrentState:self.handleParticle];

	springBehavior = [self addSpringBehaviorWithItem:self.particles[1]
				       attachedToItem:self.handleParticle];
	
	[self.gravityBehavior addItem:self.handleParticle];
	[self.particleBehavior addItem:self.handleParticle];
    }
    
    self.handleSpringBehavior = springBehavior;
}


#pragma mark - Move Handle

- (void)moveHandleToLocation:(CGPoint)location
{
    CGFloat angle=atan2(location.y,location.x-CGRectGetMidX(self.bounds));
    
    location.x=CGRectGetMidX(self.bounds)+cos(angle)*_rope_length*1.5;
    location.y=CGRectGetHeight(self.bounds)-sin(angle)*_rope_length/5;
    
    
    self.addGravite=cos(angle)*0.5;
    
    self.handleParticle.center = location;
    self.handleSpringBehavior.anchorPoint = location;
    
    [self.animator updateItemUsingCurrentState:self.handleParticle];
}


#pragma mark - Draw Frame

- (void)drawFrame
{
    //if (self.motionManager.isDeviceMotionActive) {
        //CMAcceleration gravity = self.motionManager.deviceMotion.gravity;
        CGVector gravityVector = CGVectorMake((float)self.addGravite, (float)-0.5);
    if (self.stress>stressNumber) {
          gravityVector = CGVectorMake((float)self.addGravite, (float)-2.5);
    }else{
         gravityVector = CGVectorMake((float)self.addGravite, (float)-0.5);
    }
        gravityVector = [self vector:gravityVector rotatedToInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
        self.gravityBehavior.gravityDirection = gravityVector;
   // }

    [self setNeedsDisplay];      // draw layer
    
    /* FPS */
//    if (self.fpsLabel) {
//	double curr_time = CACurrentMediaTime();
//	if (curr_time - self.fps_prev_time >= 0.2) {
//	    double delta = (curr_time - self.fps_prev_time) / self.fps_count;
//	    self.fpsLabel.text = [NSString stringWithFormat:@"%0.0f fps", 1.0/delta];
//	    self.fps_prev_time = curr_time;
//	    self.fps_count = 1;
//	}
//	else {
//	    self.fps_count++;
//	}
//    }
    
    //set the supports points
    
    
    
    CGFloat targetStress=0;
    
    double bend=-0.15;
   
    NSUInteger particlesMaxIndex = [self.particles count];
    
    for (NSUInteger i=1; i<particlesMaxIndex; i++)  {
//        CMSpringyRopeParticle *particle=self.particles[i];
//        if (particle.center.x<CGRectGetMinX(self.bounds)) {
//            particle.center=CGPointMake(CGRectGetMinX(self.bounds)+50, particle.center.y) ;
//        }else if(particle.center.x>CGRectGetMaxX(self.bounds)){
//            particle.center=CGPointMake(CGRectGetMaxX(self.bounds)-50, particle.center.y) ;
//        }
//        
        CMSpringyRopeParticle *support2=self.supports2[i];
        CMSpringyRopeParticle *curPartice=self.particles[i];
        
        CMSpringyRopeParticle *prePartice=self.particles[i-1];
        
      double angle=atan2(curPartice.center.y-prePartice.center.y, curPartice.center.x-prePartice.center.x);
      
        CGFloat support2x=curPartice.center.x-cos(angle+i*bend)*CMSpringyRopeLength/9;
        CGFloat support2y=curPartice.center.y-sin(angle+i*bend)*CMSpringyRopeLength /9 ;
        support2.center=CGPointMake(support2x, support2y);
        
        
        CMSpringyRopeParticle *support1=self.supports1[i];
        
        
        CGFloat support1x=curPartice.center.x-cos(angle+3.14)*CMSpringyRopeLength/9;
        CGFloat support1y=curPartice.center.y-sin(angle+3.14)*CMSpringyRopeLength /9 ;
        support1.center=CGPointMake(support1x, support1y);
        
        
        CGFloat length=(curPartice.center.x-prePartice.center.x)*(curPartice.center.x-prePartice.center.x)/200;
        
        if (i>1) {
            targetStress+=length;
        }
        
        
    }
    self.stress+=(targetStress-self.stress*0.1)*0.1;
    
    
    
}


#pragma mark - CALayer methods

- (void)drawInContext:(CGContextRef)ctx
{
    if (!CGSizeEqualToSize(self.bounds.size, self.lastSize)) {
	self.gravityScale = 1.0f * CGRectGetHeight(self.frame) / 320.0f;
        self.lastSize = self.bounds.size;
    }
    
    

    CGMutablePathRef path = CGPathCreateMutable();
    


    CGPoint anchorPoint = self.anchorSpringBehavior.anchorPoint;
    CGPathMoveToPoint(path, NULL, anchorPoint.x, anchorPoint.y);
    for (NSUInteger i=0; i<[self.particles count]; i++) {
	CMSpringyRopeParticle *p = [self.particles objectAtIndex:i];
	CGPathAddLineToPoint(path, NULL, p.center.x, p.center.y);
    }
    
    

    UIGraphicsPushContext(ctx);
    
   
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithCGPath:path];
    bezierPath = smoothedPath(bezierPath, 8);
    bezierPath.lineWidth=110;

    bezierPath.lineCapStyle=kCGLineCapRound;
    bezierPath.lineJoinStyle = kCGLineJoinRound;
    
    
    
    [ self.bodyColor setStroke];
    
//    if (self.smoothed) {
//	
//        bezierPath.lineWidth=110;
//        bezierPath.lineJoinStyle = kCGLineJoinRound;
//        bezierPath.lineCapStyle=kCGLineCapRound;
//   
//        //[bezierPath fill];
//    }
    
    if (self.stress>stressNumber) {
        //NSLog(@"rilegoule");
      [[UIColor colorWithRed:1 green:0 blue:0.1 alpha:0.9]setStroke];
        _getPoint=_getPoint+0.01;
    }


    if (_getPoint>3) {
        CGFloat score=[[NSUserDefaults standardUserDefaults] integerForKey:@"Score"];
        score+=1;
      NSMutableString *message=[[NSMutableString alloc]init];
        [message appendFormat:@"Score:%d",(int)score];
        self.scoreLabel.text=message;
       [[NSUserDefaults standardUserDefaults]setInteger:score forKey:@"Score"];
        [self reportScore:score forCategory:@"slippers.staggeringBeauty_leaderboard"];
        _getPoint=0;
        NSLog(@"%f",score);
       
        [self randomTheBodyColor];
       
  
        
        //GKScore *localPlayerScore=[leaderboardRequest localPlayerScore];
        GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] init];
        leaderboardRequest.identifier = @"slippers.staggeringBeauty_leaderboard";
        [leaderboardRequest loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
            if (error) {
                NSLog(@"%@", error);
            } else if (scores) {
                GKScore *localPlayerScore = leaderboardRequest.localPlayerScore;
               // LOG(@"Local player's score: %lld", localPlayerScore.value);
                CGFloat rank=localPlayerScore.rank;
                        [[NSUserDefaults standardUserDefaults]setInteger:rank forKey:@"Rank"];
                        NSMutableString *messageRank=[[NSMutableString alloc]init];
                        [messageRank appendFormat:@"Rank:%d",(int)rank];
                        self.rankLabel.text=messageRank;
                        NSLog(@"排名%ld",(long)localPlayerScore.rank);
                CGFloat thescore=localPlayerScore.value;
                NSLog(@"分数%ld",(long)thescore);
                if (thescore>[[NSUserDefaults standardUserDefaults] integerForKey:@"Score"]) {
                       [[NSUserDefaults standardUserDefaults]setInteger:thescore forKey:@"Score"];
                }
                
              
            }
        }];
        
//        CGFloat rank=localPlayerScore.rank;
//        [[NSUserDefaults standardUserDefaults]setInteger:rank forKey:@"Rank"];
//        NSMutableString *messageRank=[[NSMutableString alloc]init];
//        [messageRank appendFormat:@"Rank:%d",(int)rank];
//        self.rankLabel.text=messageRank;
//        NSLog(@"分数%ld",(long)localPlayerScore.rank);
    }

    
    [bezierPath stroke];
  
    UIGraphicsPopContext();
    
    CGPathRelease(path);
    
    // Draw handle
    CGPoint handlePoint = self.handleParticle.center;
    CGContextAddEllipseInRect(ctx, CGRectMake(handlePoint.x-CMSpringyRopeHandleRadius, handlePoint.y-CMSpringyRopeHandleRadius, CMSpringyRopeHandleRadius*2, CMSpringyRopeHandleRadius*2));
    CGContextStrokePath(ctx);
    
    
    
//    CGFloat eyeToeyelength=30;
//    UIView *view1=self.particles[[self.particles count]-1];
//    UIView *view2=self.particles[[self.particles count]-2];
//    CGFloat angle=atan2(view2.center.y-view1.center.y, view2.center.x-view1.center.x)+90;
//    CGPoint eyeLeft=CGPointMake(view2.center.x+cos(angle)*eyeToeyelength/2+5, view2.center.y+sin(angle)*eyeToeyelength/6+5);
//    CGPoint eyeRight=CGPointMake(view2.center.x-cos(angle)*eyeToeyelength/2+5, view2.center.y-sin(angle)*eyeToeyelength/6+5);
//    
//    
//    CGContextAddRect(ctx, CGRectMake(eyeLeft.x, eyeLeft.y+5, 10, 2));
//    CGContextAddEllipseInRect(ctx, CGRectMake(eyeLeft.x, eyeLeft.y, 10, 10));
//    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
//   // CGContextRotateCTM(ctx,angle*M_PI/90);
//    
//    
//    CGContextAddRect(ctx, CGRectMake(eyeRight.x, eyeRight.y+5, 10, 2));
//    CGContextAddEllipseInRect(ctx, CGRectMake(eyeRight.x, eyeRight.y, 10, 10));
//    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
//    
//    CGContextRotateCTM(ctx,angle*M_PI/180);
//    
//    CGContextFillPath(ctx);
    [self addEyes:ctx];

}

//Random the color of the body
-(void)randomTheBodyColor{
    int randomNumber=arc4random()%9;
    UIColor *color=[[UIColor alloc]init];
    switch (randomNumber) {
        case 0:
       color= [UIColor colorWithRed:2/255.0 green:1/255.0 blue:240/255.0 alpha:0.9];
            break;
        case 1:
          color= [UIColor colorWithRed:2/255.0 green:250/255.0 blue:100/255.0 alpha:0.9];
            break;
        case 2:
            color=[UIColor colorWithRed:138/255.0 green:43/255.0 blue:226/255.0 alpha:0.9];
            break;
        case 3:
            color=[UIColor colorWithRed:127/255.0 green:245/255.0 blue:0/255.0 alpha:0.9];
            break;
        case 4:
            color=[UIColor colorWithRed:127/255.0 green:245/255.0 blue:0/255.0 alpha:0.9];
            break;
        case 5:
            color=[UIColor colorWithRed:255/255.0 green:127/255.0 blue:80/255.0 alpha:0.9];
            break;
        case 6:
            color=[UIColor colorWithRed:255/255.0 green:20/255.0 blue:127/255.0 alpha:0.9];
            break;
        case 7:
            color=[UIColor colorWithRed:233/255.0 green:150/255.0 blue:122/255.0 alpha:0.9];
            break;
        default:
            color=[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.9];
            break;
    }

    self.bodyColor=color;
    
}


#pragma mark - Vector Rotation

- (CGVector)vector:(CGVector)vector rotatedToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    CGVector result;

    if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        result.dx = -vector.dx;
        result.dy = -vector.dy;
    }
    else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        result.dx = -vector.dy;
        result.dy = vector.dx;
    }
    else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        result.dx = vector.dy;
        result.dy = -vector.dx;
    }
    else {
        result = vector;
    }

    return result;
}

#pragma mark - add eyes
-(void)addEyesBig:(CGContextRef)ctx{
    CGFloat eyeToeyelength=40;
    UIView *view1=self.particles[[self.particles count]-1];
    UIView *view2=self.particles[[self.particles count]-2];
    CGFloat angle=atan2(view2.center.y-view1.center.y, view2.center.x-view1.center.x)+90;
    CGPoint eyeLeft=CGPointMake(view2.center.x+cos(angle)*eyeToeyelength/2+5, view2.center.y+sin(angle)*eyeToeyelength/6-20);
    CGPoint eyeRight=CGPointMake(view2.center.x-cos(angle)*eyeToeyelength/2+5, view2.center.y-sin(angle)*eyeToeyelength/6-20);
    
    
   // CGContextAddRect(ctx, CGRectMake(eyeLeft.x, eyeLeft.y+5, 20, 2));
    CGContextAddEllipseInRect(ctx, CGRectMake(eyeLeft.x, eyeLeft.y, 15, 15));
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    // CGContextRotateCTM(ctx,angle*M_PI/90);
    
    
    //CGContextAddRect(ctx, CGRectMake(eyeRight.x, eyeRight.y+5, 20, 2));
    CGContextAddEllipseInRect(ctx, CGRectMake(eyeRight.x, eyeRight.y, 15, 15));
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    
    CGContextRotateCTM(ctx,angle*M_PI/180);
    
    CGContextFillPath(ctx);
    
}

-(void)addEyesSmall:(CGContextRef)ctx{
    CGFloat eyeToeyelength=40;
    UIView *view1=self.particles[[self.particles count]-1];
    UIView *view2=self.particles[[self.particles count]-2];
    CGFloat angle=atan2(view2.center.y-view1.center.y, view2.center.x-view1.center.x)+90;
    CGPoint eyeLeft=CGPointMake(view2.center.x+cos(angle)*eyeToeyelength/2+5, view2.center.y+sin(angle)*eyeToeyelength/6-20);
    CGPoint eyeRight=CGPointMake(view2.center.x-cos(angle)*eyeToeyelength/2+5, view2.center.y-sin(angle)*eyeToeyelength/6-20);
    
    
    CGContextAddRect(ctx, CGRectMake(eyeLeft.x, eyeLeft.y+5, 15, 2));
    //CGContextAddEllipseInRect(ctx, CGRectMake(eyeLeft.x, eyeLeft.y, 10, 10));
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    // CGContextRotateCTM(ctx,angle*M_PI/90);
    
    
    CGContextAddRect(ctx, CGRectMake(eyeRight.x, eyeRight.y+5, 15, 2));
    //CGContextAddEllipseInRect(ctx, CGRectMake(eyeRight.x, eyeRight.y, 10, 10));
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    
    CGContextRotateCTM(ctx,angle*M_PI/180);
    
    CGContextFillPath(ctx);
}


-(void)addEyesshape:(CGContextRef)ctx{
    CGFloat eyeToeyelength=40;
    UIView *view1=self.particles[[self.particles count]-1];
    UIView *view2=self.particles[[self.particles count]-2];
    CGFloat angle=atan2(view2.center.y-view1.center.y, view2.center.x-view1.center.x)+90;
    CGPoint eyeLeft=CGPointMake(view2.center.x+cos(angle)*eyeToeyelength/2+5, view2.center.y+sin(angle)*eyeToeyelength/6-20);
    CGPoint eyeRight=CGPointMake(view2.center.x-cos(angle)*eyeToeyelength/2+5, view2.center.y-sin(angle)*eyeToeyelength/6-20);
    
    
    CGContextAddRect(ctx, CGRectMake(eyeLeft.x, eyeLeft.y+5, 15, 2));
    CGContextAddRect(ctx, CGRectMake(eyeLeft.x+7.5, eyeLeft.y-2.5, 2, 15));
    //CGContextAddEllipseInRect(ctx, CGRectMake(eyeLeft.x, eyeLeft.y, 10, 10));
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    // CGContextRotateCTM(ctx,angle*M_PI/90);
    
    
    CGContextAddRect(ctx, CGRectMake(eyeRight.x, eyeRight.y+5, 15, 2));
    CGContextAddRect(ctx, CGRectMake(eyeRight.x+7.5, eyeRight.y-2.5, 2, 15));
    //CGContextAddEllipseInRect(ctx, CGRectMake(eyeRight.x, eyeRight.y, 10, 10));
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    
    CGContextRotateCTM(ctx,angle*M_PI/180);
    
    CGContextFillPath(ctx);
    
}

-(void)addEyes:(CGContextRef)ctx{
    if (self.stress>stressNumber) {
        [self addEyesshape:ctx];
    }else{
        self.eyesNumber+=1;
        int i=self.eyesNumber;
        if (i==509||i==510|| i==524||i==525||i==538||i==539||i==548||i==549) {
            [self addEyesSmall:ctx];
        }else if((i>510&&i<524)||(i>538&&i<548)){
            
        }
        else{
            [self addEyesBig:ctx];
            
        }
        
        if (self.eyesNumber>1000) {
            self.eyesNumber=0;
        }
    }
    
}


- (void) reportScore: (int64_t) score forCategory: (NSString*) category
{
    GKScore *scoreReporter = [[GKScore alloc] initWithLeaderboardIdentifier:category];
    scoreReporter.value = score;
    
    NSArray *scores=@[scoreReporter];
    [GKScore reportScores:scores withCompletionHandler:^(NSError *error){
        
    }];
}



// - (void) loadPlayerData
// {
//     
//      // GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
//     GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] init];
//     GKScore *localPlayerScore=[leaderboardRequest localPlayerScore];
//     
//
//}

@end
