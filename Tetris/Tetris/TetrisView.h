//
//  TetrisView.h
//  Tetris
//
//  Created by CSX on 2017/4/15.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TetrisView : UIView


@end

///-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

@interface SquareGroup : UIView

/// 提示下一个组合的面板
- (UIView *)tipBoard;

/// 回到起始位置
- (void)backToStartPoint:(CGPoint)startPoint;

/// 旋转
- (void)rotate:(BOOL(^)(NSArray *nextGroup))canRotate;

@end

///-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

@interface BasicSquare : UIButton

/// 11-背景方块 ，22-组内方块
- (instancetype)initWithType:(NSInteger)type;

@end
