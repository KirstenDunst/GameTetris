//
//  TetrisView.m
//  Tetris
//
//  Created by CSX on 2017/4/15.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//


/** TODO
 
 按照与屏幕的宽高比设置约束，横竖屏适配
 sketch
 音效 切图 字体
 游戏开始前的动画
 退出或暂停时，销毁keepMoveTimer
 Instruments
 
 使用CADisplayLink代替NSTimer
 XY计算不准确的问题！
 
 Gameboy
 
 */

#import "TetrisView.h"
#import "TetrisOther.h"

typedef enum :NSInteger{
    cellTag = 10,
}Tags;


#if TARGET_IPHONE_SIMULATOR
#define SIMULATOR 1
#elif TARGET_OS_IPHONE
#define SIMULATOR 0
#endif

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define SCALE [UIScreen mainScreen].bounds.size.width/375
#define kSquareWH 15  // (kScreenWidth / 20)

#define kRowCount 20
#define kColumnCount 11

@interface TetrisView ()
{
    CGPoint _startPoint;        // 新组合origin
    CGFloat _edgeRotateOffset;  // 旋转溢出补偿
    int _bestScore;             // 最高分
    int _levelUpCounter;        // 计满20行升级
    BOOL _disableButtonActions; // 按钮禁用1
    BOOL _disablePauseButton;   // 刷新动画期间使暂停按钮无效
}

@property (strong, nonatomic) UIView *squareRoomView;
@property (strong, nonatomic) SquareGroup *group;

@property (strong, nonatomic)  UILabel *scoreLabel;
@property (strong, nonatomic)  UITextField *scoreField;
@property (strong, nonatomic)  UILabel *lineCountLabel;
@property (strong, nonatomic)  UITextField *lineCountField;
@property (strong, nonatomic)  UITextField *levelField;
@property (strong, nonatomic)  UIView *tipBoardView;
@property (strong, nonatomic)  UIButton *pauseButton;
@property (strong, nonatomic)  UIButton *replayButton;

@property (strong, nonatomic) NSTimer *dropDownTimer;       // 下落计时 1
@property (strong, nonatomic) NSTimer *keepMoveTimer;       // 按住按钮持续移动 0
@property (strong, nonatomic) NSTimer *refreshTimer;        // 刷新动画计时 0
@property (strong, nonatomic) NSTimer *playTimer;           // 游戏计时

@property (assign, nonatomic) int score;                    // 当前得分
@property (assign, nonatomic) int clearedLines;             // 消除行数
@property (assign, nonatomic) int startupLines;             // 起始行数
@property (assign, nonatomic) int speedLevel;               // 速度级别
@property (assign, nonatomic) BOOL isSettingMode;           // YES-设置 NO-移动

@end

