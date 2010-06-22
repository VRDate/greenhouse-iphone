//
//  OAuthManager.m
//  OAuthSample
//
//  Created by Roy Clarkson on 6/3/10.
//  Copyright 2010 VMware. All rights reserved.
//

#define OAUTH_CONSUMER_KEY		@"mnSPl0mz9gOPhkDaV0d7gA"
#define OAUTH_CONSUMER_SECRET	@"wl2oAHI4ZrAl5zCxPJHLGlPhl8E7ImlcIbyVvW2S0"
#define OAUTH_REQUEST_TOKEN_URL	@"https://api.twitter.com/oauth/request_token"
#define OAUTH_ACCESS_TOKEN_URL	@"https://api.twitter.com/oauth/access_token"
#define OAUTH_AUTHORIZE_URL		@"https://api.twitter.com/oauth/authorize"
#define OAUTH_CALLBACK_URL		@"x-com-springsource-oauthsample://oauth-response"
#define TWITTER_UPDATE_URL		@"http://api.twitter.com/1/statuses/update.json"

#define OAUTH_TOKEN				@"oauth_token"
#define OAUTH_TOKEN_SECRET		@"oauth_token_secret"
#define OAUTH_CALLBACK			@"oauth_callback"
#define OAUTH_VERIFIER			@"oauth_verifier"
#define USER_ID					@"user_id"
#define SCREEN_NAME				@"screen_name"
#define TWITTER_STATUS			@"status"


#import "OAuthManager.h"


static OAuthManager *sharedInstance = nil;

@implementation OAuthManager

#pragma mark -
#pragma mark Class methods
#pragma mark

// This class is configured to function as a singleton. 
// Use this class method to obtain the shared instance of the class.
+ (OAuthManager *)sharedInstance
{
    @synchronized(self)
    {
        if (sharedInstance == nil)
		{
			sharedInstance = [[OAuthManager alloc] init];
		}
    }
	
    return sharedInstance;
}


#pragma mark -
#pragma mark Public methods
#pragma mark

- (void)fetchUnauthorizedRequestToken;
{
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:OAUTH_CONSUMER_KEY
													secret:OAUTH_CONSUMER_SECRET];
	
    NSURL *url = [NSURL URLWithString:OAUTH_REQUEST_TOKEN_URL];
	
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url 
																   consumer:consumer 
																	  token:nil   // we don't have a Token yet
																	  realm:nil   // our service provider doesn't specify a realm
														  signatureProvider:nil]; // use the default method, HMAC-SHA1
	
	[consumer release];
	
	[request setHTTPMethod:@"POST"];
	[request setOAuthParameterName:OAUTH_CALLBACK withValue:OAUTH_CALLBACK_URL];
	
	NSLog(@"%@", request);
	
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	
	[fetcher fetchDataWithRequest:request
						 delegate:self
				didFinishSelector:@selector(requestTokenTicket:didFinishWithData:)
				  didFailSelector:@selector(requestTokenTicket:didFailWithError:)];
	
	[request release];
}

- (void)requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
	if (ticket.didSucceed) 
	{
		NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		
		NSLog(@"%@", responseBody);
		
		OAToken *requestToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		[responseBody release];
		
		[[NSUserDefaults standardUserDefaults] setObject:requestToken.key forKey:OAUTH_TOKEN];
		[[NSUserDefaults standardUserDefaults] setObject:requestToken.secret forKey:OAUTH_TOKEN_SECRET];
		
		[self authorizeRequestToken:requestToken];
		[requestToken release];
	}
}

- (void)requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	NSLog(@"%@", [error localizedDescription]);
}

- (void)authorizeRequestToken:(OAToken *)requestToken;
{
	[requestToken retain];
	NSString *urlString = [NSString stringWithFormat:@"%@?%@=%@", 
						   OAUTH_AUTHORIZE_URL,
						   OAUTH_TOKEN,
						   requestToken.key];
	
	[requestToken release];
	
	NSLog(@"%@", urlString);
	NSURL *url = [NSURL URLWithString:urlString];
	[[UIApplication sharedApplication] openURL:url];
}

