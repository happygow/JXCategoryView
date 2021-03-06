//
//  LoadDataViewController.m
//  JXCategoryView
//
//  Created by jiaxin on 2018/8/27.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "LoadDataViewController.h"
#import "JXCategoryView.h"
#import "LoadDataListBaseViewController.h"

#define WindowsSize [UIScreen mainScreen].bounds.size

@interface LoadDataViewController () <JXCategoryViewDelegate>
@property (nonatomic, strong) JXCategoryTitleView *categoryView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray <LoadDataListBaseViewController *> *listVCArray;
@property (nonatomic, strong) JXCategoryListVCContainerView *listVCContainerView;
@end

@implementation LoadDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.isNeedCategoryListContainerView = YES;

    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;

    CGFloat naviHeight = 64;
    if (@available(iOS 11.0, *)) {
        if (WindowsSize.height == 812) {
            naviHeight = [UIApplication sharedApplication].keyWindow.safeAreaInsets.top + 44;
        }
    }

    NSArray *titles = [self getRandomTitles];
    NSUInteger count = titles.count;
    CGFloat categoryViewHeight = 50;
    CGFloat width = WindowsSize.width;
    CGFloat height = WindowsSize.height - naviHeight - categoryViewHeight;

    self.listVCArray = [NSMutableArray array];
    for (int i = 0; i < count; i ++) {
        LoadDataListBaseViewController *listVC = [[LoadDataListBaseViewController alloc] initWithStyle:UITableViewStylePlain];
        listVC.view.frame = CGRectMake(i*width, 0, width, height);
        [self.listVCArray addObject:listVC];
    }

    self.categoryView = [[JXCategoryTitleView alloc] init];
    self.categoryView.frame = CGRectMake(0, 0, WindowsSize.width, categoryViewHeight);
    self.categoryView.delegate = self;
    self.categoryView.titles = titles;
    JXCategoryIndicatorLineView *lineView = [[JXCategoryIndicatorLineView alloc] init];
    self.categoryView.indicators = @[lineView];
    [self.view addSubview:self.categoryView];

    if (self.isNeedCategoryListContainerView) {
        self.listVCContainerView = [[JXCategoryListVCContainerView alloc] initWithFrame:CGRectMake(0, categoryViewHeight, width, height)];
        self.listVCContainerView.defaultSelectedIndex = 0;
        self.listVCContainerView.listVCArray = self.listVCArray;
        [self.view addSubview:self.listVCContainerView];

        self.categoryView.contentScrollView = self.listVCContainerView.scrollView;
    }else {
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, categoryViewHeight, width, height)];
        self.scrollView.pagingEnabled = YES;
        self.scrollView.contentSize = CGSizeMake(width*count, height);
        [self.view addSubview:self.scrollView];

        for (int i = 0; i < count; i ++) {
            LoadDataListBaseViewController *listVC = self.listVCArray[i];
            [self.scrollView addSubview:listVC.view];
        }

        self.categoryView.contentScrollView = self.scrollView;
        [self.listVCArray.firstObject loadDataForFirst];
    }

    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"刷新数据" style:UIBarButtonItemStylePlain target:self action:@selector(reloadData)];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.isNeedCategoryListContainerView) {
        [self.listVCContainerView parentVCWillAppear:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.navigationController.interactivePopGestureRecognizer.enabled = (self.categoryView.selectedIndex == 0);

    if (self.isNeedCategoryListContainerView) {
        [self.listVCContainerView parentVCDidAppear:animated];
    }
}

//这句代码必须加上
- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (self.isNeedCategoryListContainerView) {
        [self.listVCContainerView parentVCWillDisappear:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    if (self.isNeedCategoryListContainerView) {
        [self.listVCContainerView parentVCDidDisappear:animated];
    }
}

/**
 重载数据源：比如从服务器获取新的数据、否则用户对分类进行了排序等
 */
- (void)reloadData {
    NSArray *titles = [self getRandomTitles];
    //先把之前的listView移除掉
    for (UIViewController *vc in self.listVCArray) {
        [vc.view removeFromSuperview];
    }
    [self.listVCArray removeAllObjects];

    for (int i = 0; i < titles.count; i ++) {
        LoadDataListBaseViewController *listVC = [[LoadDataListBaseViewController alloc] initWithStyle:UITableViewStylePlain];
        listVC.view.frame = CGRectMake(i*self.scrollView.bounds.size.width, 0, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
        [self.listVCArray addObject:listVC];
    }

    if (self.isNeedCategoryListContainerView) {
        self.listVCContainerView.listVCArray = self.listVCArray;
        self.listVCContainerView.defaultSelectedIndex = 0;
        [self.listVCContainerView reloadData];
    }else {
        //根据新的数据源重新添加listView
        for (int i = 0; i < titles.count; i ++) {
            LoadDataListBaseViewController *listVC = self.listVCArray[i];
            [self.scrollView addSubview:listVC.view];
        }
        self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width*titles.count, self.scrollView.bounds.size.height);

        //触发首次加载
        [self.listVCArray.firstObject loadDataForFirst];
    }

    //重载之后默认回到0，你也可以指定一个index
    self.categoryView.defaultSelectedIndex = 0;
    self.categoryView.titles = titles;
    [self.categoryView reloadData];
}

- (NSArray <NSString *> *)getRandomTitles {
    NSMutableArray *titles = @[@"红烧螃蟹", @"麻辣龙虾", @"美味苹果", @"胡萝卜", @"清甜葡萄", @"美味西瓜", @"美味香蕉", @"香甜菠萝", @"麻辣干锅", @"剁椒鱼头", @"鸳鸯火锅"].mutableCopy;
    NSInteger randomMaxCount = arc4random()%6 + 5;
    NSMutableArray *resultArray = [NSMutableArray array];
    for (int i = 0; i < randomMaxCount; i++) {
        NSInteger randomIndex = arc4random()%titles.count;
        [resultArray addObject:titles[randomIndex]];
        [titles removeObjectAtIndex:randomIndex];
    }
    return resultArray;
}

#pragma mark - JXCategoryViewDelegate

- (void)categoryView:(JXCategoryBaseView *)categoryView didSelectedItemAtIndex:(NSInteger)index {
    //侧滑手势处理
    self.navigationController.interactivePopGestureRecognizer.enabled = (index == 0);
    if (!self.isNeedCategoryListContainerView) {
        [self.listVCArray[index] loadDataForFirst];
    }
}

- (void)categoryView:(JXCategoryBaseView *)categoryView didClickSelectedItemAtIndex:(NSInteger)index {
    if (self.isNeedCategoryListContainerView) {
        [self.listVCContainerView didClickSelectedItemAtIndex:index];
    }
}

- (void)categoryView:(JXCategoryBaseView *)categoryView didScrollSelectedItemAtIndex:(NSInteger)index {
    if (self.isNeedCategoryListContainerView) {
        [self.listVCContainerView didScrollSelectedItemAtIndex:index];
    }
}

- (void)categoryView:(JXCategoryBaseView *)categoryView scrollingFromLeftIndex:(NSInteger)leftIndex toRightIndex:(NSInteger)rightIndex ratio:(CGFloat)ratio {
    if (self.isNeedCategoryListContainerView) {
        [self.listVCContainerView scrollingFromLeftIndex:leftIndex toRightIndex:rightIndex ratio:ratio];
    }
}

@end