@implementation TetrisView

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame{
    if ([super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        [self createView];
        [self setupUI];
        [self initConfigs];
        [self configNotifications];
    }
    return self;
}
- (void)createView{
    UIView *playView = [[UIView alloc]init];
    playView.backgroundColor = [UIColor lightGrayColor];
    [self addSubview:playView];
    [playView addSubview:self.squareRoomView];
    playView.frame = CGRectMake(20*SCALE, 64, self.squareRoomView.frame.size.width, self.squareRoomView.frame.size.height);
    NSArray *titleArr = @[@"最高分",@"起始行",@"级别",@"下一个"];
    for (int i = 0; i<4; i++) {
        UILabel *label = [[UILabel alloc]init];
        label.frame = CGRectMake(kScreenWidth-120*SCALE, 64+80*i, 100*SCALE, 30);
        label.font = [UIFont systemFontOfSize:15*SCALE];
        label.text = titleArr[i];
        [self addSubview:label];
    }
    for (int i = 0; i<3; i++) {
        UITextField *text = [[UITextField alloc]initWithFrame:CGRectMake(kScreenWidth-120*SCALE, 64+40+80*i, 100*SCALE, 40)];
        text.borderStyle = UITextBorderStyleRoundedRect;
        text.textAlignment = NSTextAlignmentRight;
        [self addSubview:text];
        if (i == 0) {
            self.scoreField = text;
        }else if (i == 1){
            self.lineCountField = text;
        }else{
            self.levelField = text;
        }
    }
    self.tipBoardView = [[UIView alloc]initWithFrame:CGRectMake(kScreenWidth-120*SCALE, 64+80*3+40, 60*SCALE, 60*SCALE)];
    [self addSubview:self.tipBoardView];
    
    self.pauseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.pauseButton.frame = CGRectMake(kScreenWidth-120*SCALE, CGRectGetMaxY(self.tipBoardView.frame), 50, 40);
    [self.pauseButton setTitle:@"PA" forState:UIControlStateNormal];
    [self.pauseButton addTarget:self action:@selector(pause:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.pauseButton];
    self.replayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.replayButton.frame = CGRectMake(CGRectGetMaxX(self.pauseButton.frame), CGRectGetMinY(self.pauseButton.frame), 50, 40);
    [self.replayButton setTitle:@"RP" forState:UIControlStateNormal];
    [self.replayButton addTarget:self action:@selector(rePlay:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.replayButton];
    
    
    UIButton *myCreateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    myCreateButton.frame = CGRectMake(CGRectGetMinX(self.pauseButton.frame), CGRectGetMaxY(self.pauseButton.frame), 100, 100);
    [myCreateButton setBackgroundColor:[UIColor grayColor]];
    [myCreateButton setTitle:@"C" forState:UIControlStateNormal];
    [myCreateButton addTarget:self action:@selector(rotate:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:myCreateButton];
    UIButton *buttonThunderDown = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonThunderDown.frame = CGRectMake(70, CGRectGetMaxY(playView.frame)+20, 50, 50);
    buttonThunderDown.layer.cornerRadius = 25;
    buttonThunderDown.clipsToBounds = YES;
    [buttonThunderDown setBackgroundColor:[UIColor grayColor]];
    [buttonThunderDown setTitle:@"DTH" forState:UIControlStateNormal];
    [buttonThunderDown addTarget:self action:@selector(thunderDown:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:buttonThunderDown];
    UIButton *buttonLeft = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonLeft.frame = CGRectMake(20, CGRectGetMaxY(buttonThunderDown.frame), 50, 50);
    buttonLeft.layer.cornerRadius = 25;
    buttonLeft.clipsToBounds = YES;
    buttonLeft.tag = 111;
    [buttonLeft setBackgroundColor:[UIColor grayColor]];
    [buttonLeft setTitle:@"L" forState:UIControlStateNormal];
    [buttonLeft addTarget:self action:@selector(left:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:buttonLeft];
    UILongPressGestureRecognizer *longPressLeft = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(setupKeepMoveTimer:)];
    [buttonLeft addGestureRecognizer:longPressLeft];
    UIButton *buttonRight = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonRight.frame = CGRectMake(120, CGRectGetMaxY(buttonThunderDown.frame), 50, 50);
    buttonRight.layer.cornerRadius = 25;
    buttonRight.clipsToBounds = YES;
    buttonRight.tag = 122;
    [buttonRight setBackgroundColor:[UIColor grayColor]];
    [buttonRight setTitle:@"R" forState:UIControlStateNormal];
    [buttonRight addTarget:self action:@selector(right:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:buttonRight];
    UILongPressGestureRecognizer *longPressRight = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(setupKeepMoveTimer:)];
    [buttonRight addGestureRecognizer:longPressRight];
    UIButton *buttonDown = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonDown.frame = CGRectMake(70, CGRectGetMaxY(buttonThunderDown.frame)+50, 50, 50);
    buttonDown.layer.cornerRadius = 25;
    buttonDown.clipsToBounds = YES;
    buttonDown.tag = 133;
    [buttonDown setBackgroundColor:[UIColor grayColor]];
    [buttonDown setTitle:@"DW" forState:UIControlStateNormal];
    [buttonDown addTarget:self action:@selector(down:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:buttonDown];
    UILongPressGestureRecognizer *longPressDown = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(setupKeepMoveTimer:)];
    [buttonDown addGestureRecognizer:longPressDown];
}
- (void)initConfigs {
    _startPoint = CGPointMake(kSquareWH * 4, 0);
    _bestScore = [self getBestScore];
    self.speedLevel = 1;
    self.score = 0;
    self.isSettingMode = YES;
}

- (void)setupUI {
    [self.squareRoomView addSubview:self.group];//显示运动的小方格
    [self.tipBoardView addSubview:self.group.tipBoard]; //添加下一个显示样式
}

/// 进入后台时暂停游戏
- (void)configNotifications {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        self.pauseButton.selected = NO;
        [self pause:self.pauseButton];
    }];
}

#pragma mark - 定时器

- (void)destroyTimer:(NSTimer *)timer {
    [timer invalidate];
    timer = nil;
}

/// 计时模式计时
- (void)setupPlayTimer {
    CGFloat duration = 5 * 60.0;
    self.playTimer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(gameOverOperaton) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.playTimer forMode:NSRunLoopCommonModes];
}

/// 下落计时
- (void)setupDropDownTimer {
    CGFloat duartion = 1.0 * pow(0.75, (self.speedLevel - 1));
    self.dropDownTimer = [NSTimer scheduledTimerWithTimeInterval:duartion target:self selector:@selector(down:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.dropDownTimer forMode:NSRunLoopCommonModes];
}

/// 按住按钮持续移动的计时
- (void)setupKeepMoveTimer:(UILongPressGestureRecognizer *)longGes {
    if (self.isSettingMode) return;
    SEL controlAction = NULL;
    CGFloat duration = 0;
    switch (longGes.view.tag) {
        case 111: // left
            controlAction = @selector(left:);
            duration = 0.1;
            break;
        case 133: // down
            controlAction = @selector(down:);
            duration = 0.03;
            break;
        case 122: // right
            controlAction = @selector(right:);
            duration = 0.1;
            break;
    }
    
    if (self.keepMoveTimer == nil) {
        self.keepMoveTimer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:controlAction userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.keepMoveTimer forMode:NSRunLoopCommonModes];
    }
    
    if (longGes.state == UIGestureRecognizerStateEnded || longGes.state == UIGestureRecognizerStateFailed || longGes.state == UIGestureRecognizerStateCancelled) {
        [self.keepMoveTimer invalidate];
        self.keepMoveTimer = nil;
    }
}

#pragma mark - 游戏中

/// 将落下的方块固定
- (void)convertGroupSquareToBlack {
    // 取消下落计时
    [self destroyTimer:self.dropDownTimer];
    // 固定已下落的组合
    for (int i = 0; i < self.group.subviews.count; i++) {
        BasicSquare *square = self.group.subviews[i];
        if (square.selected) {
            // 将square的坐标转换到背景中
            CGRect rect2 = [self.squareRoomView convertRect:square.frame fromView:self.group];
            if (rect2.origin.y >= 0) {
                int X = rect2.origin.x / kSquareWH;
                int Y = rect2.origin.y / kSquareWH;
                int indexOfBehindSquare = Y * kColumnCount + X;
                BasicSquare *behindSquare = self.squareRoomView.subviews[indexOfBehindSquare];
                behindSquare.selected = YES;
            }
        }
    }
}

/// 消行 改进：行数为0时返回、group延时回到起点
- (void)clearFullLines {
    
    NSArray *linesShouldClear = [self LineArrayWaitForClear];
    
    // 消行动画
    for (int i = 0; i < linesShouldClear.count; i++) {
        for (NSNumber *index in linesShouldClear[i]) {
            BasicSquare *square = self.squareRoomView.subviews[[index intValue]];
            
            [self dispatchAfter:0.05 operation:^{
                square.selected = NO;
                [self dispatchAfter:0.1 operation:^{
                    square.selected = YES;
                    [self dispatchAfter:0.1 operation:^{
                        square.selected = NO;
                        [self dispatchAfter:0.1 operation:^{
                            square.selected = YES;
                            [self dispatchAfter:0.1 operation:^{
                                square.selected = NO;
                            }]; }]; }]; }]; }];
            
        }
    }
    
    // 消行
    CGFloat duration = SIMULATOR ? 0.8 : 0.55;
    [self dispatchAfter:duration operation:^{
        for (int i = 0; i < linesShouldClear.count; i++) {
            
            NSArray *squareLine = linesShouldClear[i];
            int lastSquareIndex = [squareLine.lastObject intValue];
            
            for (int j = lastSquareIndex; j > 0; j--) {
                
                BasicSquare *lastLineSquare = self.squareRoomView.subviews[j];
                
                if (j >= kColumnCount) {
                    BasicSquare *aboveSquare = self.squareRoomView.subviews[j - kColumnCount];
                    lastLineSquare.selected = aboveSquare.selected;
                    
                }else {
                    lastLineSquare.selected = NO;
                }
            }
        }
    }];
    
    // 消行计分、提高速度级别
    [self calcScoreAndSpeedLevel:(int)linesShouldClear.count];
    // 消除动画完成后，判断游戏结束，group回到起始位置
    if (![self isOver]) {
        [self.group backToStartPoint:_startPoint];
        [self setupDropDownTimer];
        
    }else {
        [self gameOverOperaton];
    }
}

/// 找出需要消除的行
- (NSArray *)LineArrayWaitForClear {
    
    // 找出刚落下的组合对应的都是第几行
    NSMutableArray *lineMaybeFull_Arr = [NSMutableArray arrayWithCapacity:4];
    
    for (int i = 0; i < self.group.subviews.count; i++) {
        BasicSquare *square = self.group.subviews[i];
        
        if (square.selected) {
            
            CGRect rect2 = [self.squareRoomView convertRect:square.frame fromView:self.group];
            
            int Y = rect2.origin.y / kSquareWH;
            // 增加 Y>=0 的判断，防止当新组合没有完全进入视野时变黑时引发数组越界
            if (Y >=0 && ![lineMaybeFull_Arr containsObject:@(Y)]) {
                [lineMaybeFull_Arr addObject:@(Y)];
            }
            
        }
    }
    
    // 拿到这些行里面所有按钮的索引
    NSMutableArray *indexArrays = [NSMutableArray arrayWithCapacity:4];
    
    for (int i = 0; i < lineMaybeFull_Arr.count; i++) {
        
        int Y = [lineMaybeFull_Arr[i] intValue];
        
        NSMutableArray *indexArrayForALine = [NSMutableArray arrayWithCapacity:kColumnCount];
        for (int j = 0; j < kColumnCount; j++) {
            int index = Y * kColumnCount + j;
            [indexArrayForALine addObject:@(index)];
        }
        [indexArrays addObject:indexArrayForALine];
        
    }
    
    // 判断其中某一行是否不满
    NSMutableArray *notFullLines = [NSMutableArray arrayWithCapacity:4];
    for (int i = 0; i < indexArrays.count; i++) {
        NSArray *indexArr = indexArrays[i];
        int notFullFlag = 0;
        for (int j = 0; j < indexArr.count; j++) {
            int squareIndex = [indexArr[j] intValue];
            BasicSquare *square = self.squareRoomView.subviews[squareIndex];
            if (!square.selected) {
                notFullFlag = 1;
            }
        }
        if (notFullFlag) {
            [notFullLines addObject:indexArr];
        }
    }
    
    // 只保留满行的数组
    [indexArrays removeObjectsInArray:notFullLines];
    
    return indexArrays;
}

/// 根据消除的行数计分、提高速度级别 bug
- (void)calcScoreAndSpeedLevel:(int)clearedCount {
    
    self.clearedLines += clearedCount;
    _levelUpCounter += clearedCount;
    
    if (clearedCount) {
        self.score += clearedCount == 1 ? 100 : (clearedCount == 2 ? 300 : (clearedCount == 3 ? 600 : 1000));
    }
    
    if (self.speedLevel < 6 && _levelUpCounter >= 20) {
        self.speedLevel += 1;
        _levelUpCounter -= 20;
    }
    
}

/// 游戏结束后的操作
- (void)gameOverOperaton {
    NSLog(@"---- Game Over ----");
    
    self.group.hidden = YES;
    // 记录最高分
    [self saveScore:self.score];
    // 清空当前得分行数
    self.clearedLines = 0;
    self.score = 0;
    // 销毁计时器
    [self destroyTimer:self.dropDownTimer];
    // 刷新动画 1.6s
    [self commitRefreshAnimation];
    // 动画执行一半
    CGFloat duration = SIMULATOR ? 1.2 : 0.8;
    [self dispatchAfter:duration operation:^{
        self.isSettingMode = YES;
    }];
    
}

/// 刷新动画
- (void)commitRefreshAnimation {
    
    // 禁止按钮操作
    _disableButtonActions = YES;
    _disablePauseButton = YES;
    // 暂停时取消暂停
    self.pauseButton.selected = NO;
    
    __weak typeof(self) weakSelf = self;
    __block int startIndex = kColumnCount * kRowCount - 1;
    
    // 变白
    __block void(^refreshWhite)() = ^{
        
        int i = startIndex;
        
        if (i > kColumnCount * kRowCount - 1) {
            [weakSelf destroyTimer:weakSelf.refreshTimer];
            // 改进：代码执行完了，但是屏幕刷新延迟了，所以这个操作需要延时 ?
            CGFloat duration = SIMULATOR ? 0.5 : 0.2;
            [weakSelf dispatchAfter:duration operation:^{
                _disableButtonActions = NO; ///
                _disablePauseButton = NO;
            }];
            return;
        }
        for (; i < startIndex + kColumnCount; i++) {
            BasicSquare *square = weakSelf.squareRoomView.subviews[i];
            square.selected = NO;
        }
        startIndex = i;
        
    };
    
    // 变黑
    __block void(^refresh)() = ^{
        int i = startIndex;
        if (i < 0) {
            startIndex = 0;
            refresh = refreshWhite;
        }else {
            for (; i > startIndex - kColumnCount; i--) {
                BasicSquare *square = weakSelf.squareRoomView.subviews[i];
                square.selected = YES;
            }
            startIndex = i;
        }
    };
    
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.04 repeats:YES block:^(NSTimer * _Nonnull timer) {
        refresh();
    }];
    [[NSRunLoop currentRunLoop] addTimer:self.refreshTimer forMode:NSRunLoopCommonModes];
    
}

#pragma mark - 控制

- (void)left:(UIButton *)sender {
    if ([self isPauseState]) return;
    
    // 设置模式调整速度级别
    if (self.isSettingMode) {
        self.speedLevel = self.speedLevel < 2 ? 6 : self.speedLevel - 1;
        return;
    }
    // 向左移动
    if ([self canMoveLeft]) {
        self.group.x -= kSquareWH;
    }
    
}

- (void)right:(id)sender {
    if ([self isPauseState]) return;
    
    if (self.isSettingMode) {
        self.speedLevel = self.speedLevel > 5 ? 1 : self.speedLevel + 1;
        return;
    }
    
    if ([self canMoveRight]) {
        self.group.x += kSquareWH;
    }
    
}

- (void)down:(id)sender {
    if ([self isPauseState]) return;
    
    if (self.isSettingMode) {
        self.startupLines = self.startupLines < 1 ? 10 : self.startupLines - 1;
        return;
    }
    
    if ([self canMoveDown]) {
        self.group.y += kSquareWH;
        
        if (sender != nil) {
            [self destroyTimer:self.dropDownTimer];
            [self setupDropDownTimer];
        }
        
    }else {
        [self convertGroupSquareToBlack];
        // 下落得分
        self.score += 18;
        // 消行
        [self clearFullLines];
    }
    
}

- (void)thunderDown:(UIButton *)sender {
    if ([self isPauseState]) return;
    
    if (self.isSettingMode) {
        self.startupLines = (self.startupLines + 1) % 11;
        return;
    }
    
    while ([self canMoveDown]) {
        [self down:nil];
    }
    [self down:nil];
    
    // 窗口动画
    [UIView animateWithDuration:0.06 animations:^{
        self.squareRoomView.y += 6;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.05 animations:^{
            self.squareRoomView.y -= 6;
        }];
    }];
}

