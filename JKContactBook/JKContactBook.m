//
//  JKAddressBook.m
//  JKAddressBook
//
//  Created by Jack on 16/9/6.
//  Copyright © 2016年 Emerys. All rights reserved.
//

#import "JKContactBook.h"
#import <AddressBook/AddressBook.h>
#ifdef __IPHONE_9_0
#import <Contacts/Contacts.h>
#endif
#import "JKContactModel.h"
#import "JKCommon.h"

#ifndef JK_iOS9Later
#define JK_iOS9Later ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"

@interface JKContactBook ()

@property (nonatomic,assign) int visitAddressBookByMethod;
@property (nonatomic,copy) GetContactBook block;
@property (nonatomic,copy) GetContactBookFailure failure;

@end

@implementation JKContactBook

+ (JKContactBook *)sharedContactBook {
    static JKContactBook *addressBook = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        addressBook = [[JKContactBook alloc] init];        
    });
    return addressBook;
}

- (void)requestAuthorization {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf requestAddressBookAuthorizationSuccess];
    });
    
}

- (void)requestAddressBookAuthorizationSuccess {
#ifdef __IPHONE_9_0
    if (JK_iOS9Later) {
        // 1.判断是否授权成功,若授权成功直接return
        if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized) return;
        // 2.创建通讯录
        CNContactStore *store = [[CNContactStore alloc] init];
        // 3.授权
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                NSLog(@"授权成功");
                
            }else{
                NSLog(@"授权失败");
            }
        }];
    }
    else
#endif
    {
        // 1.获取授权的状态
        ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
        
        // 2.判断授权状态,如果是未决定状态,才需要请求
        if (status == kABAuthorizationStatusNotDetermined) {
            
            // 3.创建通讯录进行授权
            ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                if (granted) {
                    NSLog(@"授权成功");
                    
                } else {
                    NSLog(@"授权失败");
                    
                }
            });
        }
        
    }
}

#pragma mark - utils

//过滤指定字符串(可自定义添加自己过滤的字符串)
- (NSString *)removeSpecialSubString: (NSString *)string {
    string = [string stringByReplacingOccurrencesOfString:@"+86" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"-" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"(" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@")" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    return string;
}

// 获取联系人姓名首字母(传入汉字字符串, 返回大写拼音首字母)
- (NSString *)getFirstLetterFromString:(NSString *)aString {
    NSMutableString *str = [NSMutableString stringWithString:aString];
    //带声调的拼音
    CFStringTransform((CFMutableStringRef)str,NULL, kCFStringTransformMandarinLatin,NO);
     NSLog(@"%@",str);
    //不带声调的拼音
    CFStringTransform((CFMutableStringRef)str,NULL, kCFStringTransformStripDiacritics,NO);
    //转化为大写拼音
    NSString *strPinYin = [str capitalizedString];
   
    NSString *firstString = [strPinYin substringToIndex:1];
    //判断姓名首位是否为大写字母
    NSString * regexA = @"^[A-Z]$";
    NSPredicate *predA = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexA];
    //获取并返回首字母
    return [predA evaluateWithObject:firstString] ? firstString : @"#";
}

- (void)sortedContactBook:(GetContactBook)block failure:(GetContactBookFailure)failure{
    
    self.visitAddressBookByMethod = 0;
    self.block = block;
    self.failure = failure;
    
    __block NSMutableDictionary *addressBook = [NSMutableDictionary dictionary];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self addressBookData:addressBook failure:failure];
        
        [addressBook enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            [obj sortedArrayUsingComparator:^NSComparisonResult(JKContactModel  *obj1, JKContactModel  *obj2) {
                
                return [obj1.name localizedCompare:obj2.name];
                
            }];
            
        }];
        
        NSArray *sortedNameKeys = [addressBook.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [obj1 localizedCompare:obj2];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            block ? block(addressBook,sortedNameKeys) : nil;
        });
        
    });
    
    
    
}

- (void)originalContactBook:(GetContactBook)block failure:(GetContactBookFailure)failure {
    
    self.visitAddressBookByMethod = 1;
    self.block = block;
    self.failure = failure;
    
    __block NSMutableDictionary *addressBook = [NSMutableDictionary dictionary];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [self addressBookData:addressBook failure:failure];
        dispatch_async(dispatch_get_main_queue(), ^{
            block ? block(addressBook,nil) : nil;
        });
    });
    
}

#pragma mark - get data

- (void)addressBookData:(NSMutableDictionary *)addressBookDict failure:(GetContactBookFailure)failure {

    if (JK_iOS9Later) {
        [self iOS_9_later_addressBookData:addressBookDict failure:failure];
    } else {
        [self iOS_9_ago_addressBookData:addressBookDict failure:failure];
    }
    
}

