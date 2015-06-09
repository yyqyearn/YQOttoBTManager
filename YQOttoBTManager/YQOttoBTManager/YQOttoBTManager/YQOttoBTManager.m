//
//  YQOttoBTManager.m
//  YQOttoBTManager
//
//  Created by yyq on 15/1/21.
//  Copyright (c) 2015年 mobilenow. All rights reserved.
//

//宏打印
#ifdef DEBUG
#define YYQLog(...) NSLog(__VA_ARGS__)
#else
#define YYQLog(...)
#endif


#import "YQOttoBTManager.h"
#import "NSData&NSDate+yyq.h"
/** 指令集 **/
static NSString *kCodeStr_Set12Hours = @"BE0101FE";
static NSString *kCodeStr_GetTime = @"BE0102ED";
static NSString *kCodeStr_SetTime = @"BE0102FE";
static NSString *kCodeStr_SetBTWork = @"BE0106FE";
static NSString *kCodeStr_RestoreFactory =@"BE010DED";
static NSString *kCodeStr_SetPetName = @"BE010EFE01";
static NSString *kCodeStr_SetMasterName = @"BE0112FE";
static NSString *kCodeStr_SetPhoneNumber = @"BE0113FE";
static NSString *kCodeStr_GetStepsH = @"BE0201FE";

/** 返回指令集 **/
static NSString *kReturnStr_Set12Hours = @"de0101ed";
static NSString *kReturnStr_GetTime = @"de0102fb";
static NSString *kReturnStr_SetTime = @"de0102ed";
static NSString *kReturnStr_SetBTWork = @"de0106ed";
static NSString *kReturnStr_RestoreFactory =@"de010ded";
static NSString *kReturnStr_SetPetName = @"de010eed";
static NSString *kReturnStr_SetMasterName = @"de0112ed";
static NSString *kReturnStr_SetPhoneNumber = @"de0113ed";

static NSString *kReturnStr_GetTodayStepsStart = @"20";
static NSString *kReturnStr_GetStepsH = @"de0201ed";
static NSString *kReturnStr_GetNoStepsH = @"de020106";


static NSString * kServiceUUIDs = @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E";


@interface YQOttoBTManager()<CBCentralManagerDelegate,CBPeripheralDelegate>

/**已寻找到的设备，为数组*/
@property (nonatomic, strong) NSMutableArray * PeripheralsFound;

/**已连接的外围设备*/
@property (nonatomic, strong) CBPeripheral * curPeripheral;
@property (nonatomic, strong) CBCentralManager *cbManager;

//服务种类
@property (nonatomic, strong) CBCharacteristic *settingsCh;
@property (nonatomic, strong) CBCharacteristic *valuesCh;

//@property (nonatomic, strong) NSMutableData *recvData;
//@property (nonatomic,assign)int seving;

//返回数据集合
@property (nonatomic, strong,readonly) NSArray * returnCodeArray;
@property (nonatomic, strong,readonly) NSArray * logArray;
@property (nonatomic, strong) NSTimer * timer;
@property (nonatomic,assign,getter=isSyncing)BOOL syncing;
@property (nonatomic,assign,getter=isHistory)BOOL history;

/** 同步获得的日期，为0点0分 */
@property (nonatomic, strong) NSDate *tarDate;

@property (nonatomic,copy) NSString *historyStepsStr;

@property (nonatomic, strong) NSDate *historyDate;


@end
@implementation YQOttoBTManager



#pragma mark - 公用方法
+ (instancetype)sharedManager
{
    static YQOttoBTManager *manager;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        manager = [[YQOttoBTManager alloc] init];
        manager.cbManager = [[CBCentralManager alloc ]initWithDelegate:manager queue:nil];
        manager.PeripheralsFound = [NSMutableArray array];
        [manager setupVersionAndArrays];
    });
    
    return manager;
}
/**
 *  搜索设备
 */
