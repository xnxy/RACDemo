//
//  RACSchedulerViewController.m
//  RACDemo
//
//  Created by zhouwei on 2018/9/7.
//  Copyright © 2018年 zhouwei. All rights reserved.
//

#import "RACSchedulerViewController.h"

@interface RACSchedulerViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *btn;

@end

@implementation RACSchedulerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}
- (IBAction)btnClick:(id)sender {
    
    RAC(self.imageView, image) = [[RACSignal startEagerlyWithScheduler:[RACScheduler schedulerWithPriority:RACSchedulerPriorityBackground] block:^(id<RACSubscriber>  _Nonnull subscriber) {
        NSError *error;
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1536310965087&di=20809aac79bf8f5ed7b2dd8bea35c9fa&imgtype=0&src=http%3A%2F%2Fattach.zhiyoo.com%2Fforum%2F201303%2F30%2F16392363kvt13er39xk1k3.jpg"]
                                             options:NSDataReadingMappedAlways
                                               error:&error];
        if(error) {
            [subscriber sendError:error];
        }
        else {
            [subscriber sendNext:[UIImage imageWithData:data]];
            [subscriber sendCompleted];
        }
    }] deliverOn:[RACScheduler mainThreadScheduler]];
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
