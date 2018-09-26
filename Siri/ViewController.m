//
//  ViewController.m
//  Siri
//
//  Created by 赵文超 on 2018/9/18.
//  Copyright © 2018 赵文超. All rights reserved.
//

#import "ViewController.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <IntentsUI/IntentsUI.h>
#import <Intents/Intents.h>

@interface ViewController () <INUIAddVoiceShortcutViewControllerDelegate, INUIEditVoiceShortcutViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)addToSiri:(id)sender {
    if (@available(iOS 12.0, *)) {
        NSString *invocationPhrase = @"哈哈哈";
        //判断该指令知否添加过
        [self isInvocationPhraseExist:invocationPhrase block:^(BOOL exist, INVoiceShortcut *voiceShortcut) {
            [self donateShortCutsWithInvocationPhrase:invocationPhrase exist:exist voiceShortcut:voiceShortcut];
        }];
    }
}

/**
 创建或者修改语音捷径

 @param invocationPhrase 提示的语音输入语句
 @param exist 是否已经存在
 @param voiceShortcut 已经存在的语音语句
 */
- (void)donateShortCutsWithInvocationPhrase:(NSString *)invocationPhrase exist:(BOOL)exist voiceShortcut:(INVoiceShortcut *)voiceShortcut  API_AVAILABLE(ios(12.0)){
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"com.cc.siri"];
    activity.eligibleForSearch = YES;
    activity.title = @"我是title";
    activity.eligibleForPrediction = YES;
    activity.suggestedInvocationPhrase = invocationPhrase;

    CSSearchableItemAttributeSet *set = [[CSSearchableItemAttributeSet alloc] init];
    set.thumbnailData = UIImagePNGRepresentation([UIImage imageNamed:@"icon"]);
    set.contentDescription = @"我是描述";

    activity.contentAttributeSet = set;

    INShortcut *shortCut = [[INShortcut alloc] initWithUserActivity:activity];
    if (!exist) { //添加
        INUIAddVoiceShortcutViewController *shortCutVc = [[INUIAddVoiceShortcutViewController alloc] initWithShortcut:shortCut];
        shortCutVc.delegate = self;
        [self presentViewController:shortCutVc animated:YES completion:nil];
    } else { //修改 此处需要用已经存在的voiceShortcut来初始化控制器
        INUIEditVoiceShortcutViewController *shortCutVc = [[INUIEditVoiceShortcutViewController alloc] initWithVoiceShortcut:voiceShortcut];
        shortCutVc.delegate = self;
        [self presentViewController:shortCutVc animated:YES completion:nil];
    }
}

#pragma mark - add voice delegate
- (void)addVoiceShortcutViewController:(INUIAddVoiceShortcutViewController *)controller didFinishWithVoiceShortcut:(nullable INVoiceShortcut *)voiceShortcut error:(nullable NSError *)error  API_AVAILABLE(ios(12.0)){
    if (!error) {
        NSLog(@"%@, %@", voiceShortcut.invocationPhrase, voiceShortcut.identifier);
        [controller dismissViewControllerAnimated:YES completion:^{
            NSLog(@"添加成功");
        }];
    } else {
        NSLog(@"%@", error.localizedDescription);
    }
}

- (void)addVoiceShortcutViewControllerDidCancel:(INUIAddVoiceShortcutViewController *)controller  API_AVAILABLE(ios(12.0)){
    [controller dismissViewControllerAnimated:YES completion:^{
        NSLog(@"取消添加");
    }];
}

#pragma mark - edit voice delegate

- (void)editVoiceShortcutViewController:(INUIEditVoiceShortcutViewController *)controller didUpdateVoiceShortcut:(nullable INVoiceShortcut *)voiceShortcut error:(nullable NSError *)error  API_AVAILABLE(ios(12.0)){
    if (!error) {
        NSLog(@"%@, %@", voiceShortcut.invocationPhrase, voiceShortcut.identifier);
        [controller dismissViewControllerAnimated:YES completion:^{
            NSLog(@"修改成功");
        }];
    } else {
        NSLog(@"%@", error.localizedDescription);
    }
}

- (void)editVoiceShortcutViewController:(INUIEditVoiceShortcutViewController *)controller didDeleteVoiceShortcutWithIdentifier:(NSUUID *)deletedVoiceShortcutIdentifier  API_AVAILABLE(ios(12.0)){
    [controller dismissViewControllerAnimated:YES completion:^{
        NSLog(@"删除指令");
    }];
}

- (void)editVoiceShortcutViewControllerDidCancel:(INUIEditVoiceShortcutViewController *)controller  API_AVAILABLE(ios(12.0)){
    [controller dismissViewControllerAnimated:YES completion:^{
        NSLog(@"取消添加");
    }];
}

#pragma mark - private
/**
 判断捷径是否已经存在
 */
- (void)isInvocationPhraseExist:(NSString *)invocationPhrase block:(void (^)(BOOL exist, INVoiceShortcut *voiceShortcut))block API_AVAILABLE(ios(12.0)){
    NSLog(@"currentThread：%@", [NSThread currentThread]);//主线程
    //获取该app已经添加过的捷径，避免重复添加
    //该方法新开了一个线程，拿到结果后需要返回主线程
    [[INVoiceShortcutCenter sharedCenter] getAllVoiceShortcutsWithCompletion:^(NSArray<INVoiceShortcut *> * _Nullable voiceShortcuts, NSError * _Nullable error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                BOOL exist = NO;
                INVoiceShortcut *voiceShortcut = nil;
                for (INVoiceShortcut *shortcut in voiceShortcuts) {
                    if ([shortcut.invocationPhrase isEqualToString:invocationPhrase]) {
                        exist = YES;
                        voiceShortcut = shortcut;
                        break;
                    } else {
                        exist = NO;
                    }
                }
                block(exist, voiceShortcut);
            });
        }
    }];
}

@end