- (void)scanDevicesWithDuration:(float)duration;
{
    YYQLog(@"开始设备寻找,时间为:%f秒",duration);
    self.timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(scanTimeout:) userInfo:nil repeats:NO];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
    [self.cbManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kServiceUUIDs]] options:options];
}


#pragma mark - 私有方法
- (void)setupVersionAndArrays
{
    _returnCodeArray = @[kReturnStr_RestoreFactory,kReturnStr_SetBTWork,kReturnStr_SetMasterName,kReturnStr_SetPetName,kReturnStr_SetPhoneNumber,kReturnStr_SetTime,kReturnStr_Set12Hours];
    _logArray = @[@"返回出厂设置成功",@"设置启动时间成功",@"设置主人名字成功",@"设置宠物名字成功",@"设置手机号码成功",@"设置时间成功",@"设置12/24小时制成功"];
    _version = 1.0;
}

- (void)writeDataWithString:(NSString*)string Characteristic:(CBCharacteristic*)characteristic
{
    
    if (self.isSyncing) {
        YYQLog(@"正在同步，不允许其他操作");
        return;
    }
    if (self.curPeripheral && self.settingsCh) {
        [self.curPeripheral writeValue:[NSData dataWithHexstring:string] forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }else{
        YYQLog(@"没有连接到设备，设置个毛啊， =,=!!");
    }
}
- (void)scanTimeout:(NSTimer*)timer{
    [timer invalidate];
    self.timer = nil;
    if (self.cbManager) {
        [self.cbManager stopScan];
    }
    if (self.PeripheralsFound.count) {
        YYQLog(@"搜索到%lu台设备,列表参见代理方法",(unsigned long)self.PeripheralsFound.count);
        if ([self.delegate respondsToSelector:@selector(ottoBTManager:didFoundDevicesWithNames:identifiers:)]) {
            //将搜索结果发送给代理
            NSMutableArray * names = [NSMutableArray array];
            NSMutableArray * IDs = [NSMutableArray array];
            for (CBPeripheral *peripheral in self.PeripheralsFound) {
                [names addObject:peripheral.name];
                [IDs addObject:peripheral.identifier.UUIDString];
            }
            [self.delegate ottoBTManager:self didFoundDevicesWithNames:names identifiers:IDs];
        }
    }else{//没有设备
//        [self.delegate ottoBTManager:self didFoundDeviceWithName:nil identifier:nil];
        if ([self.delegate respondsToSelector:@selector(ottoBTManager:didFoundDevicesWithNames:identifiers:)]) {
        [self.delegate ottoBTManager:self didFoundDevicesWithNames:nil identifiers:nil];
        }
        YYQLog(@"No Peripheral Found! 没有搜索到设备");
    }
    YYQLog(@"scanTimesUp");
}
/**
 *  设置定时启动
 */
- (void)setAutoBT
{
    NSString * str = kCodeStr_SetBTWork;
    str = [str stringByAppendingString:@"02"];//定时启动
    //早上7点到晚上9点，每整点启动一次
    NSArray * numbers = @[@7,@8,@9,@10,@11,@12,@13,@14,@15,@16,@17,@18,@19,@20,@21];
    for (int i = 0; i<numbers.count; i++) {
        NSNumber *number = numbers[i];
        NSString * ASCIIstr = [NSString stringWithFormat:@"%02x",[number intValue]];
        str = [str stringByAppendingString:ASCIIstr];
    }
    [self writeDataWithString:str Characteristic:self.settingsCh];
}


#pragma mark - 设备操纵

/**
 *  连接设备
 */
- (void)connectWithDeviceID:(NSString*)ID
{
    if (self.timer) {
        [self.cbManager stopScan];
    }
    BOOL found = NO;
    for (CBPeripheral *peripheral in self.PeripheralsFound) {
        if ([peripheral.identifier.UUIDString isEqualToString:ID]) {
            [self.cbManager connectPeripheral:peripheral options:nil];
//            float duration = 3;
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                if (!self.isConnected) {
//                    YYQLog(@"连接超时，请再扫描");
//                    [self.cbManager cancelPeripheralConnection:peripheral];
//                    if ([self.delegate respondsToSelector:@selector(ottoBTManager:didConnectWithDevicelName:ID:)]) {
//                        [self.delegate ottoBTManager:self didConnectWithDevicelName:nil ID:nil];
//                    }
//                }
//            });
            found = YES;
            break;
        }
    }
    if (found==NO) {
        YYQLog(@"没有找到需要连接的设备,请先扫描");
        if ([self.delegate respondsToSelector:@selector(ottoBTManager:didConnectWithDevicelName:ID:)]) {
            [self.delegate ottoBTManager:nil didConnectWithDevicelName:nil ID:nil];
        }
    }
}  

/**
 *  断开连接
 */
- (void)disConnectWithDevice
{
    [self.cbManager cancelPeripheralConnection:self.curPeripheral];
}

/**
 *  立即停止扫描
 */
- (void)stopScanDevices
{
//    [self scanTimeout:self.timer];
    [self.cbManager stopScan];
//    [self.PeripheralsFound removeAllObjects];

}

/**
 * 公/英制,12H/24H制: 在APP第一次运行时,弹出对话框,要求用户选择
 */
- (void)setIs12Hours:(BOOL)is12Hours andIsBritich:(BOOL)isBritich
{
    NSString *str = kCodeStr_Set12Hours;
    NSString *subStr =[NSString stringWithFormat:@"0%i0%i%@",isBritich,is12Hours,[NSDate hexStringWithSystemTimezone]];
    str = [str stringByAppendingString:subStr];
    [self writeDataWithString:str Characteristic:self.settingsCh];
}

/**
 *  获得时间
 */
- (void)getTimeAndBatteryLVOfDevice{
    NSString *str = kCodeStr_GetTime;
    [self writeDataWithString:str Characteristic:self.settingsCh];
//    [self setAutoBT];
}

/**
 *  写入时间
 */
- (void)setTimeOfDeviceWithDate:(NSDate*)date;
{
    if (date == nil) {
        date = [NSDate date];
    }
    NSString *str;
    str = [kCodeStr_SetTime stringByAppendingString:[NSDate string16WithDate:date]];
    YYQLog(@"%@",str);
//    str = @"BE0102FE200f011d0508173A11";
    [self writeDataWithString:str Characteristic:self.settingsCh];
}

/**
 *  还原出厂设置
 */
- (void)RestoreFactory
{
    NSString *str = kCodeStr_RestoreFactory;
    [self writeDataWithString:str Characteristic:self.settingsCh];
}

/**
 *  设置pet姓名
 */
- (void)setPetNameWithName:(NSString*)name
{
    if (name.length>15) {
        YYQLog(@"名字太长");
        return;
    }
    NSString *str = kCodeStr_SetPetName;
    for (int i = 0; i<name.length; i++) {
        int fName = [name characterAtIndex:i];
    NSString * ASCIIstr = [NSString stringWithFormat:@"%02x",fName];
       str = [str stringByAppendingString:ASCIIstr];
    }
    for (int j = 0; j<40;j++ ) {
        if (str.length<40) {
       str = [str stringByAppendingString:@"00"];
        }else{
            break;
        }
    }
    [self writeDataWithString:str Characteristic:self.settingsCh];
    YYQLog(@"%@",str);
}
/**
 *  设置主人姓名
 */
- (void)setMastNameWithName:(NSString*)name
{
    if (name.length>14) {
        YYQLog(@"名字太长");
        return;
    }
    NSString *count = [NSString stringWithFormat:@"%02lx",(unsigned long)name.length];
    NSString *str = [kCodeStr_SetMasterName stringByAppendingString:count];
    for (int i = 0; i<name.length; i++) {
        int fName = [name characterAtIndex:i];
        NSString * ASCIIstr = [NSString stringWithFormat:@"%02x",fName];
        str = [str stringByAppendingString:ASCIIstr];
    }
    for (int j = 0; j<40;j++ ) {
        if (str.length<40) {
            str = [str stringByAppendingString:@"00"];
        }else{
            break;
        }
    }
    [self writeDataWithString:str Characteristic:self.settingsCh];
    YYQLog(@"%@",str);
}

- (void)setPhoneNumberWithNumber:(NSString*)number
{
    if (number.length>14) {
        YYQLog(@"号码太长");
        return;
    }
    NSString *count = [NSString stringWithFormat:@"%02lx",number.length];
    NSString *str = [kCodeStr_SetPhoneNumber stringByAppendingString:count];
    for (int i = 0; i<number.length; i++) {
        int fName = [number characterAtIndex:i];
        NSString * ASCIIstr = [NSString stringWithFormat:@"%02x",fName];
        str = [str stringByAppendingString:ASCIIstr];
    }
    
    for (int j = 0; j<40;j++ ) {
        if (str.length<40) {
            str = [str stringByAppendingString:@"00"];
        }else{
            break;
        }
    }
    [self writeDataWithString:str Characteristic:self.settingsCh];
    YYQLog(@"%@",str);
}

- (void)getStepsWithDate:(NSDate*)date;{
    if ([date isSameDayWithDate:date]) {
        [self getStepsToday];
    }else{
        self.historyDate = date;
    NSString *str = kCodeStr_GetStepsH;
    self.history = YES;
    str = [str  stringByAppendingString:[NSDate stringDay16WithDate:date]];
//    str = @"BE0201FE200F0310";// 0f181a"
    str  = [str stringByAppendingString:@"00"];
        [self writeDataWithString:str Characteristic:self.settingsCh];
    }
}
/**
 *  当天数据
 */
- (void)getStepsToday
{
//    NSString *str = @"BE0203FE0000";
    NSString *str = kCodeStr_GetStepsH;
       NSString *dateStr = [NSDate stringDay16WithDate:[NSDate date]];
    str = [str stringByAppendingString:dateStr];
    str = [str stringByAppendingString:@"00"];

    [self writeDataWithString:str Characteristic:self.settingsCh];
}




#pragma mark - CBCentralManagerDelegate 蓝牙代理方法
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    NSMutableString* nsmstring=[NSMutableString stringWithString:@"UpdateState:"];
    BOOL isWork=FALSE;
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            [nsmstring appendString:@"Unknown\n"];
            break;
        case CBCentralManagerStateUnsupported:
            [nsmstring appendString:@"Unsupported\n"];
            break;
        case CBCentralManagerStateUnauthorized:
            [nsmstring appendString:@"Unauthorized\n"];
            break;
        case CBCentralManagerStateResetting:
            [nsmstring appendString:@"Resetting\n"];
            break;
        case CBCentralManagerStatePoweredOff:
            [nsmstring appendString:@"PoweredOff\n"];
            if (self.curPeripheral!=NULL){
                [central cancelPeripheralConnection:self.curPeripheral];
                YYQLog(@"设备断开连接");
            }
            break;
        case CBCentralManagerStatePoweredOn:
            [nsmstring appendString:@"PoweredOn\n"];
            isWork=TRUE;
            break;
        default:
            [nsmstring appendString:@"none\n"];
            break;
    }
    YYQLog(@"centralManagerDidUpdateState ,%@",nsmstring);
    
    
//        [delegate didUpdateState:isWork message:nsmstring getStatus:cManager.state];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    if (self.PeripheralsFound.count) { //设备数组里已有设备
        BOOL  added = NO;
        for (CBPeripheral *pre in self.PeripheralsFound) {
            if (![pre.identifier isEqual:peripheral.identifier]){
                continue;
            }else{
                added = YES;
                break;
            }
        }
        if (!added){
            YYQLog(@"找到设备：ID = %@",peripheral.identifier.UUIDString);
            [self.PeripheralsFound addObject:peripheral];
            if ([self.delegate respondsToSelector:@selector(ottoBTManager:didFoundDeviceWithName:identifier:)]) {
                [self.delegate ottoBTManager:self didFoundDeviceWithName:peripheral.name identifier:peripheral.identifier.UUIDString];
            }
        }
    }else{//设备数组为空
        YYQLog(@"找到设备：ID = %@",peripheral.identifier.UUIDString);
        [self.PeripheralsFound addObject:peripheral];
        if ([self.delegate respondsToSelector:@selector(ottoBTManager:didFoundDeviceWithName:identifier:)]) {
            [self.delegate ottoBTManager:self didFoundDeviceWithName:peripheral.name identifier:peripheral.identifier.UUIDString];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    YYQLog(@"设备连接成功！didConnectPeripheral: name = %@ , UUID = %@",peripheral.name,peripheral.identifier.UUIDString);
    peripheral.delegate = self;
    self.curPeripheral = peripheral;
    _connected = YES;
    //开始搜索设备提供的可用服务
//    YYQLog(@"start To Discover Services...");
    [peripheral discoverServices:nil];
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"%@",error.description);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    
    YYQLog(@"设备断开连接，error = %@",[error localizedDescription]);
    _connected = NO;
    self.curPeripheral = nil;
    self.syncing = NO;
}

