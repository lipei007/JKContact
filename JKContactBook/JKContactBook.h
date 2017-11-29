//
//  JKAddressBook.h
//  JKAddressBook
//
//  Created by Jack on 16/9/6.
//  Copyright © 2016年 Emerys. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JKContactModel;
typedef void(^GetContactBookFailure)(void);

typedef void(^GetContactBook)(NSMutableDictionary *addressBook,NSArray *nameKeys);

typedef void(^authorizeFailure)(void);

@interface JKContactBook : NSObject

+ (JKContactBook *)sharedContactBook;

- (void)requestAuthorization;

- (void)sortedContactBook:(GetContactBook)block failure:(GetContactBookFailure)failure;

- (void)originalContactBook:(GetContactBook)block failure:(GetContactBookFailure)failure;

- (void)addContact:(JKContactModel *)contact;

@end
