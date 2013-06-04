//
//  JHActivityButton.m
//  JHActivityButtonExample
//
//  Created by justin howlett on 2013-05-31.
//  Copyright (c) 2013 JustinHowlett. All rights reserved.
//

#import "JHActivityButton.h"
#import <QuartzCore/QuartzCore.h>
#import "CAKeyframeAnimation+AHEasing.h"

@interface JHActivityButton (){
   
    CAShapeLayer*   _buttonBackgroundShapeLayer;
    
    UIColor*        _backgroundNormalColor;
    UIColor*        _backgroundHighlightedColor;
    UIColor*        _backgroundDisabledColor;
    UIColor*        _backgroundSelectedColor;
    
    BOOL            _isAnimating;
    
    NSDictionary*               _animationMethodTable;
}
@end

static CGFloat          kExpandFromCenterFactor = 0.27;
static CGFloat          kIndicatorWidth         = 36.0f;
static NSUInteger       kDefaultFrameCount      = 60;
static CGFloat          kExpandWidePadding      = 10.0f;

@implementation JHActivityButton


-(instancetype)initFrame:(CGRect)frame style:(JHActivityButtonStyle)style{
    
    if (self = [super initWithFrame:frame]){
        
        [self prepareAnimationDispatchTable];

        /** Defaults */
        _rectangleCornerRadius  = 0.1;
        _easingFunction         = BackEaseOut;
        _animationTime          = 0.3;
        
        _style                  = style;
        _indicator              = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
       
        /* center indicator vertically */
        /** indicator position and animation is controlled all at the CALayer level */
        [_indicator.layer setPosition:CGPointMake(0, (frame.size.height/2) - (kIndicatorWidth/2))];
        _indicator.userInteractionEnabled = NO;
        
        [self drawBackgroundRectangle];
    }
    
    return self;
}


-(void)setRectangleCornerRadius:(CGFloat)rectangleCornerRadius{
    
    _rectangleCornerRadius = rectangleCornerRadius;
    
    /** force a minimum of 0.1 as less than that causes animation bugs */
    if (_rectangleCornerRadius < 0.1)
        _rectangleCornerRadius = 0.1;
    
    _buttonBackgroundShapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:_rectangleCornerRadius].CGPath;
    
}

-(void)setBackgroundColor:(UIColor *)color forState:(UIControlState)state{
    
    switch (state) {
        case UIControlStateNormal:
            _backgroundNormalColor      = color;
            break;
        case UIControlStateHighlighted:
            _backgroundHighlightedColor = color;
            break;
        case UIControlStateDisabled:
            _backgroundDisabledColor    = color;
            break;
        case UIControlStateSelected:
            _backgroundSelectedColor    = color;
            break;
        case UIControlStateApplication:
            //nothing yet
            break;
        case UIControlStateReserved:
            //nothing yet
            break;
    }
}

-(void)animateToActivityIndicatorState:(BOOL)shouldAnimateToActivityState{
    /** manually trigger normal/activity state */
    
    if (_isAnimating) return;
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:_animationTime];
    [CATransaction setCompletionBlock:^{
        _isAnimating = NO;
    }];
    
    _isAnimating = YES;
    
    /** query method dispatch table for correct method for current style and state */
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:[self animationSelectorForCurrentStyle:shouldAnimateToActivityState]];
    #pragma clang diagnostic pop
    
    [CATransaction commit];
}

-(void)drawBackgroundRectangle{
    
    _buttonBackgroundShapeLayer             = [CAShapeLayer layer];
    _buttonBackgroundShapeLayer.path        = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:_rectangleCornerRadius].CGPath;
    _buttonBackgroundShapeLayer.fillColor   = [UIColor redColor].CGColor;
    _buttonBackgroundShapeLayer.anchorPoint = CGPointMake(0.5f, 0.5f);
    
    [self.layer addSublayer:_buttonBackgroundShapeLayer];
}

-(void)animateBackToDefaultState{
    
    /** TODO: animate removal based on style */
    [_indicator stopAnimating];
    [_indicator removeFromSuperview];
}


#pragma mark -
#pragma mark - UIButton State Change Handling

/** KVO on self.state not possible as it's "synthesized from other flags." using existing UIButton Methods instead */

