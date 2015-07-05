//
//  ViewController.m
//  YQOttoBTManager
//
//  Created by yyq on 15/1/21.
//  Copyright (c) 2015年 mobilenow. All rights reserved.
//

#import "ViewController.h"
#import "YQOttoBTManager.h"
@interface ViewController ()<YQOttoBTManagerDelegate>
@property (nonatomic, strong) YQOttoBTManager * manager;
@property (nonatomic,copy) NSString *deviceID;

@property (weak, nonatomic) IBOutlet UILabel *deviceName;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [YQOttoBTManager sharedManager];
    self.manager.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
- (IBAction)scanDevice:(id)sender {
    [self.manager scanDevicesWithDuration:2000];
}
- (IBAction)connectDevice:(id)sender {
    [self.manager connectWithDeviceID:self.deviceID];
}
- (IBAction)readDate:(id)sender {
    [self.manager getTimeOfDevice];
}
- (IBAction)setDate:(id)sender {
    [self.manager setTimeOfDeviceWithDate:nil];
}
- (IBAction)getStepsToday:(id)sender {
    [self.manager getStepsToday];
}
/**
 *  停止扫描
 */
- (IBAction)stopScan:(id)sender {
    [self.manager stopScanDevices];
}

- (IBAction)getData:(id)sender {
//    [self.manager RestoreFactory];
//    [self.manager setPetNameWithName:@"PingPing"];
//    [self.manager setMastNameWithName:@"yyq Yearn"];
//    [self.manager setPhoneNumberWithNumber:@"13085730958"];
//    [self.manager getStepsWithDate:[NSDate date]];
    
    [self.manager deleteDataWithDate:[NSDate date]];
    
//    [self.manager getStepsToday];

}

#pragma mark - YQOttoBTManagerDelegate
- (void)ottoBTManager:(YQOttoBTManager *)manager didFoundDevicesWithNames:(NSArray *)nams identifiers:(NSArray *)identifiers
{
    self.deviceID = [identifiers lastObject];
}

- (void)ottoBTManager:(YQOttoBTManager *)manager didConnectWithDevicelName:(NSString *)name ID:(NSString *)ID
{
    self.deviceName.text = name;
}
- (void)ottoBTManager:(YQOttoBTManager *)manager didFoundDeviceWithName:(NSString *)name identifier:(NSString *)identifier
{
    self.deviceID = identifier;
}
- (void)ottoBTManager:(YQOttoBTManager *)manager getSteps:(int)steps intensity:(int)intensity fromDate:(NSDate *)date
{
    NSLog(@"客户端获得数据：date = %@, steps = %i , intensity = %i",date,steps,intensity);
}
- (void)ottoBTManager:(YQOttoBTManager *)manager totalDataWithTotalSteps:(int)totalSteps totalIntensity:(int)totalIntensity date:(NSDate *)date btLV:(int)btLV
{
    NSLog(@"客户端获得信息，今天是%@ ，totalSteps = %i , totalIntensity = %i ,电池电量 = %i",date,totalSteps,totalIntensity,btLV);
}
- (void)ottoBTManager:(YQOttoBTManager *)manager hourDataWithSteps:(int)steps intensity:(int)intensity fromDate:(NSDate *)date{
    NSLog(@"客户端获得数据：date = %@, steps = %i , intensity = %i",date,steps,intensity);
}


@end
