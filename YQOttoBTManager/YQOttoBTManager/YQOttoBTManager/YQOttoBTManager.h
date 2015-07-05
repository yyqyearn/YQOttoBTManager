// 版本 1.0
//  YQOttoBTManager.h
//  YQOttoBTManager
//
//  Created by yyq on 15/1/21.
//  Copyright (c) 2015年 mobilenow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class CBCentralManager;
@class CBPeripheral;
@protocol YQOttoBTManagerDelegate;


@interface YQOttoBTManager : NSObject
@property (nonatomic,assign,readonly,getter=isConnected)BOOL connected;
@property (nonatomic,assign,readonly)float version;

@property (weak, nonatomic) id <YQOttoBTManagerDelegate> delegate;


/**
 *  实例化一个Manager,单例
 */
+ (instancetype)sharedManager;

/**
 * 公/英制,12H/24H制: 在APP第一次运行时,弹出对话框,要求用户选择
 */
- (void)setIs12Hours:(BOOL)is12Hours andIsBritich:(BOOL)isBritich;

/**
 *  开始设备寻找:duration 指定设备寻找时间
 */
- (void)scanDevicesWithDuration:(float)duration;

/**
 *  立即停止扫描
 */
- (void)stopScanDevices;

/**
 *  连接设备
 */
- (void)connectWithDeviceID:(NSString*)ID;

/**
 *  断开连接
 */
- (void)disConnectWithDevice;

/**
 *  获得设备时间
 */
- (void)getTimeOfDevice;

/**
 *  写入设备时间
 */
- (void)setTimeOfDeviceWithDate:(NSDate*)date;

/**
 *  还原出厂设置,未完工
 */
- (void)RestoreFactory;

/**
 *  设置宠物姓名
 */
- (void)setPetNameWithName:(NSString*)name;

/**
 *  设置主人姓名
 */
- (void)setMastNameWithName:(NSString*)name;

/**
 *  设置联系电话
 */
- (void)setPhoneNumberWithNumber:(NSString*)number;

/**
 *  请求计步器数据传输
 */
- (void)getStepsWithDate:(NSDate*)date;

/**
 *  当天数据
 */
- (void)getStepsToday;

/**
 *  删除运动数据
 */
- (void)deleteDataWithDate:(NSDate*)date;

@end

@protocol YQOttoBTManagerDelegate <NSObject>
@optional

/**
 *  搜索到一个设备到后立即调用
 *  在此方法中遍历数组得到单个CBPeripheral对象，并可以收集CBPeripheral.name 和 CBPeripheral.identifier生成列表交由用户选择
 *  @param peripherals CBPeripheral数组
 */
- (void)ottoBTManager:(YQOttoBTManager*)manager didFoundDeviceWithName:(NSString*)name identifier:(NSString*)identifier;

/**
 *  搜索到设备，并且时间到后调用
 *  在此方法中遍历数组得到单个CBPeripheral对象，并可以收集CBPeripheral.name 和 CBPeripheral.identifier生成列表交由用户选择
 *  @param peripherals CBPeripheral数组
 */
- (void)ottoBTManager:(YQOttoBTManager*)manager didFoundDevicesWithNames:(NSArray*)nams identifiers:(NSArray*)identifiers;
//- (void)ottoBTManager:(YQOttoBTManager*)manager didFoundDevicesWithPeripherals:(NSArray*)peripherals;


/**
 *  连接到设备后调用
 *  @param name 连接到的设备 如果为nil，则没有找到可连接的设备
 */
- (void)ottoBTManager:(YQOttoBTManager*)manager didConnectWithDevicelName:(NSString*)name ID:(NSString *)ID;

/**
 *  设备断开连接
 */
- (void)ottoBTManager:(YQOttoBTManager *)manager didDisconnectWithDevicelName:(NSString*)name ID:(NSString *)ID;
/**
 *  设备获得时间
 *  @param date           当天日期
 */
- (void)ottoBTManager:(YQOttoBTManager *)manager date:(NSDate *)date;

/**
 *  设备开始同步当天数据
 *  @param totalSteps     当天总步数
 *  @param totalIntensity 当天总强度
 *  @param date           当天日期
 *  @param btLV           剩余电量百分比
 */
- (void)ottoBTManager:(YQOttoBTManager *)manager totalDataWithTotalSteps:(int)totalSteps totalIntensity:(int)totalIntensity date:(NSDate *)date btLV:(int)btLV;
/**
 *  设备获取计步器数据
 *  @param steps     计步器步数
 *  @param intensity 运动强度
 *  @param date      时间点
 */
- (void)ottoBTManager:(YQOttoBTManager *)manager getSteps:(int)steps intensity:(int)intensity fromDate:(NSDate *)date;

/**
 *  设备获取计步器-整点-数据
 *  @param steps     计步器步数
 *  @param intensity 运动强度
 *  @param date      时间点
 */
- (void)ottoBTManager:(YQOttoBTManager *)manager hourDataWithSteps:(int)steps intensity:(int)intensity fromDate:(NSDate *)date;
@end
