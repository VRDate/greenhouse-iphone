//
//  EventSessionTweetsViewController.h
//  Greenhouse
//
//  Created by Roy Clarkson on 7/26/10.
//  Copyright 2010 VMware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TweetsViewController.h"
#import "Event.h"
#import "EventSession.h"


@interface EventSessionTweetsViewController : TweetsViewController <DataViewDelegate>
{

}

@property (nonatomic, retain) Event *event;
@property (nonatomic, retain) EventSession *session;

- (void)refreshView;
- (void)fetchData;

@end
