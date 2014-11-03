//
//  UICollectionViewDelegateAndDataSourceImplementProxy.h
//  GCExtension
//
//  Created by njgarychow on 11/3/14.
//  Copyright (c) 2014 zhoujinqiang. All rights reserved.
//

#import <GCExtension/GCExtension.h>

#import "UIScrollViewDelegateImplementationProxy.h"

@interface UICollectionViewDelegateAndDataSourceImplementationProxy : UIScrollViewDelegateImplementationProxy

@property (nonatomic, weak) UICollectionView* owner;

- (instancetype)init;

@end