- (void)rotate:(id)sender {
    if ([self isPauseState]) return;
    
    if (self.isSettingMode) {
        [self startPlay];
        return;
    }
    
    // 如果旋转后重合则不允许旋转
    [self.group rotate:^BOOL(NSArray *nextGroup) {
        return [self canRotate:nextGroup];
    }];
    
    // 如果旋转后超出范围，旋转并调整origin
    if (_edgeRotateOffset != 0) {
        self.group.x += _edgeRotateOffset;
        _edgeRotateOffset = 0;
    }
}

#pragma mark - 判断

/// 是否处于非游戏状态：暂停 刷新
- (BOOL)isPauseState {
    // 暂停时取消暂停
    if (self.pauseButton.selected) {
        _disableButtonActions = NO;
        [self setupDropDownTimer];
        self.pauseButton.selected = NO;
        return YES;
        // 刷新动画时按钮无效
    }else if (_disableButtonActions) {
        return YES;
    }else {
        return NO;
    }
}

/// 是否结束游戏
- (BOOL)isOver {
    for (int i = 0; i < kColumnCount; i++) {
        BasicSquare *square = self.squareRoomView.subviews[i];
        if (square.selected) {
            return YES;
        }
    }
    return NO;
}

/// 是否可以旋转
- (BOOL)canRotate:(NSArray *)nextGroup {
    
    for (int i = 0; i < nextGroup.count; i++) {
        BasicSquare *square = self.group.subviews[[nextGroup[i] intValue]];
        CGRect squareRect = [self.squareRoomView convertRect:square.frame fromView:self.group];
        
        int X = squareRect.origin.x / kSquareWH;
        int Y = squareRect.origin.y / kSquareWH;
        
        if (X < 0) {
            _edgeRotateOffset = -X * kSquareWH;
        }else if (X >= kColumnCount) {
            _edgeRotateOffset = (kColumnCount - X - 1) * kSquareWH;
        }
        
        // XY判断
        if (Y >= kRowCount) {
            return NO;
        }
        
        // 重合判断
        if (Y >= 0) {
            int indexOfBehindSquare = Y * kColumnCount + X;
            BasicSquare *behindSquare = self.squareRoomView.subviews[indexOfBehindSquare];
            if (behindSquare.selected) {
                return NO;
            }
        }
    }
    
    return YES;
}

