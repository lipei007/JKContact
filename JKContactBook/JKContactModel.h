//
//  JKAddressModel.h
//  JKAddressBook
//
//  Created by Jack on 16/9/6.
//  Copyright © 2016年 Emerys. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JKContactModel : NSObject

@property (nonatomic,copy) NSString *name;

@property (nonatomic,strong) NSMutableArray *phone;

@property (nonatomic,strong) UIImage *header;

@end