#pragma mark - CBPeripheralDelegate
/**
 *  搜索到可用服务
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        YYQLog(@"Error discovering services: %@", [error localizedDescription]);
    }else{
        for (CBService *p in peripheral.services){
//            YYQLog(@"Service found with UUID: %@\n", p.UUID);
//            YYQLog(@"Start To Discover Characteristics...");
            [peripheral discoverCharacteristics:nil forService:p];
        }
    }
}


/**
 *  搜索到可用功能
 */
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
//    YYQLog(@"did Discover Characteristics For Service ,error = %@ \n service = %@",error,service);
    self.valuesCh = [service.characteristics firstObject];
    self.settingsCh = [service.characteristics lastObject];
    [self.curPeripheral setNotifyValue:YES forCharacteristic:self.settingsCh];
    [self.curPeripheral setNotifyValue:YES forCharacteristic:self.valuesCh];
//    YYQLog(@"搜索到特征 set = %@ , \nValue = %@",self.settingsCh,self.valuesCh);
    //通知代理，连接成功
    
    [[NSNotificationCenter defaultCenter]postNotificationName:@"discoverCharacteristics" object:@{@"name":peripheral.name,@"id":peripheral.identifier.UUIDString}];
    if ([self.delegate respondsToSelector:@selector(ottoBTManager:didConnectWithDevicelName:ID:)]) {
       
        [self.delegate ottoBTManager:self didConnectWithDevicelName:peripheral.name ID:peripheral.identifier.UUIDString];
    }
}

