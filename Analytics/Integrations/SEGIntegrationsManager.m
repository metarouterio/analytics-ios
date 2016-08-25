//
//  SEGIntegrationsManager.m
//  Analytics
//
//  Created by Tony Xiao on 6/23/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SEGAnalytics.h"
#import "SEGUtils.h"
#import "SEGHTTPRequest.h"
#import "SEGAnalyticsConfiguration.h"
#import "SEGIntegration.h"
#import "SEGIntegrationFactory.h"
#import "SEGDispatchQueue.h"
#import "SEGIntegrationsManager.h"

@interface SEGIntegrationsManager ()

@property (nonatomic, strong) NSDictionary *cachedSettings;
@property (nonatomic, strong) SEGAnalyticsConfiguration *configuration;
@property (nonatomic, strong) NSMutableArray *messageQueue;
@property (nonatomic, strong) SEGHTTPRequest *settingsRequest;
@property (nonatomic, strong) NSArray *factories;
@property (nonatomic, strong) NSMutableDictionary *integrations;
@property (nonatomic, strong) SEGDispatchQueue *dispatchQueue;
@property (nonatomic) volatile BOOL initialized;

@end

typedef void (^IntegrationBlock)(NSString * _Nonnull key, id<SEGIntegration> _Nonnull integration);


@implementation SEGIntegrationsManager

@synthesize cachedSettings = _cachedSettings;

- (instancetype)initWithAnalytics:(SEGAnalytics *)analytics {
    if (self = [super init]) {
        _analytics = analytics;
        _configuration = analytics.configuration;
        _factories = [self.configuration.factories copy];
        _integrations = [NSMutableDictionary dictionaryWithCapacity:self.factories.count];
        _messageQueue = [[NSMutableArray alloc] init];
        _dispatchQueue = [[SEGDispatchQueue alloc] initWithLabel:@"com.segment.analytics.integrations"];
        
        // Refresh setings upon entering foreground
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshSettings)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [self refreshSettings];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSURL *)settingsURL {
    return SEGAnalyticsURLForFilename(@"analytics.settings.v2.plist");
}


- (NSDictionary *)cachedSettings {
    if (!_cachedSettings)
        _cachedSettings = [[NSDictionary alloc] initWithContentsOfURL:[self settingsURL]] ?: @{};
    return _cachedSettings;
}

- (void)setCachedSettings:(NSDictionary *)settings {
    _cachedSettings = [settings copy];
    NSURL *settingsURL = [self settingsURL];
    if (!_cachedSettings) {
        // [@{} writeToURL:settingsURL atomically:YES];
        return;
    }
    [_cachedSettings writeToURL:settingsURL atomically:YES];
    
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        [self updateIntegrationsWithSettings:settings[@"integrations"] callback:nil];
    });
}

- (void)updateIntegrationsWithSettings:(NSDictionary *)projectSettings callback:(void (^)(void))block {
    for (id<SEGIntegrationFactory> factory in self.factories) {
        NSString *key = [factory key];
        NSDictionary *integrationSettings = [projectSettings objectForKey:key];
        if (integrationSettings) {
            id<SEGIntegration> integration = [factory createWithSettings:integrationSettings forAnalytics:self.analytics];
            if (integration != nil) {
                ((NSMutableDictionary *)self.integrations)[key] = integration;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SEGAnalyticsIntegrationDidStart object:key userInfo:nil];
        } else {
            SEGLog(@"No settings for %@. Skipping.", key);
        }
    }
    
    [self.dispatchQueue async:^{
        self.initialized = true;
        [self flushMessageQueue];
        if (block) { block(); }
    }];
}

- (void)refreshSettings {
    if (self.settingsRequest) {
        return;
    }
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:
        [NSString stringWithFormat:@"https://cdn.segment.com/v1/projects/%@/settings", self.configuration.writeKey]]];
    urlRequest.HTTPMethod = @"GET";
    [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    SEGLog(@"%@ Sending API settings request: %@", self, urlRequest);
    
    self.settingsRequest = [SEGHTTPRequest startWithURLRequest:urlRequest
                                                     completion:^{
        [self.dispatchQueue async:^{
            SEGLog(@"%@ Received API settings response: %@", self, self.settingsRequest.responseJSON);
            
            if (self.settingsRequest.error == nil) {
                [self setCachedSettings:self.settingsRequest.responseJSON];
            }
            self.settingsRequest = nil;
        }];
    }];
}

- (void)flushMessageQueue {
    if (!self.initialized) {
        return;
    }
    NSLog(@"Fluhing messag equeue %@", self.messageQueue);
    for (IntegrationBlock block in self.messageQueue) {
        for (NSString *key in self.integrations) {
            block(key, self.integrations[key]);
        }
    }
    [self.messageQueue removeAllObjects];
}

- (void)filterIntegrations:(SEL)selector block:(void(^)(id<SEGIntegration> _Nonnull integration))block {
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([integration respondsToSelector:selector]) {
            block(integration);
        }
    }];
}

- (void)eachIntegration:(IntegrationBlock _Nonnull)block {
    if (self.initialized) {
        for (NSString *key in self.integrations) {
            block(key, self.integrations[key]);
        }
    } else {
        [self.messageQueue addObject:[block copy]];
    }
}

