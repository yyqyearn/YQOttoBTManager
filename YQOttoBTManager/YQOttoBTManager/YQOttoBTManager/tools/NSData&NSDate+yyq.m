//
//  NSData+yyq.m
//  HealtKitTest
//
//  Created by yyq on 15/1/19.
//  Copyright (c) 2015年 mobilenow. All rights reserved.
//

#import "NSData&NSDate+yyq.h"

@implementation NSData (yyq)
//将传入的NSString类型转换成NSData并返回
+ (NSData*)dataWithHexstring:(NSString *)hexstring{
    NSMutableData* data = [NSMutableData data];
    int idx;
    for(idx = 0; idx + 2 <= hexstring.length; idx += 2){
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [hexstring substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
       NSString *sendBy = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
//    NSLog(@"发送的2进制为%@ ,data = %@",sendBy,data);
    return data;
}
//将传入的NSData类型转换成NSString并返回
+ (NSString*)hexadecimalString:(NSData *)data{
    NSString* result;
    const unsigned char* dataBuffer = (const unsigned char*)[data bytes];
    if(!dataBuffer){
        return nil;
    }
    NSUInteger dataLength = [data length];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for(int i = 0; i < dataLength; i++){
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    result = [NSString stringWithString:hexString];
    return result;
}

@end


/****************************************************华丽的分割线**********************************************************/


@implementation NSDate (yyq)
/**********************************************************
 *@Description:获取当天的包括“年”，“月”，“日”，“周”，“时”，“分”，“秒”的NSDateComponents
 *@Params:nil
 *@Return:当天的包括“年”，“月”，“日”，“周”，“时”，“分”，“秒”的NSDateComponents
 ***********************************************************/
- (NSDateComponents *)componentsOfDay
{
    static NSDateComponents *dateComponents = nil;
    static NSDate *previousDate = nil;
    
    if (!previousDate || ![previousDate isEqualToDate:self]) {
        previousDate = self;
        dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal | NSWeekCalendarUnit| NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:self];
    }
    
    return dateComponents;
}


//  --------------------------NSDate---------------------------
- (NSInteger)weekdayOrdinal
{
    return self.weekdayOrdinal;
}


/****************************************************
 *@Description:获得NSDate对应的年份
 *@Params:nil
 *@Return:NSDate对应的年份
 ****************************************************/
- (NSUInteger)year
{
    return [self componentsOfDay].year;
}

/****************************************************
 *@Description:获得NSDate对应的月份
 *@Params:nil
 *@Return:NSDate对应的月份
 ****************************************************/
- (NSUInteger)month
{
    return [self componentsOfDay].month;
}


/****************************************************
 *@Description:获得NSDate对应的日期
 *@Params:nil
 *@Return:NSDate对应的日期
 ****************************************************/
- (NSUInteger)day
{
    return [self componentsOfDay].day;
}


/****************************************************
 *@Description:获得NSDate对应的小时数
 *@Params:nil
 *@Return:NSDate对应的小时数
 ****************************************************/
- (NSUInteger)hour
{
    return [self componentsOfDay].hour;
}


/****************************************************
 *@Description:获得NSDate对应的分钟数
 *@Params:nil
 *@Return:NSDate对应的分钟数
 ****************************************************/
- (NSUInteger)minute
{
    return [self componentsOfDay].minute;
}


/****************************************************
 *@Description:获得NSDate对应的秒数
 *@Params:nil
 *@Return:NSDate对应的秒数
 ****************************************************/
- (NSUInteger)second
{
    return [self componentsOfDay].second;
}

/****************************************************
 *@Description:获得NSDate对应的星期
 *@Params:nil
 *@Return:NSDate对应的星期
 ****************************************************/
- (NSUInteger)weekday
{
    return [self componentsOfDay].weekday;
}

/****************************************************
 *@Description:获得NSDate对应的周数
 *@Params:nil
 *@Return:NSDate对应的周数
 ****************************************************/
- (NSUInteger)week
{
    return [self componentsOfDay].week;
}

//是否同一天
- (BOOL)isSameDayWithDate:(NSDate*)date{
    if ((self.year==date.year)&&(self.month==date.month)&&(self.day==date.day)) {
        return YES;
    }else{
        return NO;
    }
}


+ (NSString*)string16WithDate:(NSDate*)date
{
    
    NSString * string = [NSString stringWithFormat:@"0%02lx",(unsigned long)date.year];
    string =  [string stringByAppendingString:[NSString stringWithFormat:@"%02lx",(unsigned long)date.month]];
    string =  [string stringByAppendingString:[NSString stringWithFormat:@"%02lx",(unsigned long)date.day]];
    string =  [string stringByAppendingString:[NSString stringWithFormat:@"%02lx",(unsigned long)date.weekday]];
    string =[string stringByAppendingString:[NSDate hexStringWithSystemTimezone]];
    string =  [string stringByAppendingString:[NSString stringWithFormat:@"%02lx",(unsigned long)date.hour]];
    string =  [string stringByAppendingString:[NSString stringWithFormat:@"%02lx",(unsigned long)date.minute]];
    string =  [string stringByAppendingString:[NSString stringWithFormat:@"%02lx",(unsigned long)date.second]];
    
    //    NSLog(@"sysZOne = %li, TZ = %ld",timezone,(long)timeZone.secondsFromGMT);
    return string;
}

+ (NSString*)stringDay16WithDate:(NSDate*)date
{
    NSString * string = [NSString stringWithFormat:@"0%02lx",(unsigned long)date.year];
    string =  [string stringByAppendingString:[NSString stringWithFormat:@"%02lx",(unsigned long)date.month]];
    string =  [string stringByAppendingString:[NSString stringWithFormat:@"%02lx",(unsigned long)date.day]];
    //    NSLog(@"sysZOne = %li, TZ = %ld",timezone,(long)timeZone.secondsFromGMT);
    return string;
}


+ (NSString*)hexStringWithSystemTimezone
{
    NSString * string;
    NSTimeZone * timeZone = [NSTimeZone systemTimeZone];
    NSInteger ZoneInt = timeZone.secondsFromGMT/3600;
    if (ZoneInt<0) {
        string =[NSString stringWithFormat:@"1%lx",-ZoneInt];
    }else{
        string = [NSString stringWithFormat:@"%02lx",ZoneInt];
    }
    return string;
}

+ (NSDate*)dateOfStringFormatyyyyMMddwwzzHHmmss:(NSString*)dateStr
{
    if (dateStr.length!=18) {
        NSLog(@"日期格式错误");
        return nil;
    }
    NSString *yearHex =[dateStr substringWithRange:NSMakeRange(0, 4)];
    //    yearHex = yearHex //[NSDate stringFromHexString:yearHex];
    NSUInteger year = strtoul([yearHex UTF8String],0,16);
    //    -(NSInteger *)hex:(UITextField *)textField3
    //    {
    //
    //        cellLabel.text= strtoul([textField3.text UTF8String],0,16);
    //    }
    
    
    NSString *monthHex = [dateStr substringWithRange:NSMakeRange(4, 2)];
    NSUInteger month = strtoul([monthHex UTF8String],0,16);
    
    NSString *dayHex = [dateStr substringWithRange:NSMakeRange(6, 2)];
    NSUInteger day = strtoul([dayHex UTF8String],0,16);
    
    NSString *weekHex = [dateStr substringWithRange:NSMakeRange(8, 2)];
    NSUInteger weekday = strtoul([weekHex UTF8String],0,16);
    
    NSString *zoneHex = [dateStr substringWithRange:NSMakeRange(10, 2)];
    NSTimeZone * timeZone = [NSTimeZone systemTimeZone];
    
    NSString *hourHex = [dateStr substringWithRange:NSMakeRange(12, 2)];
    NSUInteger hour = strtoul([hourHex UTF8String],0,16);
    
    NSString *minuteHex = [dateStr substringWithRange:NSMakeRange(14, 2)];
    NSUInteger minute = strtoul([minuteHex UTF8String],0,16);
    
    NSString *secondHex = [dateStr substringWithRange:NSMakeRange(16, 2)];
    NSUInteger second = strtoul([secondHex UTF8String],0,16);
    
    NSDateComponents *  dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:[NSDate date]];
    //    + (NSDate*)dateOfStringFormatyyyyMMddwwzzHHmmss:(NSString*)dateStr
    
    dateComponents.year = year;
    dateComponents.month = month;
    dateComponents.day = day;
    //    dateComponents.timeZone = timeZone;
    dateComponents.hour = hour;
    dateComponents.minute = minute;
    dateComponents.second = second;
    
    return [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
}

/**
 *  将16进制字符串转换成10进制 失效
 */
+ (NSString *)stringFromHexString:(NSString *)hexString { //
    
    char *myBuffer = (char *)malloc((int)[hexString length] / 2 + 1);
    bzero(myBuffer, [hexString length] / 2 + 1);
    for (int i = 0; i < [hexString length] - 1; i += 2) {
        unsigned int anInt;
        NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        myBuffer[i / 2] = (char)anInt;
    }
    NSString *unicodeString = [NSString stringWithCString:myBuffer encoding:4];
    NSLog(@"------字符串=======%@",unicodeString);
    return unicodeString;
}


+ (NSDate*)dateWithTimeNote:(NSString*)timeNoteStr ThatDate:(NSDate*)thatDate isSecond:(BOOL)isSecond{
    int note = (int)strtoul([timeNoteStr UTF8String],0,16);
    if (isSecond) {
        note += 255;
    }
    NSInteger hour = note / 12;
    NSInteger minute = (note%12)*5;
    
    //    NSDate * date = thatDate;
    
    NSDateComponents *  dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:[NSDate date]];
    dateComponents.year = thatDate.year;
    dateComponents.month = thatDate.month;
    dateComponents.day = thatDate.day;
    dateComponents.hour = hour;
    dateComponents.minute = minute;
    dateComponents.second = 0;
    NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
    
    
    //    date = [[NSCalendar currentCalendar] dateBySettingHour:hour minute:minute second:0 ofDate:date options:0];
    
    return date;
}

+ (NSDate*)dateWithHexDate:(NSString*)hexDateStr{
    

    NSString * yearHS = [hexDateStr substringWithRange:NSMakeRange(0, 4)];
    NSString * monthHS = [hexDateStr substringWithRange:NSMakeRange(4, 2)];
    NSString * dayHS = [hexDateStr substringWithRange:NSMakeRange(6, 2)];
    
    NSInteger year = (int)strtoul([yearHS UTF8String],0,16);
    NSInteger month = (int)strtoul([monthHS UTF8String],0,16);
    NSInteger day = (int)strtoul([dayHS UTF8String],0,16);
    
    NSDateComponents *  dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:[NSDate date]];
    dateComponents.year = year;
    dateComponents.month = month;
    dateComponents.day = day;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
    
    //    NSDate * date = [[NSCalendar currentCalendar] dateWithEra:21 year:year month:month day:day hour:0 minute:0 second:0 nanosecond:0];
    return date;
}



@end