/// 是否可以移动
- (BOOL)canMoveDown {
    
    for (int i = 0; i < self.group.subviews.count; i++) {
        BasicSquare *square = self.group.subviews[i];
        if (square.selected) {
            
            // 将square的坐标转换到背景中
            CGRect rect2 = [self.squareRoomView convertRect:square.frame fromView:self.group];
            
            // 只考虑显示在room范围内的，防止崩溃
            if (rect2.origin.y >= 0) {
                int X = rect2.origin.x / kSquareWH;
                int Y = rect2.origin.y / kSquareWH;
                
                if (Y == kRowCount - 1) return NO;
                
                int indexOfBelowSquare = (Y + 1) * kColumnCount + X;
                
                BasicSquare *belowSquare = self.squareRoomView.subviews[indexOfBelowSquare];
                
                if (belowSquare.isSelected) {
                    return NO;
                }
            }
        }
    }
    
    return YES;
}

- (BOOL)canMoveLeft {
    
    for (int i = 0; i < self.group.subviews.count; i++) {
        BasicSquare *square = self.group.subviews[i];
        if (square.selected) {
            // 将square的坐标转换到背景中
            CGRect rect2 = [self.squareRoomView convertRect:square.frame fromView:self.group];
            int X = rect2.origin.x / kSquareWH;
            int Y = rect2.origin.y / kSquareWH;
            if (X == 0) return NO;
            if (Y >= 0) {
                int indexOfLeftSquare = Y * kColumnCount + X - 1;
                BasicSquare *leftSquare = self.squareRoomView.subviews[indexOfLeftSquare];
                if (leftSquare.isSelected) {
                    return NO;
                }
            }
        }
    }
    return YES;
}

