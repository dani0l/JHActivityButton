//
//  JHViewController.m
//  JHActivityButtonExample
//
//  Created by justin howlett on 2013-05-31.
//  Copyright (c) 2013 JustinHowlett. All rights reserved.
//

#import "JHViewController.h"
#import "JHActivityButton.h"

@interface JHViewController (){
    UIScrollView *_masterScrollView;
}

@end

@implementation JHViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _masterScrollView = [[UIScrollView alloc]init];
    [self.view addSubview:_masterScrollView];
    
    CGFloat yLoc = 100;
    
    for (int i=0; i<11; i++){
        
        JHActivityButton* activityButton = [[JHActivityButton alloc]initFrame:CGRectMake(100, yLoc, 100, 50) style:JHActivityButtonStyleExpandLeft];
//        [activityButton setBackgroundColor:[UIColor purpleColor] forState:UIControlStateNormal];
        [activityButton setBackgroundColor:[UIColor redColor] forState:UIControlStateHighlighted];
//        [activityButton setBackgroundColor:[UIColor blackColor] forState:UIControlStateSelected];
        [activityButton setTitle:@"hello \n second line" forState:UIControlStateNormal];
        activityButton.easingFunction = QuadraticEaseInOut;
        activityButton.animationTime = 0.5;

        [_masterScrollView addSubview:activityButton];
        
        yLoc += 120;
    }

    
    [_masterScrollView setContentSize:CGSizeMake(self.view.bounds.size.width, yLoc)];

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [_masterScrollView setFrame:self.view.bounds];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
