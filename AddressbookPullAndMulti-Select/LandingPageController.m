//
//  LandingPageController.m
//  MultiSelectUIXibVersion
//
//  Created by Aditya Narayan on 10/28/14.
//  Copyright (c) 2014 TurnToTech. All rights reserved.
//

#import "LandingPageController.h"
#import "TBMultiselectController.h"
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface LandingPageController ()

@end

@implementation LandingPageController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(openMultiContactsSelectView)];
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];

    
    self.navigationController.navigationBar.topItem.rightBarButtonItem = rightBarButton;
    self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0xF23A3A);
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction) openMultiContactsSelectView {
    TBMultiselectController *msvc = [[TBMultiselectController alloc]init];
    [self.navigationController pushViewController:msvc animated:YES];
}




@end
