//
//  UserInfoViewController.m
//  Coding_iOS
//
//  Created by Ease on 15/3/18.
//  Copyright (c) 2015年 Coding. All rights reserved.
//

#import "UserInfoViewController.h"
#import "Coding_NetAPIManager.h"

#import "MJPhotoBrowser.h"
#import "UsersViewController.h"
#import "ConversationViewController.h"
#import "UserTweetsViewController.h"
#import "AddUserViewController.h"
#import "SettingViewController.h"

#import "RDVTabBarController.h"
#import "RDVTabBarItem.h"

#import "ODRefreshControl.h"

#import "UserInfoTextCell.h"
#import "UserInfoIconCell.h"

#import "StartImagesManager.h"
#import "EaseUserHeaderView.h"
#import <APParallaxHeader/UIScrollView+APParallaxHeader.h>

@interface UserInfoViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) UITableView *myTableView;
@property (strong, nonatomic) EaseUserHeaderView *headerView;
@property (nonatomic, strong) ODRefreshControl *refreshControl;

@end

@implementation UserInfoViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (_isRoot) {
        self.title = @"我";
        _curUser = [Login curLoginUser]? [Login curLoginUser]: [User userWithGlobalKey:@""];
        
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settingBtn_Nav"] style:UIBarButtonItemStylePlain target:self action:@selector(settingBtnClicked:)] animated:NO];
        [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addUserBtn_Nav"] style:UIBarButtonItemStylePlain target:self action:@selector(addUserBtnClicked:)] animated:NO];
        
    }else{
        self.title = _curUser.name;
    }
    
    //    添加myTableView
    _myTableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        tableView.backgroundColor = kColorTableSectionBg;
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [tableView registerClass:[UserInfoTextCell class] forCellReuseIdentifier:kCellIdentifier_UserInfoTextCell];
        [tableView registerClass:[UserInfoIconCell class] forCellReuseIdentifier:kCellIdentifier_UserInfoIconCell];
        [self.view addSubview:tableView];
        [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        if (_isRoot) {
            UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, CGRectGetHeight(self.rdv_tabBarController.tabBar.frame), 0);
            tableView.contentInset = insets;
            tableView.scrollIndicatorInsets = insets;
        }
        tableView;
    });
    __weak typeof(self) weakSelf = self;
    _headerView = [EaseUserHeaderView userHeaderViewWithUser:_curUser image:[StartImagesManager shareManager].curImage.image];
    _headerView.userIconClicked = ^(){
        [weakSelf userIconClicked];
    };
    _headerView.fansCountBtnClicked = ^(){
        [weakSelf fansCountBtnClicked];
    };
    _headerView.followsCountBtnClicked = ^(){
        [weakSelf followsCountBtnClicked];
    };
    _headerView.followBtnClicked = ^(){
        [weakSelf followBtnClicked];
    };
    [_myTableView addParallaxWithView:_headerView andHeight:CGRectGetHeight(_headerView.frame)];

    _refreshControl = [[ODRefreshControl alloc] initInScrollView:self.myTableView];
    [_refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
}

- (BOOL)isMe{
    return [_curUser.global_key isEqualToString:[Login curLoginUser].global_key];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)dealloc
{
    _myTableView.delegate = nil;
    _myTableView.dataSource = nil;
}


- (void)refresh{
    __weak typeof(self) weakSelf = self;
    [[Coding_NetAPIManager sharedManager] request_UserInfo_WithObj:_curUser andBlock:^(id data, NSError *error) {
        [weakSelf.refreshControl endRefreshing];
        if (data) {
            weakSelf.curUser = data;
            weakSelf.headerView.curUser = data;
            weakSelf.title = _isRoot? @"我": weakSelf.curUser.name;
            [weakSelf.myTableView reloadData];
        }
    }];
}

