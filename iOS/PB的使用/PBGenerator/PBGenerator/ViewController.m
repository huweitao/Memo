//
//  ViewController.m
//  PBGenerator
//
//  Created by huweitao on 17/2/15.
//  Copyright © 2017年 huweitao. All rights reserved.
//

#import "ViewController.h"
#import "Person.pbobjc.h"
#import "Pbtest.pbobjc.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    Person *per = [[Person alloc] init];
    per.name = @"protocBuffer";
    per.address = @"shenzhen";
    per.age = 23;
    NSLog(@"Person in PB is %@ %@ %ld",per.name,per.address,per.age);
    PBTest *tet = [[PBTest alloc] init];
    tet.query = @"http-----";
    tet.corpus = PBTest_Corpus_Web;
    PBTest2 *tet2 = [[PBTest2 alloc] init];
    [tet2.repArray addValue:15];
    NSLog(@"%@%ld,%@",tet.query,tet.corpus,tet2.repArray);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