- (void)addAddress:(JKContactModel *)model toAddressBook:(NSMutableDictionary *)addressBookDict {
    
//    NSLog(@"%@",model.name);
    //获取到姓名的大写首字母
    NSString *firstLetterString = [self getFirstLetterFromString:model.name];
    
    //如果该字母对应的联系人模型不为空,则将此联系人模型添加到此数组中
    if (addressBookDict[firstLetterString])
    {
        [addressBookDict[firstLetterString] addObject:model];
    }
    //没有出现过该首字母，则在字典中新增一组key-value
    else
    {
        //创建新发可变数组存储该首字母对应的联系人模型
        NSMutableArray *arrGroupNames = [NSMutableArray arrayWithObject:model];
        //将首字母-姓名数组作为key-value加入到字典中
        [addressBookDict setObject:arrGroupNames forKey:firstLetterString];
    }

    
}

- (void)iOS_9_ago_addressBookData:(NSMutableDictionary *)addressBookDict failure:(GetContactBookFailure)failure{
    // 1.获取授权状态
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    
    // 2.如果没有授权,先执行授权失败的block后return
    if (status != kABAuthorizationStatusAuthorized/** 已经授权*/)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            failure ? failure() : nil;
        });
        return;
    }
    
    // 3.创建通信录对象
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    // 4.从通信录对象中,将所有的联系人拷贝出来
    CFArrayRef allPeopleArray = ABAddressBookCopyArrayOfAllPeople(addressBook);
    
    // 5.遍历每个联系人的信息,并装入模型
    for(id personInfo in (__bridge NSArray *)allPeopleArray)
    {
        JKContactModel *model = [JKContactModel new];
        // 5.1获取到联系人
        ABRecordRef person = (__bridge ABRecordRef)(personInfo);
        // 5.2获取姓名
        NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        NSString *middleName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
        NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        
        NSString *name = [NSString stringWithFormat:@"%@%@%@",lastName?lastName:@"",middleName?middleName:@"",firstName?firstName:@""];
        model.name = name.length > 0 ? name : @"无名氏" ;
        
        // 5.3获取头像数据
        NSData *imageData = (__bridge_transfer NSData *)ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
        model.header = [UIImage imageWithData:imageData];
        
        // 5.4获取每个人所有的电话号码
        ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
        
        CFIndex phoneCount = ABMultiValueGetCount(phones);
        for (CFIndex i = 0; i < phoneCount; i++)
        {
            NSString *phoneValue = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, i);           //号码
            NSString *mobile = [self removeSpecialSubString:phoneValue];
            
            [model.phone addObject: mobile ? mobile : @"空号"];
            
            NSString *localizedPhoneTypeString = (__bridge NSString *)(ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(phones, i)));
            NSLog(@"%@: %@",localizedPhoneTypeString,mobile);
            
        }
        // 5.5将联系人模型回调出去
        [self addAddress:model toAddressBook:addressBookDict];
        
        CFRelease(phones);
    }
    
    // 释放不再使用的对象
    CFRelease(allPeopleArray);
    CFRelease(addressBook);
}



- (void)iOS_9_later_addressBookData:(NSMutableDictionary *)addressDict failure:(GetContactBookFailure)failure {
#ifdef __IPHONE_9_0
    // 1.获取授权状态
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    // 2.如果没有授权,先执行授权失败的block后return
    if (status != CNAuthorizationStatusAuthorized)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            failure ? failure() : nil;
        });
        return;
    };
    // 3.获取联系人
    // 3.1.创建联系人仓库
    CNContactStore *store = [[CNContactStore alloc] init];
    
    // 3.2.创建联系人的请求对象
    // keys决定能获取联系人哪些信息,例:姓名,电话,头像等
    NSArray *fetchKeys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactMiddleNameKey,CNContactPhoneNumbersKey,CNContactThumbnailImageDataKey];
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:fetchKeys];
    
    // 3.3.请求联系人
    NSError *error = nil;
    [store enumerateContactsWithFetchRequest:request error:&error usingBlock:^(CNContact * _Nonnull contact,BOOL * _Nonnull stop) {
        
        // 姓名
        NSString *lastName = contact.familyName;
        NSString *middleName = contact.middleName;
        NSString *firstName = contact.givenName;
        
        // 创建联系人模型
        JKContactModel *model = [JKContactModel new];
        NSString *name = [NSString stringWithFormat:@"%@%@%@",lastName?lastName:@"",middleName?middleName:@"",firstName?firstName:@""];
        model.name = name.length > 0 ? name : @"#" ;
        
        // 联系人头像
        model.header = [UIImage imageWithData:contact.thumbnailImageData];
        
        // 获取一个人的所有电话号码
        NSArray *phones = contact.phoneNumbers;
        
        for (CNLabeledValue *labelValue in phones)
        {
            CNPhoneNumber *phoneNumber = labelValue.value;
            NSString *mobile = [self removeSpecialSubString:phoneNumber.stringValue];
            [model.phone addObject: mobile ? mobile : @""];
            
            NSString *localizedPhoneTypeString = [CNLabeledValue localizedStringForLabel:labelValue.label];
            NSLog(@"%@: %@",localizedPhoneTypeString,mobile);
        }
        
        [self addAddress:model toAddressBook:addressDict];
        
    }];
