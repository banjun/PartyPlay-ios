//
//  CenteringView.h
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CenteringView : UIView

- (id)initWithFrame:(CGRect)frame contentView:(UIView *)contentView;
@property (nonatomic, readonly) UIView *contentView;

@end




@interface AutoLayoutMinView : UIView

+ (instancetype)spacer;

@end

