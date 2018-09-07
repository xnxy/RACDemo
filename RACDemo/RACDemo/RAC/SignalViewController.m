//
//  SignalViewController.m
//  RACDemo
//
//  Created by zhouwei on 2018/9/7.
//  Copyright © 2018年 zhouwei. All rights reserved.
//

#import "SignalViewController.h"

@interface SignalViewController ()
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *login;

@property (nonatomic, copy) NSString *name;

@end

@implementation SignalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    @weakify(self)
    [[self.userNameTextField rac_textSignal] subscribeNext:^(NSString * _Nullable x) {
        @strongify(self);
        self.name = x;
    }];
  
    //绑定
//    RAC(self, name) = [self.userNameTextField rac_textSignal];
//    [RACObserve(self, name) subscribeNext:^(id  _Nullable x) {
//        NSLog(@"----绑定---：%@----",x);
//    }];
    
//    [self map];
}

//创建信号  订阅信息
- (void)signal{
    
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber>subscriber) {
        [subscriber sendNext:@"hello world"];
        [subscriber sendCompleted];
        return nil;
    }];
    
    //订阅信息
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"---x:%@----",x);
    }];
    
    /*
    RACSubject是一个有趣的信号类型。在RAC的世界中，它是一个可变的状态。它是一个可以主动发送新值得信号。   一般我们使用它来代替代理。
    
    RACSubject和RACReplaySubject 的区别：
    1. RACSubject/RACReplaySubject: 信号的提供者，自己可以充当信号，又可以发送信号。
    
    2. RACSubject 必须要先订阅信号之后才能发送信号，而RACReplaySubject可以先发送信号后再订阅。
    RACSubject代码中的体现为： 先走sendNext,后走subscribeNext订阅。
    RACReplaySubject代码中体现为: 先走subscribeNext订阅，后走sendNext.
     */
    
//    RACSubject *subject = [RACSubject subject];
//    [subject sendNext:@""];
//
//    RACReplaySubject *subject = [RACReplaySubject subject];
    
}

/*
 1.target-action
 */
- (void)targetAction{
    [[self.login rac_signalForControlEvents:UIControlEventTouchUpInside]
     subscribeNext:^(__kindof UIControl * _Nullable x) {
         NSLog(@"-----按钮点击事件 ------");
     }];
}
/*
 2.用RAC写代理是有局限的，它只能实现返回值为void的代理方法
 */
- (void)delegate{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"RAC" message:@"RAC delegate" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    [[self rac_signalForSelector:@selector(alertView:clickedButtonAtIndex:) fromProtocol:@protocol(UIAlertViewDelegate)] subscribeNext:^(RACTuple *tuple) {
        NSLog(@"---alertView：%@----",tuple.first);
        NSLog(@"----buttonIndex：%@----",tuple.second);
    }];
//    [[alertView rac_buttonClickedSignal] subscribeNext:^(id x) {
//        NSLog(@"----%@----",x);
//    }];
    [alertView show];
}

/*
 3.通知
 */
- (void)notificationCenter{
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"postData" object:nil]
     takeUntil:self.rac_willDeallocSignal]
     subscribeNext:^(NSNotification * _Nullable x) {
         NSLog(@"------notification%@-----",x);
     }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSMutableArray *dataArray = [[NSMutableArray alloc] initWithObjects:@"1", @"2", @"3", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"postData" object:dataArray];
    });
}

/*
 4.KVO
 RAC中得KVO大部分都是宏定义，所以代码异常简洁，简单来说就是RACObserve(TARGET, KEYPATH)这种形式，TARGET是监听目标，KEYPATH是要观察的属性值
 */
- (void)racObserve{
    [RACObserve(self, name) subscribeNext:^(id  _Nullable x) {
        NSLog(@"------监听name变化:%@-----",x);
    }];
}

//信号 去重
- (void)distinctUntilChanged{
    /*
     distinctUntilChanged 网络请求中微量减轻服务器压力，无用的请求我们应该尽可能不发送。distinctUntilChanged 的作用是使RAC不会连续发送两次相同的信号。
     */
    [[self.userNameTextField rac_textSignal] subscribeNext:^(NSString * _Nullable x) {
        NSLog(@"--没去重--username:%@-----",x);
    }];
    [[[self.userNameTextField rac_textSignal] distinctUntilChanged] subscribeNext:^(id x) {
        NSLog(@"---去重---username:%@-----",x);
    }];
}

//组合信号
- (void)combineLatest{
    @weakify(self)
    [[[RACSignal combineLatest:@[self.userNameTextField.rac_textSignal,self.passwordTextField.rac_textSignal] reduce:^(NSString *username, NSString *password){
        NSLog(@"-----username:%@----password:%@----",username,password);
        return @(username.length > 5 && password.length > 5);
    }] distinctUntilChanged]
     subscribeNext:^(NSNumber *value) {
         @strongify(self);
         NSLog(@"-----用户名和密码是否合法：%@----",value);
         if (value.boolValue) { // 用户名和密码合法，登录按钮可用
             self.login.backgroundColor = [UIColor redColor];
             self.login.enabled = YES;
         }else{// 用户名或密码不合法，登录按钮不可用
             self.login.backgroundColor = [UIColor lightGrayColor];
             self.login.enabled = NO;
         }
     }];
}

/*filter 过滤
 返回YES的才会通过，它的内部实现使用了- flattenMap:，将原来的Signal经过过滤转化成只返回过滤值的Signal
 */
- (void)filter{
    [[self.userNameTextField.rac_textSignal filter:^BOOL(NSString * _Nullable value) {
        return [value isEqualToString:@"123"];
    }] subscribeNext:^(NSString * _Nullable x) {
        NSLog(@"----filter:%@-----",x);
    }];
}

/*
 map  (映射)将接收的对象转换成想要的类型
 */
- (void)map{
    [[self.userNameTextField.rac_textSignal map:^id _Nullable(NSString * _Nullable value) {
        return [NSString stringWithFormat:@"%@hello",value];
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"-----map:%@----",x);
    }];
}

- (IBAction)login:(UIButton *)sender {
    NSLog(@"----按钮点击----");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
