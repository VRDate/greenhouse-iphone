//
//  Copyright 2010-2012 the original author or authors.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//
//  GHEventSessionsViewController.h
//  Greenhouse
//
//  Created by Roy Clarkson on 8/2/10.
//

#import <UIKit/UIKit.h>
#import "GHPullRefreshTableViewController.h"

@class Event;
@class EventSession;
@class GHEventSessionDetailsViewController;

@interface GHEventSessionsViewController : GHPullRefreshTableViewController

@property (nonatomic, strong) NSIndexPath *visibleIndexPath;
@property (nonatomic, strong) NSArray *sessions;
@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) GHEventSessionDetailsViewController *sessionDetailsViewController;

- (EventSession *)eventSessionForIndexPath:(NSIndexPath *)indexPath;
- (BOOL)displayLoadingCell;

@end