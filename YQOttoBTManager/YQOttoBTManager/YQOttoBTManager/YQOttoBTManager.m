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
static NSString *kCodeStr_Set12Hours = @"BE0101FE";//1.1 设置12/24小时制，本地时区日期时间，有参数
static NSString *kCodeStr_GetTime = @"BE0102ED";//1.7 请求计步器发送日期时间，无参数
static NSString *kCodeStr_SetTime = @"BE0102FE";//1.3 发送日期时间时区给计步器，有参数
static NSString *kCodeStr_SetBTWork = @"BE0106FE";//1.15 手机发送设备的定时启动，有参数
static NSString *kCodeStr_RestoreFactory =@"BE010DED";//1.33 手机发送恢复出厂设置，无参数
static NSString *kCodeStr_SetPetName = @"BE010EFE01";//1.35 发送宠物名称，有参数
static NSString *kCodeStr_SetMasterName = @"BE0112FE";//1.45 发送联系人名称，有参数
static NSString *kCodeStr_SetPhoneNumber = @"BE0113FE";//1.47 发送电话号码，有参数
static NSString *kCodeStr_GetStepsH = @"BE0201FE";//2.1 请求计步器传输数据xx日期xx时间节点，单位为一天，有参数
//static NSString *kCodeStr_GetStepsT = @"BE0203FE";

static NSString *kCodeStr_DeleteStepsH = @"BE0202FE";//2.4 请求删除某天运动数据，有参数


/** 返回指令集 **/
static NSString *kReturnStr_Set12Hours = @"de0101ed";//1.2 计步器收到12/24小时制后返回，无参数
static NSString *kReturnStr_GetTime = @"de0102fb"; //1.8 计步器发送日期时间到手机，有参数
static NSString *kReturnStr_SetTime = @"de0102ed";//1.4 计步器收到日期时间时区后返回，无参数
static NSString *kReturnStr_SetBTWork = @"de0106ed";//1.16 计步器收到定时启动后返回，无参数
static NSString *kReturnStr_RestoreFactory =@"de010ded"; //1.34 收到恢复出厂设置后返回，无参数
static NSString *kReturnStr_SetPetName = @"de010eed";//1.36 收到宠物名称，无参数
static NSString *kReturnStr_SetMasterName = @"de0112ed";//1.45 收到联系人名称，无参数
static NSString *kReturnStr_SetPhoneNumber = @"de0113ed";//1.47 收到电话号码，无参数