- (BOOL)canMoveRight {
    
    for (int i = 0; i < self.group.subviews.count; i++) {
        BasicSquare *square = self.group.subviews[i];
        if (square.selected) {
            // 将square的坐标转换到背景中
            CGRect rect2 = [self.squareRoomView convertRect:square.frame fromView:self.group];
            
            int X = rect2.origin.x / kSquareWH;
            int Y = rect2.origin.y / kSquareWH;
            
            if (X == kColumnCount - 1) return NO;
            
            if (Y >= 0) {
                int indexOfRightSquare = Y * kColumnCount + X + 1;
                
                BasicSquare *rightSquare = self.squareRoomView.subviews[indexOfRightSquare];
                
                if (rightSquare.isSelected) {
                    return NO;
                }
            }
        }
    }
    return YES;
}

#pragma mark - 设置

/// 音效
- (void)configVoice:(UIButton *)sender {
    if (_disableButtonActions) return;
    sender.selected = !sender.selected;
}

/// 暂停
- (void)pause:(UIButton *)sender {
    if (_disablePauseButton) return;
    
    if (self.isSettingMode) {
        [self startPlay];
        return;
    }
    sender.selected = !sender.selected;
    
    if (sender.selected) {
        _disableButtonActions = YES;
        [self destroyTimer:self.dropDownTimer];
    }else {
        _disableButtonActions = NO;
        [self setupDropDownTimer];
    }
}

