//
//  JGson.m
//  JGson_Example
//
//  Created by justin on 2020/1/16.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

#import "JGson.h"
#import <objc/runtime.h>
#import "JGsonConst.h"
#import "JGsonObject.h"

@implementation JGson

-(id)fromDict:(NSDictionary *)dict modelClass:(Class)modelClass
{
    if(dict == nil)
    {
        NSLog(@"JGson error: %@", NULL_NSDIC);
        
        return nil;
    }
    
    if(![modelClass isSubclassOfClass:[JGsonObject class]])
    {
        NSLog(@"JGson error: %@", NOT_SUBCLASS_OF_JGSONOBJECT);
        
        return nil;
    }
    
    id model = [[modelClass alloc] init];
    
    unsigned int outCount;
    
    objc_property_t *properties = class_copyPropertyList(modelClass, &outCount);
    
    for (unsigned int i = 0; i < outCount; i++)
    {
        objc_property_t property = properties[i];
        
        const char * name = property_getName(property);
        
//        const char * propertyAttr = property_getAttributes(property);
        
        unsigned int attrCount = 0;
        
        objc_property_attribute_t *attrs = property_copyAttributeList(property, &attrCount);
        
        NSString *pName = [[NSString alloc]initWithUTF8String:name];
        
        JGsonObject* jGsonObject = (JGsonObject *)model;
        NSDictionary *keyMap = [jGsonObject getKeyMapper];
        
        NSString *pIvar;
        
        NSString *pType;
        
        NSString *pProtocol;
        
        bool pRead = false;
        
        for(unsigned int j = 0; j < attrCount; j ++)
        {
            objc_property_attribute_t attr = attrs[j];
            
            const char * name = attr.name;
            const char * value = attr.value;
            
            NSString *nameStr = [[NSString alloc]initWithUTF8String:name];
            
            NSString *valueStr = [[NSString alloc]initWithUTF8String:value];
            
            if([nameStr isEqualToString:@"V"])
            {
                pIvar = valueStr;
            }
            else if([nameStr isEqualToString:@"R"])
            {
                pRead = YES;
            }
            else if([nameStr isEqualToString:@"T"])
            {
                if([valueStr containsString:@"<"])
                {
                    NSString *patternType = @"(?<=\')[A-Za-z]+(?=<)";
                    
                    NSRegularExpression *reqularType = [[NSRegularExpression alloc]initWithPattern:patternType options:NSRegularExpressionCaseInsensitive error: nil];
                    
                    NSRange textRange = NSMakeRange(0, valueStr.length);
                    
                    NSArray<NSTextCheckingResult *> *resultsType = [reqularType matchesInString:valueStr options:0 range:textRange];
                    
                    if(resultsType.count != 0)
                    {
                        pType = [valueStr substringWithRange:resultsType.firstObject.range];
                    }
                    
                    NSString *patternProtocol = @"(?<=<')[A-Za-z]+(?=>)";
                    
                    NSRegularExpression *regularProtocol = [[NSRegularExpression alloc] initWithPattern:patternProtocol options:NSRegularExpressionCaseInsensitive error:nil];
                    
                    NSArray<NSTextCheckingResult *> *resultsProtocol = [regularProtocol matchesInString:valueStr options:0 range:textRange];
                    
                    if(resultsProtocol.count != 0)
                    {
                        pProtocol = [valueStr substringWithRange:resultsProtocol.firstObject.range];
                    }
                }
                else if([valueStr containsString:@"@"] && valueStr.length != 1)
                {
                    pType = [valueStr substringWithRange:NSMakeRange(2, valueStr.length-3)];
                }
                else
                {
                    pType = valueStr;
                }
            }
        }
        
        free(attrs);
        
        id dictValue;
        
        if(keyMap != nil && [keyMap objectForKey:pName] != nil)
        {
            NSString* keyValue = [keyMap objectForKey:pName];
            
            dictValue = [dict objectForKey:keyValue];
        }
        else
        {
            dictValue = [dict objectForKey:pName];
        }
        
        if(!pRead && dictValue != nil)
        {
            if([dictValue isKindOfClass:[NSDictionary class]] && ![pType isEqualToString:@"NSDictionary"])
            {
                Class c = NSClassFromString(pType);
                
                if(c != nil)
                {
                    id m = [self fromDict:dictValue modelClass:c];
                    
                    [model setValue:m forKey:pName];
                }
                else
                {
                    NSLog(@"JGson error: %@", NO_INSTANCE_CLASS);
                }
            }
            else if([dictValue isKindOfClass:[NSArray class]])
            {
                bool ifModelArr = NO;
                
                NSArray* arr = (NSArray *)dictValue;
                
                if(arr.count != 0)
                {
                    if([arr.firstObject isKindOfClass:[NSDictionary class]])
                    {
                        if(![pProtocol isEqualToString:@"NSDictionary"])
                        {
                            ifModelArr = YES;
                            
                            NSMutableArray *valueArr = [[NSMutableArray alloc]init];
                            
                            Class mC = NSClassFromString(pProtocol);
                            
                            if(mC != nil)
                            {
                                for(NSDictionary *d in arr)
                                {
                                    id mD = [self fromDict:d modelClass:mC];
                                    
                                    [valueArr addObject:mD];
                                }
                                
                                [model setValue:valueArr forKey:pName];
                            }
                            else
                            {
                                NSLog(@"JGson error: %@", NO_INSTANCE_CLASS);
                            }
                        }
                    }
                }
                
                if(!ifModelArr)
                {
                    [model setValue:dictValue forKey:pName];
                }
            }
            else
            {
                [model setValue:dictValue forKey:pName];
            }
        }
    }
    
    free(properties);
    
    return model;
}

- (id)fromJson:(NSString *)json modelClass:(Class)modelClass
{
    NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    
    if(jsonData == nil)
    {
        NSLog(@"JGson error: %@", NULL_NSDATA);
        
        return nil;
    }
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
    
    id m = [self fromDict:dict modelClass:modelClass];
    
    return m;
}

@end