-(void)setHighlighted:(BOOL)highlighted{
    [super setHighlighted:highlighted];
    
    [self buttonStateChanged];
}

-(void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    
   
    [self buttonStateChanged];
}

-(void)setEnabled:(BOOL)enabled{
    [super setEnabled:enabled];
    
    [self buttonStateChanged];
}


-(void)buttonStateChanged{
    
    if (_shouldSuppressStateChangeOnTap)
        return;
    
    [self animateToActivityIndicatorState:self.state != UIControlStateNormal];
    
    switch (self.state) {
        case UIControlStateNormal:
            _buttonBackgroundShapeLayer.fillColor = _backgroundNormalColor.CGColor;
            break;
        case UIControlStateHighlighted:
            if(_backgroundHighlightedColor)_buttonBackgroundShapeLayer.fillColor    = _backgroundHighlightedColor.CGColor;
            break;
        case UIControlStateDisabled:
            if(_backgroundDisabledColor)_buttonBackgroundShapeLayer.fillColor       =  _backgroundDisabledColor.CGColor;
            break;
        case UIControlStateSelected:
            if(_backgroundSelectedColor)_buttonBackgroundShapeLayer.fillColor       = _backgroundSelectedColor.CGColor;
            break;
        case UIControlStateApplication:
            //nothing yet
            break;
        case UIControlStateReserved:
            //nothing yet
            break;
    }
    
}

#pragma mark - 
#pragma mark Style Specific Animation Methods


-(void)animateView:(UIView*)view fromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint{
    
    
    CAAnimation *indicatorAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"
                                                                       function:_easingFunction
                                                                      fromPoint:fromPoint
                                                                        toPoint:toPoint];
    
    indicatorAnimation.duration = _animationTime;
    
    [view.layer addAnimation:indicatorAnimation forKey:@"position"];
    view.layer.position = toPoint;
}



#pragma mark Expand wide center

-(void)animateBackgroundExpandLeft{
    
    /** animate label */
    
    UIImageView *rasterLabel = [self rasterTitleLabel];
    [self addSubview:rasterLabel];
    self.titleLabel.alpha = 0;
    
    CGRect newBounds       = self.bounds;
    newBounds.size.width   += ((self.bounds.size.width * kExpandFromCenterFactor)*2);
    
    CGFloat offsetDelta = (newBounds.size.width - self.bounds.size.width)/2;
    CGPoint existingLayerPoint  = rasterLabel.layer.position;
    CGPoint xOffsetPoint        = existingLayerPoint;
    xOffsetPoint.x              += offsetDelta;
    
    [self animateView:rasterLabel fromPoint:existingLayerPoint toPoint:xOffsetPoint];
    
    /** animate activity indicator */
    
    [_indicator.layer setPosition:CGPointMake([self indicatorHorizontalCenter], [self indicatorVerticalCenter])];
    
    [self addSubview:_indicator];
    [_indicator startAnimating];
    
    CGFloat zeroPosition = -xOffsetPoint.x + _indicator.bounds.size.width/2;
    zeroPosition += kExpandWidePadding;
    
    CAAnimation *indicatorAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"
                                                                       function:_easingFunction
                                                                      fromValue:0.0 toValue:zeroPosition];
    
    indicatorAnimation.fillMode = kCAFillModeForwards;
    indicatorAnimation.removedOnCompletion = NO;
    indicatorAnimation.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorAnimation forKey:@"transform.scale"];
    
    
    
    CAAnimation *indicatorOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                     function:_easingFunction
                                                                    fromValue:0.0 toValue:1.0];
    
    indicatorOpacity.fillMode = kCAFillModeForwards;
    indicatorOpacity.removedOnCompletion = NO;
    indicatorOpacity.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorOpacity forKey:@"opacity"];
    

    /** animate background */
    [self expandBackgroundWidthFromCenter];
}

