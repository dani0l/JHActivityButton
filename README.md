JHActivityButton
================

UIButton Subclass with a built-in UIActivityIndicator. Based off the Ladda concept by Hakim El Hattab http://lab.hakim.se/ladda/

JHActivityButton makes use of the AHEasing library.

Example Usage:

JHActivityButton* activityButton = [[JHActivityButton alloc]initFrame:CGRectMake(100, yLoc, 100, 50) style:JHActivityButtonStyleExpandUp];
[activityButton setBackgroundColor:[UIColor redColor] forState:UIControlStateSelected];
[activityButton setBackgroundColor:[UIColor blueColor] forState:UIControlStateNormal];
[activityButton setTitle:@"hello" forState:UIControlStateNormal];
activityButton.easingFunction = BackEaseOut;
activityButton.animationTime = 0.5;


TODO: 
- Reverse animations (back to normal state)
- UIAppearance support for activity indicator and background color states.
- Combine animations methods to reduce code duplication

Known Issues: 

- Tons, it's early days
 