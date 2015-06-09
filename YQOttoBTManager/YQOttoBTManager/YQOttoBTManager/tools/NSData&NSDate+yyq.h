//
//  NSData+yyq.h
//  HealtKitTest
//
//  Created by yyq on 15/1/19.
//  Copyright (c) 2015年 mobilenow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (yyq)
//将传入的NSString类型转换成NSData并返回
+ (NSData*)dataWithHexstring:(NSString *)hexstring;

//将传入的NSData类型转换成NSString并返回
+ (NSString*)hexadecimalString:(NSData *)data;
@end



/****************************************************华丽的分割线**********************************************************/



@interface NSDate (yyq)

/**********************************************************
 *@Description:获取当天的包括“年”，“月”，“日”，“周”，“时”，“分”，“秒”的NSDateComponents
 *@Params:nil
 *@Return:当天的包括“年”，“月”，“日”，“周”，“时”，“分”，“秒”的NSDateComponents
 ***********************************************************/
- (NSDateComponents *)componentsOfDay;


- (NSInteger)weekdayOrdinal;

/****************************************************
 *@Description:获得NSDate对应的年份
 *@Params:nil
 *@Return:NSDate对应的年份
 ****************************************************/
- (NSUInteger)year;

/****************************************************
 *@Description:获得NSDate对应的月份
 *@Params:nil
 *@Return:NSDate对应的月份
 ****************************************************/
- (NSUInteger)month;


/****************************************************
 *@Description:获得NSDate对应的日期
 *@Params:nil
 *@Return:NSDate对应的日期
 ****************************************************/
- (NSUInteger)day;


/****************************************************
 *@Description:获得NSDate对应的小时数
 *@Params:nil
 *@Return:NSDate对应的小时数
 ****************************************************/
- (NSUInteger)hour;


/****************************************************
 *@Description:获得NSDate对应的分钟数
 *@Params:nil
 *@Return:NSDate对应的分钟数
 ****************************************************/
- (NSUInteger)minute;


/****************************************************
 *@Description:获得NSDate对应的秒数
 *@Params:nil
 *@Return:NSDate对应的秒数
 ****************************************************/
- (NSUInteger)second;

/****************************************************
 *@Description:获得NSDate对应的星期
 *@Params:nil
 *@Return:NSDate对应的星期
 ****************************************************/
- (NSUInteger)weekday;

/****************************************************
 *@Description:获得NSDate对应的周数
 *@Params:nil
 *@Return:NSDate对应的周数
 ****************************************************/
- (NSUInteger)week;

//是否同一天
- (BOOL)isSameDayWithDate:(NSDate*)date;

/**
 *  将NSDate转换成16进制 年/月/日/星期几/时区/时/分/秒
 */
+ (NSString*)string16WithDate:(NSDate*)date;

/**
 *  将NSDate转换成16进制 年/月/日
 */
+ (NSString*)stringDay16WithDate:(NSDate*)date;


/**
 *  将16进制字符串转换成NSDate
 */
+ (NSDate*)dateOfStringFormatyyyyMMddwwzzHHmmss:(NSString*)dateStr;


/**
 *  本地时区(1Byte)的bit7=1表示负时差,bit7=0表示正时差。时差数的绝对值放在本地时区(1Byte)里面。以格林威治时间为参考标准。
 */
+ (NSString*)hexStringWithSystemTimezone;


/**
 *  根据那天的16进制时间节点返回NSDate
 */
+ (NSDate*)dateWithTimeNote:(NSString*)timeNoteStr ThatDate:(NSDate*)thatDate isSecond:(BOOL)isSecond;

/**
 *  根据16进制字符串返回NSDate
 */
+ (NSDate*)dateWithHexDate:(NSString*)hexDateStr;

@end