/// 重玩
- (void)rePlay:(UIButton *)sender {
     if (_disableButtonActions) return;
    
    if (self.isSettingMode) {
        [self startPlay];
    }else {
        [self convertGroupSquareToBlack];
        [self gameOverOperaton];
    }
}

/// 点击其他按钮开始游戏
- (void)startPlay {
    self.isSettingMode = NO;
    self.group.hidden = NO;
    [self.group backToStartPoint:_startPoint];
    [self setupDropDownTimer];
    [self configRandomLines];
}

/// 设置起始行
- (void)configRandomLines {
    if (self.startupLines == 0) return;
    for (int i = kColumnCount * kRowCount - 1; i > kColumnCount * (kRowCount - self.startupLines); i--) {
        BasicSquare *square = self.squareRoomView.subviews[i];
        square.selected = arc4random_uniform(2);
    }
}

/// 存取最高分
- (void)saveScore:(int)score {
    if (score > _bestScore) {
        _bestScore = score;
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"bestScore"];
        [[NSUserDefaults standardUserDefaults] setObject:@(score) forKey:@"bestScore"];
    }
}

- (int)getBestScore {
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"bestScore"]) {
        return [[[NSUserDefaults standardUserDefaults]objectForKey:@"bestScore"] intValue];
    }
    return 0;
}

#pragma mark - setters

- (void)setIsSettingMode:(BOOL)isSettingMode {
    _isSettingMode = isSettingMode;
    if (isSettingMode) {
        self.scoreLabel.text = @"最高分";
        self.scoreField.text = @(_bestScore).stringValue;
        self.lineCountLabel.text = @"起始行";
        self.lineCountField.text = @(self.startupLines).stringValue;
    }else {
        self.scoreLabel.text = @"当前得分";
        self.scoreField.text = @(self.score).stringValue;
        self.lineCountLabel.text = @"消除行";
        self.lineCountField.text = @(self.clearedLines).stringValue;
    }
}

- (void)setScore:(int)score {
    _score = score;
    self.scoreField.text = @(score).stringValue;
}

- (void)setClearedLines:(int)clearedLines {
    _clearedLines = clearedLines;
    self.lineCountField.text = @(clearedLines).stringValue;
}