#pragma mark Table M
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 3;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger row = 0;
    if (section == 0) {
        row = 3;
    }else if (section == 1){
        row = 1;
    }else if (section == 2){
        row = 2;
    }
    return row;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0) {
        UserInfoTextCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_UserInfoTextCell forIndexPath:indexPath];
        switch (indexPath.row) {
            case 0:
                [cell setTitle:@"所在地" value:_curUser.location];
                break;
            case 1:
                [cell setTitle:@"座右铭" value:_curUser.slogan];
                break;
            default:
                [cell setTitle:@"个性标签" value:_curUser.tags_str];
                break;
        }
        [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kPaddingLeftWidth];
        return cell;
    }else{
        UserInfoIconCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_UserInfoIconCell forIndexPath:indexPath];
        if (indexPath.section == 1) {
            [cell setTitle:@"详细信息" icon:@"user_info_detail"];
        }else{
            if (indexPath.row == 0) {
                [cell setTitle:[self isMe]? @"我的项目": @"Ta的项目" icon:@"user_info_project"];
            }else{
                [cell setTitle:[self isMe]? @"我的冒泡": @"Ta的冒泡" icon:@"user_info_tweet"];
            }
        }
        [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kPaddingLeftWidth];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat cellHeight = 0;
    if (indexPath.section == 0) {
        cellHeight = [UserInfoTextCell cellHeight];
    }else{
        cellHeight = [UserInfoIconCell cellHeight];
    }
    return cellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 20.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreen_Width, 20)];
    footerView.backgroundColor = [UIColor colorWithHexString:@"0xe5e5e5"];
    if (section == 0) {
        [footerView addLineUp:YES andDown:NO andColor:tableView.separatorColor];
    }
    return footerView;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Btn Clicked
- (void)fansCountBtnClicked{
    if (_curUser.id.integerValue == 93) {//Coding官方账号
        return;
    }
    UsersViewController *vc = [[UsersViewController alloc] init];
    vc.curUsers = [Users usersWithOwner:_curUser Type:UsersTypeFollowers];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)followsCountBtnClicked{
    if (_curUser.id.integerValue == 93) {//Coding官方账号
        return;
    }
    UsersViewController *vc = [[UsersViewController alloc] init];
    vc.curUsers = [Users usersWithOwner:_curUser Type:UsersTypeFriends_Attentive];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)userIconClicked{
//        显示大图
    MJPhoto *photo = [[MJPhoto alloc] init];
    photo.url = [_curUser.avatar urlWithCodePath];
    
    MJPhotoBrowser *browser = [[MJPhotoBrowser alloc] init];
    browser.currentPhotoIndex = 0;
    browser.photos = [NSArray arrayWithObject:photo];
    [browser show];
}

- (void)messageBtnClicked{
    ConversationViewController *vc = [[ConversationViewController alloc] init];
    vc.myPriMsgs = [PrivateMessages priMsgsWithUser:_curUser];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)followBtnClicked{
    __weak typeof(self) weakSelf = self;
    [[Coding_NetAPIManager sharedManager] request_FollowedOrNot_WithObj:_curUser andBlock:^(id data, NSError *error) {
        if (data) {
            weakSelf.curUser.followed = [NSNumber numberWithBool:!_curUser.followed.boolValue];
            weakSelf.headerView.curUser = weakSelf.curUser;
            if (weakSelf.followChanged) {
                weakSelf.followChanged(weakSelf.curUser);
            }
        }
    }];
}

- (void)goToTweets{
    UserTweetsViewController *vc = [[UserTweetsViewController alloc] init];
    vc.curTweets = [Tweets tweetsWithUser:_curUser];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark Nav
- (void)settingBtnClicked:(id)sender{
    SettingViewController *vc = [[SettingViewController alloc] init];
    vc.myUser = self.curUser;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)addUserBtnClicked:(id)sender{
    AddUserViewController *vc = [[AddUserViewController alloc] init];
    vc.type = AddUserTypeFollow;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
