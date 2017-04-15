//
//  TetrisView.m
//  Tetris
//
//  Created by CSX on 2017/4/15.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

#import "TetrisView.h"
#import "CellView.h"

typedef enum :NSInteger{
    cellTag = 10,
}Tags;


#define cellWith  15           //定义每一个小的方块的宽度

@interface TetrisView ()
{
    UILabel *label;
}
//大数组
@property (nonatomic, strong)NSMutableArray *dataArr;
//小数组
@property (nonatomic, strong)NSMutableArray *tempArr;
@end

@implementation TetrisView

- (NSMutableArray *)tempArr{
    if (!_tempArr) {
        _tempArr = [NSMutableArray array];
    }
    return _tempArr;
}
- (NSMutableArray *)dataArr{
    if (!_dataArr) {
        _dataArr = [NSMutableArray array];
    }
    return _dataArr;
}
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
    gameView.layer.borderWidth = 3;
    gameView.layer.borderColor = [[UIColor whiteColor] CGColor];
    [self addSubview:gameView];
    for (int i = 0; i<15*25; i++) {
        CellView *bgView = [[CellView alloc]initWithFrame:CGRectMake(i%15*cellWith, i/15*cellWith, cellWith-0.5, cellWith-0.5)];
        bgView.layer.cornerRadius = 3;
        bgView.clipsToBounds = YES;
        bgView.isSelect = NO;
        [gameView addSubview:bgView];
    }
    
    
    
    UIView *lastTypeView = [[UIView alloc]initWithFrame:CGRectMake(frame.size.width-cellWith*4, 150, cellWith*4, cellWith*4)];
    lastTypeView.backgroundColor = [UIColor blackColor];
    [self addSubview:lastTypeView];
    for (int i = 0; i<4*4; i++) {
        CellView *bgView = [[CellView alloc]initWithFrame:CGRectMake(i%4*cellWith, i/4*cellWith, cellWith-0.5, cellWith-0.5)];
        bgView.layer.cornerRadius = 3;
        bgView.clipsToBounds = YES;
        bgView.isSelect = NO;
        [lastTypeView addSubview:bgView];
    }
    
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
