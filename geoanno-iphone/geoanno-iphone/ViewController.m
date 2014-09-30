//
//  ViewController.m
//  geoanno-iphone
//
//  Created by mitsui0273 on 2014/09/29.
//  Copyright (c) 2014年 none. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController ()<CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameText;

@property CLLocationManager *locationManager;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    _locationManager = [[CLLocationManager alloc] init];
    // ②位置情報サービスのON/OFFで挙動を分岐
    if ([CLLocationManager locationServicesEnabled]) {
        // ③locationManagerの各プロパティを設定
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        _locationManager.activityType = CLActivityTypeAutomotiveNavigation;
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        _locationManager.distanceFilter = 100.0;
    } else {
        NSLog(@"Location services not available.");
    }
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    _nameText.text = [ud stringForKey:@"name"];
}
- (IBAction)onChangeSwitch:(UISwitch*)swt {
    if (swt.on) {
        [_locationManager startUpdatingLocation];
    } else {
        [_locationManager stopUpdatingLocation];
    }
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:_nameText.text forKey:@"name"];
    [ud synchronize];
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    // ⑥ログを出力
    NSLog(@"didUpdateToLocation latitude=%f, longitude=%f, accuracy=%f, time=%@",
          [newLocation coordinate].latitude,
          [newLocation coordinate].longitude,
          newLocation.horizontalAccuracy,
          newLocation.timestamp);
    
    [self postLocation:newLocation];
}

- (void)postLocation:(CLLocation *)location
{
    NSURL* url = [NSURL URLWithString:@"http://geoanno.herokuapp.com/currentPosition"];
    //NSURL* url = [NSURL URLWithString:@"http://sti2238:3000/currentPosition"];
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    // postするテキスト
    NSMutableDictionary *jsonObj = [[NSMutableDictionary alloc] init];
    [jsonObj setObject:[self getUUID] forKey:@"accountId"];
    [jsonObj setObject:_nameText.text forKey:@"name"];
    [jsonObj setObject:[NSNumber numberWithDouble:[[location timestamp] timeIntervalSince1970] * 1000] forKey:@"updateTime"];
    
    NSMutableDictionary *position = [[NSMutableDictionary alloc] init];
    [position setObject:[NSNumber numberWithDouble:[location coordinate].latitude] forKey:@"latitude"];
    [position setObject:[NSNumber numberWithDouble:[location coordinate].longitude] forKey:@"longitude"];
    
    [jsonObj setObject:position forKey:@"position"];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObj options:NSJSONWritingPrettyPrinted error:nil];
    //NSData* data = [@"param1=りんご&param2=みかん" dataUsingEncoding:NSUTF8StringEncoding];

    [request setValue:@"application/json;charset=UTF-8"forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                // 完了時の処理
                                            }];
    
    [task resume];
}

-(NSString *)getUUID
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [ud stringForKey:@"UUID"];
    //NSLog(@"stored uuid : %@", uuid);
    if(uuid == nil){
        NSUUID *vendorUUID = [UIDevice currentDevice].identifierForVendor;
        uuid = vendorUUID.UUIDString;
        //NSLog(@"created uuid : %@", uuid);
        
        [ud setObject:uuid forKey:@"UUID"];
        [ud synchronize];
    }
    return uuid;
}
@end
