//
//  JGson.h
//  JGson_Example
//
//  Created by justin on 2020/1/16.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JGson : NSObject

-(id)fromJson:(NSString *)json modelClass:(Class)modelClass;

-(id)fromDict:(NSDictionary *)dict modelClass:(Class)modelClass;

@end

NS_ASSUME_NONNULL_END