-(void)animateBackgroundExpandRight{
    
    /** animate label */
    
    UIImageView *rasterLabel = [self rasterTitleLabel];
    [self addSubview:rasterLabel];
    self.titleLabel.alpha = 0;
    
    CGRect newBounds       = self.bounds;
    newBounds.size.width   += ((self.bounds.size.width * kExpandFromCenterFactor)*2);
    
    CGFloat offsetDelta = (newBounds.size.width - self.bounds.size.width)/2;
    CGPoint existingLayerPoint  = rasterLabel.layer.position;
    CGPoint xOffsetPoint        = existingLayerPoint;
    xOffsetPoint.x              -= offsetDelta;
    
    [self animateView:rasterLabel fromPoint:existingLayerPoint toPoint:xOffsetPoint];
    
    /** animate activity indicator */
        
    [_indicator.layer setPosition:CGPointMake([self indicatorHorizontalCenter], [self indicatorVerticalCenter])];
    
    [self addSubview:_indicator];
    [_indicator startAnimating];
    
    CAAnimation *indicatorAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"
                                                                       function:_easingFunction
                                                                      fromValue:0.0 toValue:(newBounds.size.width/2 - _indicator.bounds.size.width/2)-kExpandWidePadding];
    
    indicatorAnimation.fillMode = kCAFillModeForwards;
    indicatorAnimation.removedOnCompletion = NO;
    indicatorAnimation.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorAnimation forKey:@"transform.scale"];
    
    
    
    CAAnimation *indicatorOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                     function:_easingFunction
                                                                    fromValue:0.0 toValue:1.0];
    
    indicatorOpacity.fillMode = kCAFillModeForwards;
    indicatorOpacity.removedOnCompletion = NO;
    indicatorOpacity.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorOpacity forKey:@"opacity"];
    
    /** animate background */
    [self expandBackgroundWidthFromCenter];
}

-(void)expandBackgroundWidthFromCenter{
        
    CGRect newBounds       = self.bounds;
    newBounds.origin.x     -= (self.bounds.size.width * kExpandFromCenterFactor);
    newBounds.size.width   += ((self.bounds.size.width * kExpandFromCenterFactor)*2);
        
    CAKeyframeAnimation* expandFromCenterAnimation = [self expandFromCenterAnimationWithNewRect:newBounds];
    [_buttonBackgroundShapeLayer addAnimation:expandFromCenterAnimation forKey:@"path"];
    [_buttonBackgroundShapeLayer setPath:[UIBezierPath bezierPathWithRoundedRect:newBounds cornerRadius:_rectangleCornerRadius].CGPath];
}

-(CAKeyframeAnimation*)expandFromCenterAnimationWithNewRect:(CGRect)newRect{
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"path"];

    NSMutableArray *values = [NSMutableArray arrayWithCapacity:kDefaultFrameCount];
	
	CGFloat t = 0.0;
	CGFloat dt = 1.0 / (kDefaultFrameCount - 1);
	for(size_t frame = 0; frame < kDefaultFrameCount; ++frame, t += dt){
		
        CGFloat value = self.bounds.size.width + _easingFunction(t) * (newRect.size.width - self.bounds.size.width);
        
        CGFloat delta = value - self.bounds.size.width;
        
        CGRect adjustedFrame    = CGRectMake(self.bounds.origin.x - (delta/2), self.bounds.origin.y, value, self.bounds.size.height);
        CGPathRef adjustedPath  = [UIBezierPath bezierPathWithRoundedRect:adjustedFrame cornerRadius:_rectangleCornerRadius].CGPath;
        
		[values addObject:(__bridge id)(adjustedPath)];
	}
	
	[animation setValues:values];
    
    return animation;
}

#pragma mark Expand Down

-(void)expandBackgroundHeightTop{
    
    [self expandBackgroundHeightDownward];
    
    /** animate activity indicator */
    
    [_indicator.layer setPosition:CGPointMake([self indicatorHorizontalCenter], [self indicatorVerticalCenter])];
    
    [self addSubview:_indicator];
    [_indicator startAnimating];
    
    CAAnimation *indicatorAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"
                                                                       function:_easingFunction
                                                                      fromValue:0 toValue:[self indicatorVerticalCenter]+(_indicator.frame.size.height/2)];
    
    indicatorAnimation.fillMode = kCAFillModeForwards;
    indicatorAnimation.removedOnCompletion = NO;
    indicatorAnimation.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorAnimation forKey:@"transform.translation.y"];
    
    
    
    CAAnimation *indicatorOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                     function:_easingFunction
                                                                    fromValue:0.0 toValue:1.0];
    
    indicatorOpacity.fillMode = kCAFillModeForwards;
    indicatorOpacity.removedOnCompletion = NO;
    indicatorOpacity.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorOpacity forKey:@"opacity"];
}