- (BOOL)isIntegration:(NSString *)key enabledInOptions:(NSDictionary *)options forSelector:(SEL)selector {
    if (![self.integrations[key] respondsToSelector:selector]) {
        return NO;
    }
    if (options[key]) {
        return [options[key] boolValue];
    } else if (options[@"All"]) {
        return [options[@"All"] boolValue];
    } else if (options[@"all"]) {
        return [options[@"all"] boolValue];
    }
    return YES;
}

- (BOOL)isTrackEvent:(NSString *)event enabledForIntegration:(NSString *)key inPlan:(NSDictionary *)plan {
    // TODO: Implement tracking plan filtering for events sent to Segment as well
    if (plan[@"track"][event]) {
        return [plan[@"track"][event][@"enabled"] boolValue];
    }
    return YES;
}

@end

@implementation SEGIntegrationsManager (SEGIntegration)

- (void)identify:(NSString *)userId anonymousId:(NSString *)anonymousId traits:(NSDictionary *)traits context:(NSDictionary *)context integrations:(NSDictionary *)integrations {
    SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:userId
                                                                 anonymousId:anonymousId
                                                                      traits:traits
                                                                     context:context
                                                                integrations:integrations];
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([self isIntegration:key enabledInOptions:payload.integrations forSelector:@selector(identify:)]) {
            [integration identify:payload];
        }
    }];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context integrations:(NSDictionary *)integrations {
    SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:event
                                                           properties:properties
                                                              context:context
                                                         integrations:integrations];
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([self isIntegration:key enabledInOptions:payload.integrations forSelector:@selector(track:)]) {
            if ([self isTrackEvent:payload.event enabledForIntegration:key inPlan:self.cachedSettings[@"plan"]]) {
                [integration track:payload];
            }
        }
    }];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context integrations:(NSDictionary *)integrations {
    SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:screenTitle
                                                            properties:properties
                                                               context:context
                                                          integrations:integrations];
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([self isIntegration:key enabledInOptions:payload.integrations forSelector:@selector(screen:)]) {
            // TODO: Respect the tracking plan here
            [integration screen:payload];
        }
    }];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits context:(NSDictionary *)context integrations:(NSDictionary *)integrations {
    SEGGroupPayload *payload = [[SEGGroupPayload alloc] initWithGroupId:groupId
                                                                 traits:traits
                                                                context:context
                                                           integrations:integrations];
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([self isIntegration:key enabledInOptions:payload.integrations forSelector:@selector(group:)]) {
            // TODO: Respect the tracking plan here
            [integration group:payload];
        }
    }];
}

- (void)alias:(NSString *)newId context:(NSDictionary *)context integrations:(NSDictionary *)integrations {
    SEGAliasPayload *payload = [[SEGAliasPayload alloc] initWithNewId:newId
                                                              context:context
                                                         integrations:integrations];
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([self isIntegration:key enabledInOptions:payload.integrations forSelector:@selector(alias:)]) {
            // TODO: Respect the tracking plan here
            [integration alias:payload];
        }
    }];
}

- (void)reset {
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([integration respondsToSelector:@selector(reset)]) {
            [integration reset];
        }
    }];
}

- (void)flush {
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([integration respondsToSelector:@selector(flush)]) {
            [integration flush];
        }
    }];
}

- (void)receivedRemoteNotification:(NSDictionary *)userInfo {
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([integration respondsToSelector:@selector(receivedRemoteNotification:)]) {
            [integration receivedRemoteNotification:userInfo];
        }
    }];
}

- (void)failedToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([integration respondsToSelector:@selector(failedToRegisterForRemoteNotificationsWithError:)]) {
            [integration failedToRegisterForRemoteNotificationsWithError:error];
        }
    }];
}

- (void)registeredForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([integration respondsToSelector:@selector(registeredForRemoteNotificationsWithDeviceToken:)]) {
            [integration registeredForRemoteNotificationsWithDeviceToken:deviceToken];
        }
    }];
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([integration respondsToSelector:@selector(handleActionWithIdentifier:forRemoteNotification:)]) {
            [integration handleActionWithIdentifier:identifier forRemoteNotification:userInfo];
        }
    }];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([integration respondsToSelector:@selector(applicationDidFinishLaunching:)]) {
            [integration applicationDidFinishLaunching:notification];
        }
    }];
}

- (void)applicationDidEnterBackground {
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([integration respondsToSelector:@selector(applicationDidEnterBackground)]) {
            [integration applicationDidEnterBackground];
        }
    }];
}

- (void)applicationWillEnterForeground {
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([integration respondsToSelector:@selector(applicationWillEnterForeground)]) {
            [integration applicationWillEnterForeground];
        }
    }];
}

- (void)applicationWillTerminate {
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([integration respondsToSelector:@selector(applicationWillTerminate)]) {
            [integration applicationWillTerminate];
        }
    }];
}

- (void)applicationWillResignActive {
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([integration respondsToSelector:@selector(applicationWillResignActive)]) {
            [integration applicationWillResignActive];
        }
    }];
}

- (void)applicationDidBecomeActive {
    [self eachIntegration:^(NSString * _Nonnull key, id<SEGIntegration>  _Nonnull integration) {
        if ([integration respondsToSelector:@selector(applicationDidBecomeActive)]) {
            [integration applicationDidBecomeActive];
        }
    }];
}

@end