- (void)processOauthResponse:(NSURL *)url
{
	NSMutableDictionary* result = [NSMutableDictionary dictionary];
	
	NSArray *pairs = [[url query] componentsSeparatedByString:@"&"];
	
	for (NSString *pair in pairs) 
	{
		NSRange firstEqual = [pair rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
		
		if (firstEqual.location == NSNotFound) 
		{
			continue;
		}
		
		NSString *key = [pair substringToIndex:firstEqual.location];
		NSString *value = [pair substringFromIndex:firstEqual.location+1];
		
		[result setObject:[value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
				   forKey:[key stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	}
	
	[self fetchAccessToken:(NSString *)[result objectForKey:OAUTH_VERIFIER]];
}

- (void)fetchAccessToken:(NSString *)oauthVerifier
{
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:OAUTH_CONSUMER_KEY
													secret:OAUTH_CONSUMER_SECRET];
	
	NSString *oauthToken = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:OAUTH_TOKEN];
	NSString *oauthTokenSecret = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:OAUTH_TOKEN_SECRET];
	
	OAToken *requestToken = [[OAToken alloc] initWithKey:oauthToken secret:oauthTokenSecret];
	
    NSURL *url = [NSURL URLWithString:OAUTH_ACCESS_TOKEN_URL];
	
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url 
																   consumer:consumer 
																	  token:requestToken
																	  realm:nil   // our service provider doesn't specify a realm
														  signatureProvider:nil]; // use the default method, HMAC-SHA1
	
	[consumer release];
	[requestToken release];
	
	[request setHTTPMethod:@"POST"];
	[request setOAuthParameterName:OAUTH_VERIFIER withValue:oauthVerifier];
	
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	
	[fetcher fetchDataWithRequest:request
						 delegate:self
				didFinishSelector:@selector(accessTokenTicket:didFinishWithData:)
				  didFailSelector:@selector(accessTokenTicket:didFailWithError:)];
	
	[request release];
}

- (void)accessTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
	if (ticket.didSucceed) 
	{
		NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		
		OAToken *accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		[[NSUserDefaults standardUserDefaults] setObject:accessToken.key forKey:OAUTH_TOKEN];
		[[NSUserDefaults standardUserDefaults] setObject:accessToken.secret forKey:OAUTH_TOKEN_SECRET];
		[accessToken release];
		
		NSMutableDictionary* result = [NSMutableDictionary dictionary];
		
		NSArray *pairs = [responseBody componentsSeparatedByString:@"&"];
		[responseBody release];
		
		for (NSString *pair in pairs) 
		{
			NSRange firstEqual = [pair rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
			
			if (firstEqual.location == NSNotFound) 
			{
				continue;
			}
			
			NSString *key = [pair substringToIndex:firstEqual.location];
			NSString *value = [pair substringFromIndex:firstEqual.location+1];
			
			[result setObject:[value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
					   forKey:[key stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:[result objectForKey:USER_ID] forKey:USER_ID];
		[[NSUserDefaults standardUserDefaults] setObject:[result objectForKey:SCREEN_NAME] forKey:SCREEN_NAME];
	}
}

- (void)accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	NSLog(@"%@", [error localizedDescription]);
}

- (void)updateStatus:(NSString *)status
{
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:OAUTH_CONSUMER_KEY
													secret:OAUTH_CONSUMER_SECRET];
	
	NSString *oauthToken = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:OAUTH_TOKEN];
	NSString *oauthTokenSecret = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:OAUTH_TOKEN_SECRET];
	
	OAToken *accessToken = [[OAToken alloc] initWithKey:oauthToken secret:oauthTokenSecret];
	
    NSURL *url = [NSURL URLWithString:TWITTER_UPDATE_URL];
	
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url 
																   consumer:consumer 
																	  token:accessToken
																	  realm:nil   // our service provider doesn't specify a realm
														  signatureProvider:nil]; // use the default method, HMAC-SHA1
	
	[consumer release];
	[accessToken release];
	
	[request setHTTPMethod:@"POST"];
	
	OARequestParameter *statusParam = [[OARequestParameter alloc] initWithName:TWITTER_STATUS
																		 value:status];
	
	NSArray *params = [NSArray arrayWithObjects:statusParam, nil];
	[statusParam release];
	
	[request setParameters:params];
	
	NSLog(@"%@", request);
	
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	
	[fetcher fetchDataWithRequest:request
						 delegate:self
				didFinishSelector:@selector(updateStatusTicket:didFinishWithData:)
				  didFailSelector:@selector(updateStatusTicket:didFailWithError:)];
	
	[request release];
}

- (void)updateStatusTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	if (ticket.didSucceed) 
	{
		NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSLog(@"%@", responseBody);
		[responseBody release];
	}
}

- (void)updateStatusTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	NSLog(@"%@", [error localizedDescription]);
}


#pragma mark -
#pragma mark NSObject methods
#pragma mark

+ (id)allocWithZone:(NSZone *)zone 
{
    @synchronized(self) 
	{
        if (sharedInstance == nil) 
		{
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
	
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain 
{
    return self;
}

- (unsigned)retainCount 
{
    return UINT_MAX;  // denotes an object that cannot be released
}

- (oneway void)release 
{
    //do nothing
}

- (id)autorelease 
{
    return self;
}

@end