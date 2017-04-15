//
//  CellView.m
//  Tetris
//
//  Created by CSX on 2017/4/15.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

#import "CellView.h"

@implementation CellView

- (instancetype)initWithFrame:(CGRect)frame{
    if ([super initWithFrame:frame]) {
        [self createView];
    }
    return self;
}
- (void)createView{
    self.backgroundColor = self.isSelect?[UIColor whiteColor]:[UIColor blackColor];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