#endif
}

#pragma mark - Add Contact

- (void)addContact:(JKContactModel *)contact {
    
    if (JK_iOS9Later) {
        [self iOS_9_later_addContact:contact];
    } else {
        [self iOS_9_ago_addContact:contact];
    }
    
}

- (void)iOS_9_ago_addContact:(JKContactModel *)contact {
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    ABRecordRef newPerson = ABPersonCreate();
    CFErrorRef error = NULL;
    // 设置单值属性
    ABRecordSetValue(newPerson, kABPersonFirstNameProperty, @"Pei", &error);
    ABRecordSetValue(newPerson, kABPersonLastNameProperty, @"Lee", &error);
    ABRecordSetValue(newPerson, kABPersonOrganizationProperty, @"US", &error);
    ABRecordSetValue(newPerson, kABPersonJobTitleProperty, @"Manager", &error);
    
    // 设置多值属性
    // 电话（邮箱类似）
    ABMutableMultiValueRef phoneMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType); // 指明保存到数据类型String
    ABMultiValueAddValueAndLabel(phoneMultiValue, @"1382556560", kABPersonPhoneMainLabel, NULL);
    ABMultiValueAddValueAndLabel(phoneMultiValue, @"1392652590", kABPersonPhoneMobileLabel, NULL);
    ABMultiValueAddValueAndLabel(phoneMultiValue, @"1378753580", kABPersonPhoneIPhoneLabel, NULL);
    
    ABRecordSetValue(newPerson, kABPersonPhoneProperty, phoneMultiValue, &error);
    
    // 地址
    ABMultiValueRef addrMultiValue = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType); // 指明保存到数据类型Dictionary
    NSMutableDictionary *addrDic = [NSMutableDictionary dictionary];
    [addrDic setObject:@"水井坊 110号" forKey:(NSString *)kABPersonAddressStreetKey];
    [addrDic setObject:@"成都" forKey:(NSString *)kABPersonAddressCityKey];
    [addrDic setObject:@"四川" forKey:(NSString *)kABPersonAddressStateKey];
    [addrDic setObject:@"中国" forKey:(NSString *)kABPersonAddressCountryKey];
    
    ABMultiValueAddValueAndLabel(addrMultiValue, (__bridge CFTypeRef)addrDic, kABWorkLabel, NULL);
    ABRecordSetValue(newPerson, kABPersonAddressProperty, addrMultiValue, &error);
    
    // 保存
    ABAddressBookAddRecord(addressBook, newPerson, &error);
    ABAddressBookSave(addressBook, &error);
}

- (void)iOS_9_later_addContact:(JKContactModel *)model {
#ifdef __IPHONE_9_0
    
    CNContactStore *store = [[CNContactStore alloc] init];
    CNSaveRequest *request = [[CNSaveRequest alloc] init];
    
    CNMutableContact *contact = [[CNMutableContact alloc] init];
    contact.givenName = @"Pei";
    contact.familyName = @"Lee";
    contact.organizationName = @"US";
    contact.jobTitle = @"Manager";
    
    // 单值
    CNPhoneNumber *phone_0 = [CNPhoneNumber phoneNumberWithStringValue:@"1382556560"];
    CNPhoneNumber *phone_1 = [CNPhoneNumber phoneNumberWithStringValue:@"1392652590"];
    CNPhoneNumber *phone_2 = [CNPhoneNumber phoneNumberWithStringValue:@"1378753580"];
    CNLabeledValue *main_labeled_phone = [[CNLabeledValue alloc] initWithLabel:CNLabelPhoneNumberMain value:phone_0];
    CNLabeledValue *mobile_labeled_phone = [[CNLabeledValue alloc] initWithLabel:CNLabelPhoneNumberMobile value:phone_1];
    CNLabeledValue *iphone_labeled_phone = [[CNLabeledValue alloc] initWithLabel:CNLabelPhoneNumberiPhone value:phone_2];
    
    contact.phoneNumbers = @[main_labeled_phone,mobile_labeled_phone,iphone_labeled_phone];
    
    // 多值
    CNMutablePostalAddress *address = [[CNMutablePostalAddress alloc] init];
    address.street = @"水井坊 110号";
    address.city = @"成都";
    address.state = @"四川";
    address.country = @"中国";
    CNLabeledValue *labeld_addr = [[CNLabeledValue alloc] initWithLabel:CNLabelWork value:address];
    
    contact.postalAddresses = @[labeld_addr];
    
    [request addContact:contact toContainerWithIdentifier:nil];
    [store executeSaveRequest:request error:nil];
    
#endif
}

@end

#pragma clang diagnostic pop