/**
 *  设备返回数据后调用
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
//    YYQLog(@"didUpdateValueForCharacteristic error = %@\nvalue = %@ ,isNotifying = %i",error,characteristic.value,characteristic.isNotifying);

    NSString *returnStr =  [NSData hexadecimalString:characteristic.value];

    NSString *headStr = [returnStr substringToIndex:8];
    if ([headStr isEqualToString:kReturnStr_GetStepsH]) {
        YYQLog(@"计步器同步结束 返回结果：%@",returnStr);
        self.syncing = NO;
        if (self.isHistory) {
            [self sendHistorySteps];
            self.history = NO;
        }
    }else if([headStr isEqualToString:kReturnStr_GetTime]){
        NSString *str = [returnStr substringWithRange:NSMakeRange(8, 18)];
        NSDate * dateOfDev = [NSDate dateOfStringFormatyyyyMMddwwzzHHmmss:str];
        YYQLog(@"时间为：%@，本地时间为：%@",dateOfDev,[NSDate date]);
        NSString *bLv = [returnStr substringFromIndex:26];
        int bLvInt = (int)strtoul([bLv UTF8String],0,16);
        YYQLog(@"电量为%i%%",bLvInt);
        if ([self.delegate respondsToSelector:@selector(ottoBTManager:date:batteryLV:)]) {
            [self.delegate ottoBTManager:self date:dateOfDev batteryLV:bLvInt];
        }
    }else{
        NSString *stepsGetHeadStr = [returnStr substringToIndex:2];
        if ([stepsGetHeadStr isEqualToString:kReturnStr_GetTodayStepsStart]) {
            if (self.isHistory) {
                YYQLog(@"开始接收计步器历史数据，头数据:%@",returnStr);
                [self addStepsStr:returnStr];
            }else{
                YYQLog(@"开始接收计步器当天数据，头数据:%@",returnStr);
                [self totalDateAnalysisWithHexString:returnStr];
            }
            self.syncing = YES;
        }else{
            if (self.isSyncing) {
                if (self.isHistory) {
                    YYQLog(@"开始接收计步器历史数据包:%@",returnStr);
                    [self addStepsStr:returnStr];
                }else{
                    YYQLog(@"开始接收计步器当天数据包:%@",returnStr);
                    [self stepsAnalysisWithHexString:returnStr];
                }
            }else{
                for (int i = 0 ; i < self.returnCodeArray.count; i ++) {
                    if ([returnStr isEqualToString:self.returnCodeArray[i]]) {
                        YYQLog(@"%@",self.logArray[i]);
                    }
                }
            }
        YYQLog(@"返回结果：%@",returnStr);
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
//    NSLog(@"didUpdateValueForDescriptor error = %@",error);
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
//    NSLog(@"didUpdateNotificationStateForCharacteristic error = %@",error);

}

#pragma mark - Steps等数据解析方法
- (void)totalDateAnalysisWithHexString:(NSString*)hexString
{
//    200f 011c 0508 0000 020e 0000 0034 0000 0000 00a1
    NSString *dateStrH = [hexString substringToIndex:8];
    NSString *stepsStr =[hexString substringWithRange:NSMakeRange(12, 8)];
    NSString *intensityStr = [hexString substringWithRange:NSMakeRange(20, 8)];
    
    NSDate *date = [NSDate dateWithHexDate:dateStrH];
    self.tarDate = date;
    int steps = (int)strtoul([stepsStr UTF8String],0,16);
    int intensity = (int)strtoul([intensityStr UTF8String],0,16);

    //结果发送至代理
    if ([self.delegate respondsToSelector:@selector(ottoBTManager:totalDataWithTotalSteps:totalIntensity:date:)]) {
        [self.delegate ottoBTManager:self totalDataWithTotalSteps:steps totalIntensity:intensity date:date];
    }
}

static int stepsOfHour = 0;
static int intensityOfHour = 0;
static NSDate *hourDate;
- (void)stepsAnalysisWithHexString:(NSString*)hexString
{
    if ([hexString isEqualToString:@"de0102ed"]) {
        return;
    }
    NSString *timeStrH = [hexString substringToIndex:4];
    NSString *stepCountStrH = [hexString substringWithRange:NSMakeRange(4, 4)];
    NSString *intensityH = [hexString substringWithRange:NSMakeRange(8, 4)];
    
    int steps = (int)strtoul([stepCountStrH UTF8String],0,16);
    int intensity = (int)strtoul([intensityH UTF8String],0,16);
   NSDate *date = [NSDate dateWithTimeNote:timeStrH ThatDate:self.tarDate isSecond:NO];
    if (hexString.length ==16) {
            //0089 0059 0007 0000
    }else{
     //0084 006a 0005 0000 0085 005d 000d 0000
//        NSString *timeStrE = [hexString substringToIndex:4];
        NSString *stepCountStrE = [hexString substringWithRange:NSMakeRange(20, 4)];
        NSString *intensityE = [hexString substringWithRange:NSMakeRange(24, 4)];
        steps += (int)strtoul([stepCountStrE UTF8String],0,16);
        intensity += (int)strtoul([intensityE UTF8String],0,16);
    }
    
    //结果发送至代理
    if([self.delegate respondsToSelector:@selector(ottoBTManager:getSteps:intensity:fromDate:)])
        [self.delegate ottoBTManager:self getSteps:steps intensity:intensity fromDate:date];
    if (!hourDate) {
        hourDate = date;
        stepsOfHour += steps;
    }else if (hourDate.hour == date.hour){
        stepsOfHour += steps;
    }else{
        if([self.delegate respondsToSelector:@selector(ottoBTManager:hourDataWithSteps:intensity:fromDate:)]){
            [self.delegate ottoBTManager:self hourDataWithSteps:stepsOfHour intensity:intensityOfHour fromDate:hourDate];
        }
        if([self.delegate respondsToSelector:@selector(ottoBTManager:getSteps:intensity:fromDate:)]){
            [self.delegate ottoBTManager:self getSteps:steps intensity:intensity fromDate:date];
        }
        stepsOfHour = steps;
        hourDate = date;
    }
}


- (void)addStepsStr:(NSString*)string
{
    if (self.historyStepsStr == nil) {
        self.historyStepsStr = string;
    }else{
        self.historyStepsStr = [self.historyStepsStr stringByAppendingString:string];
    };
}
- (void)sendHistorySteps
{
    NSDate *date;

//    NSDate *stepsDate;
    int steps = 0;
    int intensity = 0;
//    200f 0302 0058 0016 f581 c81a f680 0000 ff80 0000
//    0480 0c00 0580 0000 1f80 0000 eb80 8e05 ec80 6a03
//    ed80 4903 ffff ffff ffff ffff ffff ffff ffff ffff
    int count = (int)self.historyStepsStr.length/8;
    if (count==0) {
        YYQLog(@"该天没有历史数据");
        if ([self.delegate respondsToSelector:@selector(ottoBTManager:hourDataWithSteps:intensity:fromDate:)]) {
        
            [self.delegate ottoBTManager:self hourDataWithSteps:0 intensity:0 fromDate:self.historyDate];
        }
    }
    BOOL secondTime  = NO;
    for (int i = 0; i < count; i++) {
        if (i == 0) {
            //200f 0109
            NSString *str = [self.historyStepsStr substringToIndex:8];
            date = [NSDate dateWithHexDate:str];
        }else if (i == 1){
            //字符串长度
        }else{
            //b980 ff1f
            NSString *str = [self.historyStepsStr substringWithRange:NSMakeRange(8*i, 8)];
            NSString *timeNote = [str substringToIndex:2];


            NSDate *timeNoteDate = [NSDate dateWithTimeNote:timeNote ThatDate:date isSecond:secondTime];//dateWithTimeNote:timeNote ThatDate:date];
            if (date.hour == timeNoteDate.hour) {
                NSString *stepsStr = [str substringWithRange:NSMakeRange(3, 3)];
                steps += (int)strtoul([stepsStr UTF8String],0,16);
                NSString *intensityStr = [str substringFromIndex:6];
                intensity += (int)strtoul([intensityStr UTF8String],0,16);
            }else{
                NSString *isRb = [str substringToIndex:4];
                if ([isRb isEqualToString:@"ffff"]||[isRb isEqualToString:@"FFFF"]) {
                    break;
                }
                if ([self.delegate respondsToSelector:@selector(ottoBTManager:hourDataWithSteps:intensity:fromDate:)]) {
                    [self.delegate ottoBTManager:self hourDataWithSteps:steps intensity:intensity fromDate:date];
                    NSString *stepsStr = [str substringWithRange:NSMakeRange(3, 3)];
                    steps = (int)strtoul([stepsStr UTF8String],0,16);
                    NSString *intensityStr = [str substringFromIndex:6];
                    intensity = (int)strtoul([intensityStr UTF8String],0,16);
                }
                date = timeNoteDate;
            }
            //时间节点进入第二轮
            if ([timeNote isEqualToString:@"ff"] || [timeNote isEqualToString:@"FF"]) {
                secondTime = YES;
            }else if ([timeNote isEqualToString:@"1f"] || [timeNote isEqualToString:@"1F"]){
                secondTime = NO;
            }
        }
    }
    
    self.historyStepsStr = nil;
}
@end
