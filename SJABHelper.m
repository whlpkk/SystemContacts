//
//  SJABHelper.m
//  GroupContract
//
//  Created by yzk on 3/12/14.
//

#import "SJABHelper.h"
#import "User.h"
#import "Encryption.h"

@implementation SJABHelper

// 单列模式
+ (SJABHelper*)shareControl {
    static SJABHelper *instance;
    @synchronized(self) {
        if(!instance) {
            instance = [[SJABHelper alloc] init];
        }
    }
    return instance;
}

+ (BOOL)addContactName:(NSString *)name phoneNum:(NSString *)num withLabel:(NSString *)label {
    return [[SJABHelper shareControl] addContactName:name phoneNum:num withLabel:label];
}

// 添加联系人（联系人名称、号码、号码备注标签）
- (BOOL)addContactName:(NSString *)name phoneNum:(NSString *)num withLabel:(NSString *)label {
    // 创建一条空的联系人
    ABRecordRef record = ABPersonCreate();
    CFErrorRef error;
    // 设置联系人的名字
    ABRecordSetValue(record, kABPersonFirstNameProperty, (__bridge CFTypeRef)name, &error);
    // 添加联系人电话号码以及该号码对应的标签名
    ABMutableMultiValueRef multi = ABMultiValueCreateMutable(kABPersonPhoneProperty);
    ABMultiValueAddValueAndLabel(multi, (__bridge CFTypeRef)num, (__bridge CFTypeRef)label, NULL);
    ABRecordSetValue(record, kABPersonPhoneProperty, multi, &error);
    
    ABAddressBookRef addressBook = nil;
    // 如果为iOS6以上系统，需要等待用户确认是否允许访问通讯录。
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0) {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     dispatch_semaphore_signal(sema);
                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    }
    else  {
        addressBook = ABAddressBookCreate();
    }
    // 将新建联系人记录添加如通讯录中
    BOOL success = ABAddressBookAddRecord(addressBook, record, &error);
    if (!success) {
        return NO;
    }else{
    // 如果添加记录成功，保存更新到通讯录数据库中
        success = ABAddressBookSave(addressBook, &error);
        return success ? YES : NO;
    }
}

+ (BOOL)addContactName:(User*) user {
    return [[SJABHelper shareControl] addContactName:user];
}