-(void)expandBackgroundHeightBottom{
    /** animate label */
    
    UIImageView *rasterLabel = [self rasterTitleLabel];
    [self addSubview:rasterLabel];
    self.titleLabel.alpha = 0;
    
    CGRect newBounds       = self.bounds;
    newBounds.size.height  *= 2;
    
    CGFloat offsetDelta = (newBounds.size.height - self.bounds.size.height);
    CGPoint existingLayerPoint  = rasterLabel.layer.position;
    CGPoint xOffsetPoint        = existingLayerPoint;
    xOffsetPoint.y              += offsetDelta;
    
    [self animateView:rasterLabel fromPoint:existingLayerPoint toPoint:xOffsetPoint];
    
    /** animate activity indicator */
    
    [_indicator.layer setPosition:CGPointMake([self indicatorHorizontalCenter], [self indicatorVerticalCenter])];
    
    [self addSubview:_indicator];
    [_indicator startAnimating];
    
    CAAnimation *indicatorAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"
                                                                       function:_easingFunction
                                                                      fromValue:-_indicator.frame.size.height toValue:0];
    
    indicatorAnimation.fillMode = kCAFillModeForwards;
    indicatorAnimation.removedOnCompletion = NO;
    indicatorAnimation.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorAnimation forKey:@"transform.translation.y"];
    
    
    
    CAAnimation *indicatorOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                     function:_easingFunction
                                                                    fromValue:0.0 toValue:1.0];
    
    indicatorOpacity.fillMode = kCAFillModeForwards;
    indicatorOpacity.removedOnCompletion = NO;
    indicatorOpacity.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorOpacity forKey:@"opacity"];


    
    [self expandBackgroundHeightDownward];
}

-(void)expandBackgroundHeightDownward{
    
    CGRect newBounds       = self.bounds;
    newBounds.size.height  *= 2;
    
    CAKeyframeAnimation* expandFromTopAnimation = [self expandDownToRect:newBounds];
    [_buttonBackgroundShapeLayer addAnimation:expandFromTopAnimation forKey:@"path"];
    [_buttonBackgroundShapeLayer setPath:[UIBezierPath bezierPathWithRoundedRect:newBounds cornerRadius:_rectangleCornerRadius].CGPath];
    
}

-(CAKeyframeAnimation*)expandDownToRect:(CGRect)newRect{
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"path"];
    
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:kDefaultFrameCount];
	
	CGFloat t = 0.0;
	CGFloat dt = 1.0 / (kDefaultFrameCount - 1);
	for(size_t frame = 0; frame < kDefaultFrameCount; ++frame, t += dt){
		
        CGFloat value = self.bounds.size.height + _easingFunction(t) * (newRect.size.height - self.bounds.size.height);
    
        CGRect adjustedFrame    = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, value);
        CGPathRef adjustedPath  = [UIBezierPath bezierPathWithRoundedRect:adjustedFrame cornerRadius:_rectangleCornerRadius].CGPath;
        
		[values addObject:(__bridge id)(adjustedPath)];
	}
	
	[animation setValues:values];
    
    return animation;
}

#pragma mark Contract to circle

-(void)animateBackgroundToCircle{
    
    self.titleLabel.alpha = 0;

    CGFloat endRadius                   = MIN(self.bounds.size.height, self.bounds.size.width);
    CGRect circlePathRect               = CGRectMake((self.bounds.size.width/2) - (endRadius/2), (self.bounds.size.height/2) - (endRadius/2), endRadius, endRadius);
    CGPathRef rectanglePath             = [UIBezierPath bezierPathWithRoundedRect:circlePathRect cornerRadius:endRadius].CGPath;
    CAKeyframeAnimation* shapeAnimation = [self circleShapeAnimationForPathUpdateToRadius:endRadius];
    
    _indicator.alpha = 0;
    [UIView animateWithDuration:_animationTime animations:^{
        _indicator.alpha = 1;
    }];
    
    [self addSubview:_indicator];
    [_indicator startAnimating];
    
    [_buttonBackgroundShapeLayer addAnimation:shapeAnimation forKey:@"path"];
    [_buttonBackgroundShapeLayer setPath:rectanglePath];
    
    
    [_indicator setFrame:circlePathRect];
}

