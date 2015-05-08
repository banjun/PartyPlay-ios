//
//  CenteringView.m
//  AirHack
//
//  Created by banjun on 2014/07/13.
//  Copyright (c) 2014年 banjun. All rights reserved.
//

#import "CenteringView.h"


@implementation AutoLayoutMinView

+ (instancetype)spacer;
{
    AutoLayoutMinView *v = [[AutoLayoutMinView alloc] init];
    [v setContentCompressionResistancePriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
    [v setContentCompressionResistancePriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisVertical];
    [v setContentHuggingPriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
    [v setContentHuggingPriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisVertical];
    return v;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeZero;
}

@end


@interface CenteringView ()

@property (nonatomic) UIView *contentView;

@end


@implementation CenteringView

- (id)initWithFrame:(CGRect)frame contentView:(UIView *)contentView
{
    if (self = [super initWithFrame:frame]) {
        UIView *(^spacer)() = ^{
            UIView *v = [AutoLayoutMinView spacer];
            [self addSubview:v];
            return v;
        };
        
        UIView *leftTopSpacer = spacer();
        UIView *rightBottomSpacer = spacer();
        
        [self addSubview:contentView];
        NSDictionary *views = NSDictionaryOfVariableBindings(leftTopSpacer, rightBottomSpacer, contentView);
        for (UIView *v in views.allValues) {
            v.translatesAutoresizingMaskIntoConstraints = NO;
        }
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[leftTopSpacer][contentView][rightBottomSpacer(==leftTopSpacer)]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[leftTopSpacer][contentView][rightBottomSpacer(==leftTopSpacer)]|" options:0 metrics:nil views:views]];
    }
    return self;
}
@end