// 添加联系人（联系人名称、号码、号码备注标签）
- (BOOL)addContactName:(User*) user {
    
    ABRecordRef record = nil;
    NSString * phoneNumber = user.user_cellphone.dencrptValue;
    if (phoneNumber != nil && ![@"" isEqualToString:phoneNumber]) {
       record = [self existPhone:phoneNumber];
    }
    if (record == nil) {
        phoneNumber = user.user_workcellphone.dencrptValue;
        if (phoneNumber != nil && ![@"" isEqualToString:phoneNumber]) {
            record = [self existPhone:phoneNumber];
        }
    }
    if (record == nil) {
        phoneNumber = user.user_telphone.dencrptValue;
        if (phoneNumber != nil && ![@"" isEqualToString:phoneNumber]) {
            record = [self existPhone:phoneNumber];
        }
    }
    if (record == nil) {
        phoneNumber = user.user_email.dencrptValue;
        if (phoneNumber != nil && ![@"" isEqualToString:phoneNumber]) {
            record = [self existPhone:phoneNumber];
        }
    }
    if (record != nil) {
        CFTypeRef companyRef = ABRecordCopyValue(record, kABPersonOrganizationProperty);
        NSString *companyName = [NSString stringWithFormat:@"%@", companyRef];
        if ([@"(null)" isEqualToString:companyName]) {
            record = nil;
        }
    }
    // 创建一条空的联系人
    if (record == nil) {
        record = ABPersonCreate();
    }
    CFErrorRef error;
    

    ABRecordSetValue(record, kABPersonOrganizationProperty, (__bridge CFTypeRef)(user.user_companyName.dencrptValue), NULL);
    ABRecordSetValue(record, kABPersonDepartmentProperty, (__bridge CFTypeRef)(user.user_defaultOrgName.dencrptValue), NULL);
    // 设置联系人的名字
    ABRecordSetValue(record, kABPersonFirstNameProperty, (__bridge CFTypeRef)[user.user_name dencrptValue], &error);
    // 添加联系人电话号码以及该号码对应的标签名
    ABMutableMultiValueRef multi = ABMultiValueCreateMutable(kABPersonPhoneProperty);
    phoneNumber = user.user_workcellphone;
    if (phoneNumber && ![phoneNumber isEqualToString:@""]) {
        ABMultiValueAddValueAndLabel(multi, (__bridge CFTypeRef)[phoneNumber dencrptValue],kABPersonPhoneMobileLabel, NULL);
    }
    
    phoneNumber = user.user_cellphone;
    if (phoneNumber && ![phoneNumber isEqualToString:@""]) {
        ABMultiValueAddValueAndLabel(multi, (__bridge CFTypeRef)[phoneNumber dencrptValue], kABPersonPhoneMobileLabel, NULL);
    }


    phoneNumber = user.user_telphone;
    if (phoneNumber && ![phoneNumber isEqualToString:@""]) {
        ABMultiValueAddValueAndLabel(multi, (__bridge CFTypeRef)[phoneNumber dencrptValue], kABOtherLabel, NULL);
    }
    
    
    ABRecordSetValue(record, kABPersonPhoneProperty, multi, &error);
    
    ABMutableMultiValueRef addr=ABMultiValueCreateMutable(kABStringPropertyType);
    ABMultiValueAddValueAndLabel(addr, (__bridge CFTypeRef)[user.user_email dencrptValue] ,kABWorkLabel ,NULL);
    ABRecordSetValue(record,kABPersonEmailProperty, addr, NULL);
    
    ABAddressBookRef addressBook = nil;
    // 如果为iOS6以上系统，需要等待用户确认是否允许访问通讯录。
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0) {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     dispatch_semaphore_signal(sema);
                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
    }
    else  {
        addressBook = ABAddressBookCreate();
    }
    // 将新建联系人记录添加如通讯录中
    BOOL success = ABAddressBookAddRecord(addressBook, record, &error);
    if (!success) {
        return NO;
    }else{
        // 如果添加记录成功，保存更新到通讯录数据库中
        success = ABAddressBookSave(addressBook, &error);
        return success ? YES : NO;
    }
}

+(NSInteger)addContactNameArray:(NSArray*) userArray {
    int count = 0;
    for (User *user in userArray) {
        
        BOOL success = [[SJABHelper shareControl] addContactName:user];
        if (success) {
            count++;
        }

    }
    return count;
}

+ (ABRecordRef)existPhone:(NSString *)phoneNum
{
    return [[SJABHelper shareControl] existPhone:phoneNum];
}

// 指定号码是否已经存在
- (ABRecordRef)existPhone:(NSString*)phoneNum
{
    ABAddressBookRef addressBook = nil;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
    {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     dispatch_semaphore_signal(sema);
                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    }
    else
    {
        addressBook = ABAddressBookCreate();
    }
    CFArrayRef records;
    if (addressBook) {
    // 获取通讯录中全部联系人
        records = ABAddressBookCopyArrayOfAllPeople(addressBook);
    }else{
        return nil;
    }
    
    // 遍历全部联系人，检查是否存在指定号码
    for (int i=0; i<CFArrayGetCount(records); i++) {
        ABRecordRef record = CFArrayGetValueAtIndex(records, i);
        CFTypeRef items = ABRecordCopyValue(record, kABPersonPhoneProperty);
        CFArrayRef phoneNums = ABMultiValueCopyArrayOfAllValues(items);
        if (phoneNums) {
            for (int j=0; j<CFArrayGetCount(phoneNums); j++) {
                NSString *phone = (NSString*)CFArrayGetValueAtIndex(phoneNums, j);
                if ([phone isEqualToString:phoneNum]) {
                    return record;
                    CFRelease(addressBook);
                }
            }
        }
    }
    
    CFRelease(addressBook);
    return nil;
}

@end