-(CAKeyframeAnimation*)circleShapeAnimationForPathUpdateToRadius:(CGFloat)endRadius{
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"path"];
    
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:kDefaultFrameCount];
	
	CGFloat t = 0.0;
	CGFloat dt = 1.0 / (kDefaultFrameCount - 1);
	for(size_t frame = 0; frame < kDefaultFrameCount; ++frame, t += dt){
        
        CGFloat startRadius = _rectangleCornerRadius;
        
        CGFloat radius = startRadius + _easingFunction(t) * (endRadius - startRadius);
    
        CGFloat adjustedWidth = self.bounds.size.width + _easingFunction(t) * (endRadius - self.bounds.size.width);
        CGFloat widthDelta = adjustedWidth - self.bounds.size.width;
        
        CGFloat adjustedHeight = self.bounds.size.height + _easingFunction(t) * (endRadius - self.bounds.size.height);
        CGFloat heightDelta = adjustedHeight - self.bounds.size.height;
        
        
        CGRect circlePathRect               = CGRectMake(self.bounds.origin.x - (widthDelta/2), self.bounds.origin.y - (heightDelta/2), adjustedWidth, adjustedHeight);
        CGPathRef circlePath                = [UIBezierPath bezierPathWithRoundedRect:circlePathRect cornerRadius:radius].CGPath;
		        
        
		[values addObject:(__bridge id)(circlePath)];
	}
	
	[animation setValues:values];
    
    return animation;
}

#pragma mark zoom

-(void)zoomOutTitleAndIndicator{
    
    [_indicator.layer setPosition:CGPointMake([self indicatorHorizontalCenter], [self indicatorVerticalCenter])];
    
    [self addSubview:_indicator];
    [_indicator startAnimating];
    
    UIImageView *rasterLabel = [self rasterTitleLabel];
    self.titleLabel.alpha = 0;
    [self addSubview:rasterLabel];
    
    
    CAAnimation *titleSizeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"
                                                                       function:_easingFunction
                                                                      fromValue:1.0 toValue:0.8];
    
    titleSizeAnimation.fillMode = kCAFillModeForwards;
    titleSizeAnimation.removedOnCompletion = NO;
    titleSizeAnimation.duration = _animationTime;
    
    [rasterLabel.layer addAnimation:titleSizeAnimation forKey:@"transform.scale"];
    
    
    CAAnimation *indicatorAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"
                                                                       function:_easingFunction
                                                                      fromValue:2.0 toValue:1.0];
    
    indicatorAnimation.fillMode = kCAFillModeForwards;
    indicatorAnimation.removedOnCompletion = NO;
    indicatorAnimation.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorAnimation forKey:@"transform.scale"];
    
    
    
    CAAnimation *indicatorOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                       function:_easingFunction
                                                                      fromValue:0.0 toValue:1.0];
    
    indicatorOpacity.fillMode = kCAFillModeForwards;
    indicatorOpacity.removedOnCompletion = NO;
    indicatorOpacity.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorOpacity forKey:@"opacity"];
    
    
    CAAnimation *titleOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                     function:_easingFunction
                                                                    fromValue:1.0 toValue:0.0];
    
    titleOpacity.fillMode = kCAFillModeForwards;
    titleOpacity.removedOnCompletion = NO;
    titleOpacity.duration = _animationTime;
    
    [rasterLabel.layer addAnimation:titleOpacity forKey:@"opacity"];
    
    
}

