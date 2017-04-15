//
//  ViewController.m
//  Tetris
//
//  Created by CSX on 2017/4/15.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

#import "ViewController.h"
#import "TetrisView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    TetrisView *tetrisVie = [[TetrisView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:tetrisVie];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
