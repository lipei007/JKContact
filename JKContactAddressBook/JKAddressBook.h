//
//  JKAddressBook.h
//  JKAddressBook
//
//  Created by Jack on 16/9/6.
//  Copyright © 2016年 Emerys. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^addressBookDataFailure)(void);

typedef void(^getAddressBook)(NSMutableDictionary *addressBook,NSArray *nameKeys);

typedef void(^authorizeFailure)(void);

@interface JKAddressBook : NSObject

+ (JKAddressBook *)sharedAddressBook;

- (void)sortedAddressBook:(getAddressBook)block failure:(addressBookDataFailure)failure;

- (void)originalAddressBook:(getAddressBook)block failure:(addressBookDataFailure)failure;

@end