-(void)zoomInTitleAndIndicator{
    
    [_indicator.layer setPosition:CGPointMake([self indicatorHorizontalCenter], [self indicatorVerticalCenter])];

    [self addSubview:_indicator];
    [_indicator startAnimating];
    
    
    UIImageView *rasterLabel = [self rasterTitleLabel];
    self.titleLabel.alpha = 0;
    [self addSubview:rasterLabel];
    
    
    CAAnimation *titleSizeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"
                                                                       function:_easingFunction
                                                                      fromValue:1.0 toValue:2.0];
    
    titleSizeAnimation.fillMode = kCAFillModeForwards;
    titleSizeAnimation.removedOnCompletion = NO;
    titleSizeAnimation.duration = _animationTime;
    
    [rasterLabel.layer addAnimation:titleSizeAnimation forKey:@"transform.scale"];
    
    
    CAAnimation *indicatorAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"
                                                                       function:_easingFunction
                                                                      fromValue:0.3 toValue:1.0];
    
    indicatorAnimation.fillMode = kCAFillModeForwards;
    indicatorAnimation.removedOnCompletion = NO;
    indicatorAnimation.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorAnimation forKey:@"transform.scale"];
    
    
    
    CAAnimation *indicatorOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                     function:_easingFunction
                                                                    fromValue:0.0 toValue:1.0];
    
    indicatorOpacity.fillMode = kCAFillModeForwards;
    indicatorOpacity.removedOnCompletion = NO;
    indicatorOpacity.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorOpacity forKey:@"opacity"];
    
    
    CAAnimation *titleOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                 function:_easingFunction
                                                                fromValue:1.0 toValue:0.0];
    
    titleOpacity.fillMode = kCAFillModeForwards;
    titleOpacity.removedOnCompletion = NO;
    titleOpacity.duration = _animationTime;
    
    [rasterLabel.layer addAnimation:titleOpacity forKey:@"opacity"];
    
}

-(void)slideLeft{
    
    self.clipsToBounds = YES;
    
    [_indicator.layer setPosition:CGPointMake([self indicatorHorizontalCenter], [self indicatorVerticalCenter])];
    
    [self addSubview:_indicator];
    [_indicator startAnimating];
    
    
    UIImageView *rasterLabel = [self rasterTitleLabel];
    self.titleLabel.alpha = 0;
    [self addSubview:rasterLabel];
    
    
    CAAnimation *titleSlide = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"
                                                                 function:_easingFunction
                                                                fromValue:0.0 toValue:-(rasterLabel.frame.origin.x + rasterLabel.frame.size.width)];
    
    titleSlide.fillMode = kCAFillModeForwards;
    titleSlide.removedOnCompletion = NO;
    titleSlide.duration = _animationTime;
    
    [rasterLabel.layer addAnimation:titleSlide forKey:@"transform.translation.x"];
    
    CAAnimation *indicatorSlide = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"
                                                               function:_easingFunction
                                                              fromValue:self.bounds.size.width toValue:0];
    
    indicatorSlide.fillMode = kCAFillModeForwards;
    indicatorSlide.removedOnCompletion = NO;
    indicatorSlide.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorSlide forKey:@"transform.translation.x"];
    
    
    CAAnimation *indicatorOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                     function:_easingFunction
                                                                    fromValue:0.0 toValue:1.0];
    
    indicatorOpacity.fillMode = kCAFillModeForwards;
    indicatorOpacity.removedOnCompletion = NO;
    indicatorOpacity.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorOpacity forKey:@"opacity"];
    
    
    CAAnimation *titleOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                 function:_easingFunction
                                                                fromValue:1.0 toValue:0.0];
    
    titleOpacity.fillMode = kCAFillModeForwards;
    titleOpacity.removedOnCompletion = NO;
    titleOpacity.duration = _animationTime;
    
    [rasterLabel.layer addAnimation:titleOpacity forKey:@"opacity"];
//
    
}


