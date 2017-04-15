//
//  TetrisView.m
//  Tetris
//
//  Created by CSX on 2017/4/15.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

#import "TetrisView.h"

#define cellWith  15           //定义每一个小的方块的宽度

@interface TetrisView ()
{
    UILabel *label;
}
@end

@implementation TetrisView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
         self.backgroundColor = [UIColor blackColor];
        [self createViewWithFrame:(CGRect)frame];
    }
    return self;
}

- (void)createViewWithFrame:(CGRect)frame{
    label = [[UILabel alloc]init];
    label.center = CGPointMake(frame.size.width/2 ,100 );
    label.bounds = CGRectMake(0, 0, 100, 50);
    label.font = [UIFont systemFontOfSize:17];
    label.text = @"分数：0";
    label.textColor = [UIColor whiteColor];
    label.textAlignment = 1;
    [self addSubview:label];
    
    //15*25的方格
    UIView *gameView = [[UIView alloc]initWithFrame:CGRectMake(20, 150, cellWith*15, cellWith*25)];
    gameView.backgroundColor = [UIColor blackColor];
    gameView.layer.borderWidth = 5;
    gameView.layer.borderColor = [[UIColor whiteColor] CGColor];
    [self addSubview:gameView];
    
    UIView *lastTypeView = [[UIView alloc]initWithFrame:CGRectMake(frame.size.width-cellWith*4, 150, cellWith*4, cellWith*4)];
    lastTypeView.backgroundColor = [UIColor blackColor];
    [self addSubview:lastTypeView];
    
    CGFloat buttonWidth = 70; //按钮的宽高
    
    UIView *buttonView = [[UIView alloc]initWithFrame:CGRectMake(frame.size.width-buttonWidth, CGRectGetMaxY(lastTypeView.frame)+30, buttonWidth, buttonWidth*3)];
    buttonView.backgroundColor = [UIColor blackColor];
    [self addSubview:buttonView];
    
    UIButton *buttonChange = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonChange.frame = CGRectMake(0, 0, buttonWidth, buttonWidth-20);
    [buttonChange setBackgroundColor:[UIColor blackColor]];
    [buttonChange setTitle:@"Change" forState:UIControlStateNormal];
    [buttonChange addTarget:self action:@selector(buttonChange:) forControlEvents:UIControlEventTouchUpInside];
    [buttonView addSubview:buttonChange];
    
    UIButton *buttonLeft = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonLeft.frame = CGRectMake(0, buttonWidth, buttonWidth, buttonWidth-20);
    [buttonLeft setBackgroundColor:[UIColor blackColor]];
    [buttonLeft setTitle:@"Left" forState:UIControlStateNormal];
    [buttonLeft addTarget:self action:@selector(buttonLeft:) forControlEvents:UIControlEventTouchUpInside];
    [buttonView addSubview:buttonLeft];
    
    UIButton *buttonRight = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonRight.frame = CGRectMake(0, buttonWidth*2, buttonWidth, buttonWidth-20);
    [buttonRight setBackgroundColor:[UIColor blackColor]];
    [buttonRight setTitle:@"Right" forState:UIControlStateNormal];
    [buttonRight addTarget:self action:@selector(buttonRight:) forControlEvents:UIControlEventTouchUpInside];
    [buttonView addSubview:buttonRight];
    
    UIButton *buttonDown = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonDown.frame = CGRectMake(0, buttonWidth*3, buttonWidth, buttonWidth-20);
    [buttonDown setBackgroundColor:[UIColor blackColor]];
    [buttonDown setTitle:@"Down" forState:UIControlStateNormal];
    [buttonDown addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchUpInside];
    [buttonView addSubview:buttonDown];
    
}
//旋转
- (void)buttonChange:(UIButton *)sender{
    
}

//向左
- (void)buttonLeft:(UIButton *)sender{
    
}

//向右
- (void)buttonRight:(UIButton *)sender{
    
}

//加速
- (void)buttonDown:(UIButton *)sender{
    
}




/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
