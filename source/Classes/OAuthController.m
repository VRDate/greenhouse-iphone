//
//  OAuthController.m
//  Greenhouse
//
//  Created by Roy Clarkson on 9/16/10.
//  Copyright 2010 VMware, Inc. All rights reserved.
//

#import "OAuthController.h"
#import "OAuthManager.h"


@implementation OAuthController

- (void)request:(OAServiceTicket *)ticket didFailWithError:(NSError *)error didFailDelegate:(id)delegate didFailSelector:(SEL)selector
{
	[_dataFetcher release];
	
	_didFailDelegate = delegate;
	_didFailSelector = selector;
	_error = error;
	
	DLog(@"%@", [error localizedDescription]);
	
	if ([error code] == NSURLErrorUserCancelledAuthentication)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil 
														message:@"You are not authorized to view the content from greenhouse.com. Please sign out and reauthorize the app." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:@"Sign Out", nil];
		[alert show];
		[alert release];
	}
	else 
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil 
														message:@"An error occurred while connecting to the server." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
	}	
}


#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[_didFailDelegate performSelector:_didFailSelector withObject:_error];
	
	if (buttonIndex == 1)
	{
		// sign out
		[[OAuthManager sharedInstance] removeAccessToken];
		[appDelegate showAuthorizeViewController];		
	}
}

@end