-(void)slideRight{
    
    self.clipsToBounds = YES;
    
    [_indicator.layer setPosition:CGPointMake([self indicatorHorizontalCenter], [self indicatorVerticalCenter])];
    
    [self addSubview:_indicator];
    [_indicator startAnimating];
    
    
    UIImageView *rasterLabel = [self rasterTitleLabel];
    self.titleLabel.alpha = 0;
    [self addSubview:rasterLabel];
    
    
    CAAnimation *titleSlide = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"
                                                               function:_easingFunction
                                                              fromValue:self.bounds.size.width toValue:0];
    
    titleSlide.fillMode = kCAFillModeForwards;
    titleSlide.removedOnCompletion = NO;
    titleSlide.duration = _animationTime;
    
    [rasterLabel.layer addAnimation:titleSlide forKey:@"transform.translation.x"];
    
    CAAnimation *indicatorSlide = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"
                                                                   function:_easingFunction
                                                                  fromValue:-(rasterLabel.frame.origin.x + rasterLabel.frame.size.width) toValue:0];
    
    indicatorSlide.fillMode = kCAFillModeForwards;
    indicatorSlide.removedOnCompletion = NO;
    indicatorSlide.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorSlide forKey:@"transform.translation.x"];
    
    
    CAAnimation *indicatorOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                     function:_easingFunction
                                                                    fromValue:0.0 toValue:1.0];
    
    indicatorOpacity.fillMode = kCAFillModeForwards;
    indicatorOpacity.removedOnCompletion = NO;
    indicatorOpacity.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorOpacity forKey:@"opacity"];
    
    
    CAAnimation *titleOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                 function:_easingFunction
                                                                fromValue:1.0 toValue:0.0];
    
    titleOpacity.fillMode = kCAFillModeForwards;
    titleOpacity.removedOnCompletion = NO;
    titleOpacity.duration = _animationTime;
    
    [rasterLabel.layer addAnimation:titleOpacity forKey:@"opacity"];
    
}

-(void)slideUp{
    
    self.clipsToBounds = YES;
    
    [_indicator.layer setPosition:CGPointMake([self indicatorHorizontalCenter], [self indicatorVerticalCenter])];
    
    [self addSubview:_indicator];
    [_indicator startAnimating];
    
    
    UIImageView *rasterLabel = [self rasterTitleLabel];
    self.titleLabel.alpha = 0;
    [self addSubview:rasterLabel];
    
    
    CAAnimation *titleSlide = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"
                                                               function:_easingFunction
                                                              fromValue:0 toValue:-(rasterLabel.frame.origin.y + rasterLabel.frame.size.height)];
    
    titleSlide.fillMode = kCAFillModeForwards;
    titleSlide.removedOnCompletion = NO;
    titleSlide.duration = _animationTime;
    
    [rasterLabel.layer addAnimation:titleSlide forKey:@"transform.translation.y"];
    
    CAAnimation *indicatorSlide = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"
                                                                   function:_easingFunction
                                                                  fromValue:self.bounds.size.height toValue:0];
    
    indicatorSlide.fillMode = kCAFillModeForwards;
    indicatorSlide.removedOnCompletion = NO;
    indicatorSlide.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorSlide forKey:@"transform.translation.x"];

    
    CAAnimation *indicatorOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                     function:_easingFunction
                                                                    fromValue:0.0 toValue:1.0];
    
    indicatorOpacity.fillMode = kCAFillModeForwards;
    indicatorOpacity.removedOnCompletion = NO;
    indicatorOpacity.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorOpacity forKey:@"opacity"];
    
    
    CAAnimation *titleOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                 function:_easingFunction
                                                                fromValue:1.0 toValue:0.0];
    
    titleOpacity.fillMode = kCAFillModeForwards;
    titleOpacity.removedOnCompletion = NO;
    titleOpacity.duration = _animationTime;
    
    [rasterLabel.layer addAnimation:titleOpacity forKey:@"opacity"];
    
}


