//
//  TetrisOther.h
//  Tetris
//
//  Created by CSX on 2017/4/17.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TetrisOther : NSObject

@end

@interface  UIColor(UIKitAdditions)

+ (UIColor *)colorWithHexString:(NSString *)hexString;

@end

@interface UIImage (UIKitAdditions)

+ (UIImage *)imageWithHexString:(NSString *)hexString;

@end

@interface UIView  (UILayoutSupport)

@property (assign, nonatomic) CGFloat x;
@property (assign, nonatomic) CGFloat y;
@property (assign, nonatomic) CGFloat width;
@property (assign, nonatomic) CGFloat height;
@property (assign, nonatomic) CGPoint origin;
@property (assign, nonatomic) CGSize  size;
@property (assign, nonatomic) CGFloat centerX;
@property (assign, nonatomic) CGFloat centerY;
@property (nonatomic, assign) CGFloat maxX;
@property (nonatomic, assign) CGFloat maxY;

@end