- (void)setStartupLines:(int)startupLines {
    _startupLines = startupLines;
    self.lineCountField.text = @(startupLines).stringValue;
}

- (void)setSpeedLevel:(int)speedLevel {
    _speedLevel = speedLevel;
    self.levelField.text = @(self.speedLevel).stringValue;
}

#pragma mark - lazy loads
//下落的格子部落
- (UIView *)squareRoomView {
    if (!_squareRoomView) {
        
        CGFloat w = kSquareWH * kColumnCount;
        CGFloat h = kSquareWH * kRowCount;
        CGFloat x = 0;
        CGFloat y = 0;
        
        _squareRoomView = [[UIView alloc] init];
        _squareRoomView.frame = CGRectMake(x, y, w, h);
//        _squareRoomView.centerX = 0.5 * kScreenWidth;
//        _squareRoomView.x -= 75;
        _squareRoomView.clipsToBounds = YES;
        _squareRoomView.userInteractionEnabled = NO;
        _squareRoomView.layer.borderColor = [UIColor blackColor].CGColor;
        _squareRoomView.layer.borderWidth = 1;
        
        for (int i = 0; i < kColumnCount * kRowCount; i++) {
            BasicSquare *square = [[BasicSquare alloc] initWithType:11];
            square.frame = CGRectMake(i % kColumnCount * kSquareWH, i / kColumnCount * kSquareWH, kSquareWH, kSquareWH);
            square.selected = NO;
            [_squareRoomView addSubview:square];
//            // test
//                        [square setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
//                        [square setTitle:[NSString stringWithFormat:@"%d", i] forState:UIControlStateNormal];
            
        }
    }
    return _squareRoomView;
}

- (SquareGroup *)group {
    if (!_group) {
        _group = [[SquareGroup alloc] init];
    }
    return _group;
}

#pragma mark - Assistant

- (void)dispatchAfter:(CGFloat)time operation:(void(^)())operation {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), operation);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
        CGPoint location = [[touches anyObject] locationInView:self.squareRoomView];
        if (CGRectContainsPoint(self.squareRoomView.bounds, location)) {
            
        }
    }
}


@end



///=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-
///=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-


@interface SquareGroup ()

@property (strong, nonatomic) NSArray *types;
@property (strong, nonatomic) NSArray *group;
@property (strong, nonatomic) NSArray *tipGroup;

@property (strong, nonatomic) NSArray *tipTypes;
@property (assign, nonatomic) int tipIndex;

@property (strong, nonatomic) UIView *tipView;

@end

@implementation SquareGroup

- (instancetype)init {
    if (self = [super init]) {
        self.frame = CGRectMake(0, 0, kSquareWH * 4, kSquareWH * 4);
        
        for (int i = 0; i < 16; i++) {
            BasicSquare *squareMask = [[BasicSquare alloc] initWithType:22];
            squareMask.frame = CGRectMake(i % 4 * kSquareWH, i / 4 * kSquareWH, kSquareWH, kSquareWH);
            [self addSubview:squareMask];
            
            /// test
            //            [squareMask setTitle:[NSString stringWithFormat:@"%d", i] forState:UIControlStateNormal];
        }
    }
    return self;
}

- (UIView *)tipBoard {
    return self.tipView;
}

/// 更新下一个提示
- (void)updateTipView {
    
    for (BasicSquare *square in self.tipView.subviews) {
        square.selected = NO;
    }
    NSArray *tip = self.tipTypes[self.tipIndex];
    for (int i = 0; i < tip.count; i++) {
        int index = [tip[i] intValue];
        BasicSquare *square = self.tipView.subviews[index];
        square.selected = YES;
    }
    
}

/// 回到起始位置
- (void)backToStartPoint:(CGPoint)startPoint {
    self.origin = startPoint;
    [self clearPrevGroup];
    [self showCurrentGroup];
    [self initPosition];
    [self updateTipView];
}

/// 清空上次显示
- (void)clearPrevGroup {
    for (BasicSquare *square in self.subviews) {
        square.selected = NO;
    }
}

/// 显示组合
- (void)showCurrentGroup {
    
    if (self.tipGroup == nil) {
        self.tipGroup = [[self catchAnRandomGroup] firstObject];
    }
    self.group = self.tipGroup.copy;
    NSArray *randomData = [self catchAnRandomGroup];
    self.tipGroup = [randomData firstObject];
    self.tipIndex = [[randomData lastObject] intValue];
    
    for (int i = 0; i <self.group.count; i++) {
        int index = [self.group[i] intValue];
        BasicSquare *squareM = self.subviews[index];
        squareM.selected = YES;
    }
    
}