-(void)slideDown{
    
    self.clipsToBounds = YES;
    
    [_indicator.layer setPosition:CGPointMake([self indicatorHorizontalCenter], [self indicatorVerticalCenter])];
    
    [self addSubview:_indicator];
    [_indicator startAnimating];
    
    
    UIImageView *rasterLabel = [self rasterTitleLabel];
    self.titleLabel.alpha = 0;
    [self addSubview:rasterLabel];
    
    
    CAAnimation *titleSlide = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"
                                                               function:_easingFunction
                                                              fromValue:0 toValue:self.bounds.size.height];
    
    titleSlide.fillMode = kCAFillModeForwards;
    titleSlide.removedOnCompletion = NO;
    titleSlide.duration = _animationTime;
    
    [rasterLabel.layer addAnimation:titleSlide forKey:@"transform.translation.y"];
    
    CAAnimation *indicatorSlide = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"
                                                                   function:_easingFunction
                                                                  fromValue:-(_indicator.frame.origin.y + _indicator.frame.size.height) toValue:0];
    
    indicatorSlide.fillMode = kCAFillModeForwards;
    indicatorSlide.removedOnCompletion = NO;
    indicatorSlide.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorSlide forKey:@"transform.translation.x"];
    
    
    CAAnimation *indicatorOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                     function:_easingFunction
                                                                    fromValue:0.0 toValue:1.0];
    
    indicatorOpacity.fillMode = kCAFillModeForwards;
    indicatorOpacity.removedOnCompletion = NO;
    indicatorOpacity.duration = _animationTime;
    
    [_indicator.layer addAnimation:indicatorOpacity forKey:@"opacity"];
    
    
    CAAnimation *titleOpacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"
                                                                 function:_easingFunction
                                                                fromValue:1.0 toValue:0.0];
    
    titleOpacity.fillMode = kCAFillModeForwards;
    titleOpacity.removedOnCompletion = NO;
    titleOpacity.duration = _animationTime;
    
    [rasterLabel.layer addAnimation:titleOpacity forKey:@"opacity"];
}

#pragma mark -
#pragma mark Animation Method Dispatch Table 

-(void)prepareAnimationDispatchTable{
    
    /* This is presented as a Dictionary for easy readability */ 
    
    NSMutableDictionary* mutableAnimationMethodTable = [[NSMutableDictionary alloc]init];
    
    mutableAnimationMethodTable[@(JHActivityButtonStyleExpandLeft)]       = @"animateBackgroundExpandLeft";
    mutableAnimationMethodTable[@(JHActivityButtonStyleExpandRight)]      = @"animateBackgroundExpandRight";
    mutableAnimationMethodTable[@(JHActivityButtonStyleExpandUp)]         = @"expandBackgroundHeightBottom";
    mutableAnimationMethodTable[@(JHActivityButtonStyleExpandDown)]       = @"expandBackgroundHeightTop";
    mutableAnimationMethodTable[@(JHActivityButtonStyleZoomIn)]           = @"zoomInTitleAndIndicator";
    mutableAnimationMethodTable[@(JHActivityButtonStyleZoomOut)]          = @"zoomOutTitleAndIndicator";
    mutableAnimationMethodTable[@(JHActivityButtonStyleSlideLeft)]        = @"slideLeft";
    mutableAnimationMethodTable[@(JHActivityButtonStyleSlideRight)]       = @"slideRight";
    mutableAnimationMethodTable[@(JHActivityButtonStyleSlideUp)]          = @"slideUp";
    mutableAnimationMethodTable[@(JHActivityButtonStyleSlideDown)]        = @"slideDown";
    mutableAnimationMethodTable[@(JHActivityButtonStyleContractCircle)]   = @"animateBackgroundToCircle";
    
    _animationMethodTable = [NSDictionary dictionaryWithDictionary:mutableAnimationMethodTable];
}


-(SEL)animationSelectorForCurrentStyle:(BOOL)shouldAnimateToActivityState{
    
    NSString* methodNameString      = _animationMethodTable[@(_style)];
    
    return NSSelectorFromString(methodNameString);;
}

#pragma mark - 
#pragma mark - Utility methods

-(CGFloat)indicatorVerticalCenter{
    /** return using CALayer rules not UIView rules */
    return (self.bounds.size.height/2);
}

-(CGFloat)indicatorHorizontalCenter{
    /** return using CALayer rules not UIView rules */
    return (self.bounds.size.width/2);
}

-(UIImageView*)rasterTitleLabel{
    
    UIImageView *titleRasterCopy = [[UIImageView alloc]initWithImage:[self.titleLabel getRasterCopy]];
    [titleRasterCopy setFrame:self.titleLabel.frame];
    //    titleRasterCopy.backgroundColor = [UIColor orangeColor];
    
    return titleRasterCopy;
}

@end
                                    
@implementation UIView (Raster)

-(UIImage*)getRasterCopy{
    
    /* returns UIImage of any UIView */
    
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0.0);
    
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultingImage;
}


@end