static NSString *kReturnStr_GetStepsStart = @"de0201fe";//2.3 开始传送数据的第一个包头数据
static NSString *kReturnStr_GetStepsH = @"de0201ed";//2.2 当天有数据：发完数据后，以此结束，无参数
static NSString *kReturnStr_GetNoStepsH = @"de020106";//2.2 当天无数据：直接以此结束，无参数
static NSString *kReturnStr_DeleteStepsH = @"de0202ed";//2.5 删除数据成功，无参数

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
    _returnCodeArray = @[kReturnStr_RestoreFactory,kReturnStr_SetBTWork,kReturnStr_SetMasterName,kReturnStr_SetPetName,kReturnStr_SetPhoneNumber,kReturnStr_SetTime,kReturnStr_Set12Hours,kReturnStr_DeleteStepsH];
    _logArray = @[@"返回出厂设置成功",@"设置启动时间成功",@"设置主人名字成功",@"设置宠物名字成功",@"设置手机号码成功",@"设置时间成功",@"设置12/24小时制成功",@"删除数据成功"];
    _version = 0705;
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
        YYQLog(@"没有连接到设备，无法设置， =,=!!");
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
    }else{
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
- (void)connectWithDeviceID:(NSString*)ID{
    BOOL found = NO;
    for (CBPeripheral *peripheral in self.PeripheralsFound) {
        if ([peripheral.identifier.UUIDString isEqualToString:ID]) {
            [self.cbManager connectPeripheral:peripheral options:nil];
            float duration = 1.5;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!self.isConnected) {
                    YYQLog(@"连接超时，请再扫描");
                    if ([self.delegate respondsToSelector:@selector(ottoBTManager:didConnectWithDevicelName:ID:)]) {
                        [self.delegate ottoBTManager:self didConnectWithDevicelName:nil ID:nil];
                    }
                }
            });
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
- (void)getTimeOfDevice{
    NSString *str = kCodeStr_GetTime;
    [self writeDataWithString:str Characteristic:self.settingsCh];
    
    [self setAutoBT];
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
    YYQLog(@"写入时间代码：%@",str);
    //    str = @"BE0102FE07df060a04080c3110";
    [self writeDataWithString:str Characteristic:self.settingsCh];
    [self setAutoBT];
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
/** 获得历史数据 */
- (void)getStepsWithDate:(NSDate*)date;{

        self.historyDate = date;
        NSString *str = kCodeStr_GetStepsH;
//        self.history = YES; 历史数据解析方式已经废弃
        str = [str  stringByAppendingString:[NSDate stringDay16WithDate:date]];
        str  = [str stringByAppendingString:@"0000"];
    YYQLog(@"发送历史请求 = %@ ",str );
        [self writeDataWithString:str Characteristic:self.settingsCh];
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
    str = [str stringByAppendingString:@"0000"];
//        str = @"BE0201FE07df01020000";
    YYQLog(@"发送str = %@",str);
    [self writeDataWithString:str Characteristic:self.settingsCh];
}

/**
 *  删除运动数据
 */
- (void)deleteDataWithDate:(NSDate*)date
{
    NSString *str = kCodeStr_DeleteStepsH;
    NSString * dateStr = [NSString stringWithFormat:@"0%02lx",(unsigned long)date.year];
    dateStr =  [dateStr stringByAppendingString:[NSString stringWithFormat:@"%02lx",(unsigned long)date.month]];
    dateStr =  [dateStr stringByAppendingString:[NSString stringWithFormat:@"%02lx",(unsigned long)date.day]];

    str = [str stringByAppendingString:dateStr];
    str = [str stringByAppendingString:@"0000"];
//    str = @"BE0202FE07df07050000";
    [self writeDataWithString:str Characteristic:self.settingsCh];

}




#pragma mark - CBCentralManagerDelegate 蓝牙代理方法
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
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
/**每搜到一个设备都会掉用这个方法*/
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

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    YYQLog(@"设备连接成功！didConnectPeripheral: name = %@ , UUID = %@",peripheral.name,peripheral.identifier.UUIDString);
    peripheral.delegate = self;
    self.curPeripheral = peripheral;
    _connected = YES;
    //开始搜索设备提供的可用服务
    //    YYQLog(@"start To Discover Services...");
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    
    YYQLog(@"设备断开连接，error = %@",[error localizedDescription]);
    _connected = NO;
    self.curPeripheral = nil;
    self.syncing = NO;
    if ([self.delegate respondsToSelector:@selector(ottoBTManager:didDisconnectWithDevicelName:ID:)]) {
        [self.delegate ottoBTManager:self didDisconnectWithDevicelName:peripheral.name ID:peripheral.identifier.UUIDString];
    }
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
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    //    YYQLog(@"did Discover Characteristics For Service ,error = %@ \n service = %@",error,service);
    self.valuesCh = [service.characteristics firstObject];
    self.settingsCh = [service.characteristics lastObject];
    [self.curPeripheral setNotifyValue:YES forCharacteristic:self.settingsCh];
    [self.curPeripheral setNotifyValue:YES forCharacteristic:self.valuesCh];
    //    YYQLog(@"搜索到特征 set = %@ , \nValue = %@",self.settingsCh,self.valuesCh);
    //通知代理，连接成功
    if ([self.delegate respondsToSelector:@selector(ottoBTManager:didConnectWithDevicelName:ID:)]) {
        [self.delegate ottoBTManager:self didConnectWithDevicelName:peripheral.name ID:peripheral.identifier.UUIDString];
    }
}

/**
 *  设备返回数据后调用
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    NSString *returnStr =  [NSData hexadecimalString:characteristic.value];
//    YYQLog(@"返回结果：%@",returnStr);
    
    NSString *headStr = [returnStr substringToIndex:8];
    if ([headStr isEqualToString:kReturnStr_GetStepsH]) {
        YYQLog(@"计步器同步结束 返回结果：%@",returnStr);
        self.syncing = NO;
        if (self.isHistory) {
            [self sendHistorySteps];
            self.history = NO;
        }
    }else if([headStr isEqualToString:kReturnStr_GetTime]){
        NSString *str = [returnStr substringWithRange:NSMakeRange(12, 18)];
        NSDate * dateOfDev = [NSDate dateOfStringFormatyyyyMMddwwzzHHmmss:str];
        
        
        YYQLog(@"时间为：%@，本地时间为：%@",dateOfDev,[NSDate date]);

#warning 厂家已经更新电量功能，移动到别处
        if ([self.delegate respondsToSelector:@selector(ottoBTManager:date:)]) {
            [self.delegate ottoBTManager:self date:dateOfDev];
        }
    }else{
        NSString *stepsGetHeadStr = [returnStr substringToIndex:8];
        if ([stepsGetHeadStr isEqualToString:kReturnStr_GetStepsStart]) {
            if (self.isHistory) {
                YYQLog(@"开始接收计步器历史数据，头数据:%@",returnStr);
                [self addStepsStr:returnStr];
            }else{
                YYQLog(@"开始接收计步器数据，头数据:%@",returnStr);
                [self totalDateAnalysisWithHexString:returnStr];
            }
            self.syncing = YES;
        }else{
            if (self.isSyncing) {
                if (self.isHistory) {
                    YYQLog(@"开始接收计步器历史数据包:%@",returnStr);
                    [self addStepsStr:returnStr];
                }else{
                    YYQLog(@"开始接收计步器数据包:%@",returnStr);
                    [self stepsAnalysisWithHexString:returnStr];
                }
            }else{
                for (int i = 0 ; i < self.returnCodeArray.count; i ++) {
                    if ([returnStr isEqualToString:self.returnCodeArray[i]]) {
                        YYQLog(@"%@",self.logArray[i]);
                    }
                }
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
}

#pragma mark - Steps等数据解析方法
/**
 *  头数据解析
 */
- (void)totalDateAnalysisWithHexString:(NSString*)hexString
{
    //    200f 011c 0508 0000 020e 0000 0034 0000 0000 00a1 已经废弃
    //    de02 01fe 070f 060a 0000 01b5 0000 004d 0300 6400
    //    de02 01fe 07df 0705 0000 0000 0000 0000 034c 6400
    NSString *dateStrH = [hexString substringWithRange:NSMakeRange(8, 8)];
    NSString *stepsStr =[hexString substringWithRange:NSMakeRange(16, 8)];
    NSString *intensityStr = [hexString substringWithRange:NSMakeRange(24, 8)];
    
    NSDate *date = [NSDate dateWithHexDate:dateStrH];
    self.tarDate = date;
    int steps = (int)strtoul([stepsStr UTF8String],0,16);
    int intensity = (int)strtoul([intensityStr UTF8String],0,16);
    
    
    NSString *bLv = [hexString substringWithRange:NSMakeRange(36, 2)];
    int bLvInt = (int)strtoul([bLv UTF8String],0,16);
    YYQLog(@"电量为%i%%",bLvInt);
    
    //结果发送至代理
    if ([self.delegate respondsToSelector:@selector(ottoBTManager:totalDataWithTotalSteps:totalIntensity:date:btLV:)]) {
        [self.delegate ottoBTManager:self totalDataWithTotalSteps:steps totalIntensity:intensity date:date btLV:bLvInt];
    }
}

static int stepsOfHour = 0;
static int intensityOfHour = 0;
static NSDate *hourDate;
- (void)stepsAnalysisWithHexString:(NSString*)hexString
{
    
    //    b4 0000 00
    
    for (int i = 0; i<(hexString.length/8); i ++) {
        NSString *timeStrH = [hexString substringWithRange:NSMakeRange(i*8, 2)];
        NSString *stepCountStrH = [hexString substringWithRange:NSMakeRange(2+i*8, 4)];
        NSString *intensityH = [hexString substringWithRange:NSMakeRange(6+i*8, 2)];
        
        int steps = (int)strtoul([stepCountStrH UTF8String],0,16);
        int intensity = (int)strtoul([intensityH UTF8String],0,16);
        NSDate *date = [NSDate dateWithTimeNote:timeStrH ThatDate:self.tarDate isSecond:NO];
        
        if (!hourDate) {
            hourDate = date;
        }
        if (hourDate.hour == date.hour) {
            stepsOfHour += steps;
            intensityOfHour += intensity;
        }else{
            //结果发送至代理
            if([self.delegate respondsToSelector:@selector(ottoBTManager:hourDataWithSteps:intensity:fromDate:)]){
                [self.delegate ottoBTManager:self hourDataWithSteps:stepsOfHour intensity:intensityOfHour fromDate:hourDate];
            }
            stepsOfHour = steps;
            hourDate = date;
        }
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