/// 随机取出一个组合及其索引 [group, index]
- (NSArray *)catchAnRandomGroup {
    int bangIndex = arc4random_uniform((uint32_t)self.types.count);
    NSArray *randomBang = self.types[bangIndex];
    int groupindex = arc4random_uniform((uint32_t)randomBang.count);
    NSArray *randomGroup = randomBang[groupindex];
    return @[randomGroup, @(bangIndex)];
}

/// 设置初始位置
- (void)initPosition {
    // 新组合出现时只显示最下面一行
    for (int i = (int)self.subviews.count - 1; i >= 0; i--) {
        BasicSquare *lastSquare = self.subviews[i];
        if (lastSquare.selected) {
            self.y -= lastSquare.y;
            return;
        }
    }
}

/// 旋转
- (void)rotate:(BOOL(^)(NSArray *nextGroup))canRotate {
    
    // 找出包含待旋转方块组和的数组
    NSArray *array;
    
    for (int i = 0; i < self.types.count; i++) {
        NSArray *tempArray = self.types[i];
        if ([tempArray containsObject:self.group]) {
            array = tempArray;
        }
    }
    // 拿到该组合的索引，循环取出下一个组合
    NSInteger index = [array indexOfObject:self.group];
    NSInteger nextIndex = (index +1) % array.count;
    NSArray *nextGroup = array[nextIndex];
    
    // 显示组合
    if (canRotate(nextGroup)) {
        [self clearPrevGroup];
        
        for (int i = 0; i <nextGroup.count; i++) {
            int index = [nextGroup[i] intValue];
            BasicSquare *squareM = self.subviews[index];
            squareM.selected = YES;
        }
        self.group = nextGroup;
    }
}

#pragma mark - lazy loads

- (UIView *)tipView {
    if (!_tipView) {
        _tipView = [[UIView alloc] init];
        _tipView.frame = CGRectMake(0, 0, 4 *kSquareWH, 2 *kSquareWH);
        
        for (int i = 0; i < 8; i++) {
            BasicSquare *squareMask = [[BasicSquare alloc] initWithType:22];
            squareMask.frame = CGRectMake(i % 4 * kSquareWH, i / 4 * kSquareWH, kSquareWH, kSquareWH);
            [_tipView addSubview:squareMask];
            [squareMask setTitle:[NSString stringWithFormat:@"%d", i] forState:UIControlStateNormal];
        }
    }
    return _tipView;
}

- (NSArray *)tipTypes {
    if (!_tipTypes) {
        _tipTypes = @[
                      @[@0, @1, @5, @6], // Z
                      @[@1, @2, @4, @5], // 反Z
                      @[@2, @4, @5, @6], // L
                      @[@0, @4, @5, @6], // 反L
                      @[@1, @4, @5, @6], // 凸
                      @[@0, @1, @4, @5], // 田
                      @[@4, @5, @6, @7], // 一
                      ];
    }
    return _tipTypes;
}

- (NSArray *)types {
    if (!_types) {
        _types = @[
                   @[
                       @[@1, @4, @5, @8],   // Z
                       @[@0, @1, @5, @6],
                       ],
                   
                   @[
                       @[@1, @5, @6, @10],  // 反Z
                       @[@1, @2, @4, @5],
                       ],
                   
                   @[
                       @[@1, @2, @6, @10],
                       @[@6, @8, @9, @10],
                       @[@0, @4, @8, @9],   // L
                       @[@0, @1, @2, @4],
                       ],
                   
                   @[
                       @[@0, @1, @4, @8],
                       @[@0, @1, @2, @6],
                       @[@2, @6, @9, @10],  // 反L
                       @[@4, @8, @9, @10],
                       ],
                   
                   @[
                       @[@1, @4, @5, @9],
                       @[@1, @4, @5, @6],   // 凸
                       @[@1, @5, @6, @9],
                       @[@4, @5, @6, @9],
                       ],
                   
                   @[
                       @[@0, @1, @4, @5],    // 田
                       ],
                   
                   @[
                       @[@4, @5, @6, @7],   // 一
                       @[@1, @5, @9, @13],
                       ],
                   
                   ];
    }
    return _types;
}


@end


///=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-
///=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-


@implementation BasicSquare
{
    NSInteger _type;
}

- (instancetype)initWithType:(NSInteger)type {
    if (self = [super init]) {
        _type = type;
        
        if (type == 11) {
            self.layer.borderWidth = 0.5;
            self.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3].CGColor;
        }
        // test
        [self.titleLabel setFont:[UIFont systemFontOfSize:7]];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (_type == 11) {
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:selected ? 0.8 : 0.3];
    }else if (_type == 22) {
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:selected ? 0.5 : 0];
    }
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    
}

@end



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

