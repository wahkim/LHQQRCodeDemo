//
//  ViewController.m
//  LHQQRCodeDemo
//
//  Created by Xhorse_iOS3 on 2021/9/2.
//

#import "ViewController.h"
#import "RHScanViewController.h"
#import "CVScanViewController.h"
#import "ZXingScan_2ViewController.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initDataSource];
    [self setupViews];
    
}

- (void)initDataSource {
    self.dataSource = @[@"本地相机识别", @"opencv scan", @"ZXing scan"].mutableCopy;
}

- (void)setupViews
{
    self.title = @"QRCode";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
    [self.view addSubview:self.tableView];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class]) forIndexPath:indexPath];
    cell.textLabel.text = self.dataSource[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                [self.navigationController pushViewController:[RHScanViewController new] animated:YES];
                break;
            case 1:
                [self.navigationController pushViewController:[CVScanViewController new] animated:YES];
                break;
            case 2:
                [self.navigationController pushViewController:[ZXingScan_2ViewController new] animated:YES];
                break;
            default:
                break;
        }
    }
}

@end
