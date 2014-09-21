//
//  NSObject+GCKVO.m
//  GCExtension
//
//  Created by njgarychow on 9/16/14.
//  Copyright (c) 2014 zhoujinqiang. All rights reserved.
//

#import "NSObject+GCKVO.h"

#import "GCMacro.h"
#import "NSObject+GCAccessor.h"

@class GCKVOObserver;
@class GCKVOObserverDeallocationHanlder;


@interface NSObject (GCKVOProperty)
@property (nonatomic, strong) GCKVOObserver* observer;
@property (nonatomic, strong) GCKVOObserverDeallocationHanlder* deallocationHandler;

- (GCKVOObserver *)theObserver;
- (GCKVOObserverDeallocationHanlder *)theDeallocationHandler;

@end











@interface GCKVOObserverWrapper : NSObject

@property (nonatomic, weak) NSObject* observeTarget;
@property (nonatomic, copy) NSString* keyPath;
@property (nonatomic, copy) GCKVOBlock handlerBlock;

@end

@implementation GCKVOObserverWrapper
@end








typedef void(^GCObserverDeallocationHandler)();
@interface GCKVOObserverDeallocationHanlder : NSObject

- (void)addHandler:(GCObserverDeallocationHandler)handler;

@end

@implementation GCKVOObserverDeallocationHanlder {
    NSMutableArray* _handlers;
}

- (void)addHandler:(GCObserverDeallocationHandler)handler {
    if (!_handlers) {
        _handlers = [NSMutableArray array];
    }
    [_handlers addObject:[handler copy]];
}

- (void)dealloc {
    for (GCObserverDeallocationHandler handler in _handlers) {
        handler();
    }
}

@end


@interface GCKVOObserver : NSObject

@property (nonatomic, strong) NSMutableSet* wrappers;

@end

@implementation GCKVOObserver

- (id)init {
    if (self = [super init]) {
        _wrappers = [NSMutableSet set];
    }
    return self;
}

- (void)startObserveObject:(NSObject *)observeTarger
                forKeyPath:(NSString *)keyPath
                   options:(NSKeyValueObservingOptions)options
                usingBlock:(GCKVOBlock)handler {
    
    GCKVOObserverWrapper* wrapper = [self _wrapperForObserveTarget:observeTarger keyPath:keyPath];
    if (!wrapper) {
        GCKVOObserverWrapper* wrapper = [[GCKVOObserverWrapper alloc] init];
        wrapper.observeTarget = observeTarger;
        wrapper.keyPath = keyPath;
        wrapper.handlerBlock = handler;
        [_wrappers addObject:wrapper];
        __weak typeof(self) weak_self = self;
        [[observeTarger theDeallocationHandler] addHandler:^{
            [weak_self stopObserveObject:observeTarger forKeyPath:keyPath];
        }];
        [observeTarger addObserver:self forKeyPath:keyPath options:options context:nil];
    }
    wrapper.handlerBlock = handler;
}

- (void)stopObserveObject:(NSObject *)observeTarger
               forKeyPath:(NSString *)keyPath {
    
    GCKVOObserverWrapper* wrapper = [self _wrapperForObserveTarget:observeTarger keyPath:keyPath];
    if (wrapper) {
        [_wrappers removeObject:wrapper];
        [observeTarger removeObserver:self forKeyPath:keyPath context:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    GCKVOObserverWrapper* wrapper = [self _wrapperForObserveTarget:object keyPath:keyPath];
    wrapper.handlerBlock(change);
}

- (void)dealloc {
    for (GCKVOObserverWrapper* wrapper in _wrappers) {
        [self stopObserveObject:wrapper.observeTarget forKeyPath:wrapper.keyPath];
    }
}

- (GCKVOObserverWrapper *)_wrapperForObserveTarget:(NSObject *)observeTarget keyPath:(NSString *)keyPath {
    for (GCKVOObserverWrapper* wrapper in _wrappers) {
        if ((wrapper.observeTarget == observeTarget) &&
            ([wrapper.keyPath isEqual:keyPath])){
            
            return wrapper;
        }
    }
    
    return nil;
}

@end






@implementation NSObject (GCKVOProperty)
@dynamic observer;
@dynamic deallocationHandler;

- (GCKVOObserver *)theObserver {
    if (!self.observer) {
        self.observer = [[GCKVOObserver alloc] init];
    }
    return self.observer;
}
- (GCKVOObserverDeallocationHanlder *)theDeallocationHandler {
    if (!self.deallocationHandler) {
        self.deallocationHandler = [[GCKVOObserverDeallocationHanlder alloc] init];
    }
    return self.deallocationHandler;
}


+ (void)load {
    [self extensionAccessorGenerator];
}

+ (NSArray *)extensionAccessorNonatomicStrongPropertyNames {
    return @[@"observer",
             @"deallocationHandler"];
}

@end







@implementation NSObject (GCKVO)


- (void)startObserveObject:(NSObject *)observeTarger
                forKeyPath:(NSString *)keyPath
                usingBlock:(GCKVOBlock)handler {
    
    [self startObserveObject:observeTarger
                  forKeyPath:keyPath
                     options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                  usingBlock:handler];
}
- (void)startObserveObject:(NSObject *)observeTarger
                forKeyPath:(NSString *)keyPath
                   options:(NSKeyValueObservingOptions)options
                usingBlock:(GCKVOBlock)handler {
    
    NSParameterAssert(observeTarger != nil);
    NSParameterAssert(keyPath != nil);
    NSParameterAssert(handler != nil);
    
    [[self theObserver] startObserveObject:observeTarger
                                 forKeyPath:keyPath
                                    options:options
                                 usingBlock:handler];
}

- (void)stopObserveObject:(NSObject *)observeTarger
               forKeyPath:(NSString *)keyPath {
    
    [[self theObserver] stopObserveObject:observeTarger forKeyPath:keyPath];
}

@end

