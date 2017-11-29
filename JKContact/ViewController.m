//
//  ViewController.m
//  JKContact
//
//  Created by emerys on 2017/5/25.
//  Copyright © 2017年 Emerys. All rights reserved.
//

#import "ViewController.h"
#import "JKContactBook.h"
#import "JKContactModel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[JKContactBook sharedContactBook] addContact:nil];
    
    [[JKContactBook sharedContactBook] sortedContactBook:^(NSMutableDictionary *address, NSArray *nameKeys) {
        
        for (NSString *key in nameKeys) {
            NSLog(@"------------------%@-----------------------",key);
            NSArray *addr = [address objectForKey:key];
            for (JKContactModel *model in addr) {
                
                NSLog(@"%@  %@",model.name,model.phone);
                
            }
            
            NSLog(@"\n");
            
        }
        
        
    } failure:^{
        
        NSLog(@"failure");
        
    }];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
