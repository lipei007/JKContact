//
//  JKAddressModel.m
//  JKAddressBook
//
//  Created by Jack on 16/9/6.
//  Copyright © 2016年 Emerys. All rights reserved.
//

#import "JKContactModel.h"

@implementation JKContactModel

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {

    
}

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (NSMutableArray *)phone {
    if (!_phone) {
        _phone = [NSMutableArray array];
    }
    return _phone;
}

@end
