//
//  SSAppDelegate.h
//  shadowmap
//
//  Created by Daniel Grigg on 21/06/13.
//  Copyright (c) 2013 Sliplane Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SSViewController;

@interface SSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) SSViewController *viewController;

@end
