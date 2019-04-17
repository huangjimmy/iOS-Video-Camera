//
//  ChromeVirtualMachine.m
//  PonyDebugger
//
//  Created by huangshaojun on 7/13/16.
//  Copyright © 2016 yidian. All rights reserved.
//

#import "ChromeVirtualMachine.h"
#import <objc/runtime.h>
#import <objc/message.h>

static char RUNTIME_JS[] = {"function _(a,b,c){"
    "if(Array.isArray(c))return performSelector(a,b,c);"
    "if(typeof(a) == 'number') return performSelector(a.ptr(),b,c); "
    "return performSelector(a,b,[c])"
    "};"
    "Object.prototype.toid=function(){return Instance(this);};Object.prototype.ptr=function(){return Instance(this);};"
    "Object.prototype.performSelector = function(a,b){ return _(this,a,b)};"
    "Object.prototype._ = Object.prototype.performSelector;"
    "Object.prototype.prop = function(a,b){"
    "   if(typeof(b) == 'undefined'){"
    "       return ValueForKey(this,a)"
    "   }"
    "   else{"
    "       return SetValueForKey(this,b,a);"
    "   }"
    "}"
};

@implementation ChromeVirtualMachine

+ (instancetype)sharedInstance{
    static ChromeVirtualMachine *machine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        machine = [[self alloc] init];
    });
    
    return machine;
}

- (id)init{
    self = [super init];
    JSVirtualMachine *virtualMachine = [[JSVirtualMachine alloc] init];
    self.context = [[JSContext alloc] initWithVirtualMachine:virtualMachine];
    
    __weak typeof(self) myself = self;
    
    self.context[@"object_getClass"] = ^(JSValue *value){
        return (id)object_getClass(value.toObject);
    };
    self.context[@"object_getSuperClass"] = ^(JSValue *value){
        return (id)class_getSuperclass(object_getClass(value.toObject));
    };
    self.context[@"class_getSuperclass"] = ^(JSValue *value){
        return (id)class_getSuperclass(value.toObject);
    };
    self.context[@"NSClassFromString"] = ^(JSValue *value){
        return (id)NSClassFromString(value.toString);
    };
    self.context[@"objc_isKindOfClass"] = ^(JSValue *instanceObject, JSValue *classObject){
        return [instanceObject.toObject isKindOfClass:classObject.toObject];
    };
    self.context[@"SetValueForKey"] = ^(JSValue *obj, JSValue *value, JSValue *key){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                id o = obj.toObject;
                NSString *k = key.toString;
                if([o isKindOfClass:[UIView class]]){
                    if([k isEqualToString:@"layer.cornerRadius"]){
                        [[o layer] setCornerRadius:value.toDouble];
                        return;
                    }
                    if([k isEqualToString:@"layer.masksToBounds"]){
                        [[o layer] setMasksToBounds:value.toBool];
                        return;
                    }
                }
                [o setValue:value.toObject forKey:key.toString];
            } @catch (NSException *exception) {
                myself.context.exception = [JSValue valueWithObject:exception inContext:myself.context];
            } @finally {
                
            }
        });
    };
    self.context[@"ValueForKey"] = ^(JSValue *obj, JSValue *key){
        @try {
            id o = obj.toObject;
            NSString *k = key.toString;
            if([o isKindOfClass:[UIView class]]){
                if([k isEqualToString:@"layer.cornerRadius"]){
                    return (id)@([[o layer] cornerRadius]);
                }
                if([k isEqualToString:@"layer.masksToBounds"]){
                    return (id)@([[o layer] masksToBounds]);
                }
            }
            return (id)[obj.toObject valueForKey:key.toString];
        } @catch (NSException *exception) {
            myself.context.exception = [JSValue valueWithObject:exception inContext:myself.context];
        } @finally {
            
        }
    };
    self.context[@"objectDescription"] = ^(JSValue *obj){
        return [obj.toObject description];
    };
    self.context[@"objectDebugDescription"] = ^(JSValue *obj){
        return [obj.toObject debugDescription];
    };
    self.context[@"Instance"] = ^(JSValue *obj){
        return (__bridge NSObject*)(void*)([obj.toNumber unsignedLongValue]);
    };
    self.context[@"objc"] = ^(JSValue *obj){
        return (__bridge NSObject*)(void*)([obj.toNumber unsignedLongValue]);
    };
    self.context[@"UIColor"] = ^(JSValue *r, JSValue *g, JSValue *b, JSValue *alpha){
        return [UIColor colorWithRed:r.toDouble green:g.toDouble blue:b.toDouble alpha:alpha.toDouble];
    };
    self.context[@"rgba"] = ^(JSValue *c, JSValue *alpha){
        int rgb = c.toInt32;
        int r = (rgb >> 16) & 0xFF;
        int g = (rgb >> 8) & 0xFF;
        int b = (rgb) & 0xFF;
        return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:alpha.toDouble];
    };
    self.context[@"rgb"] = ^(JSValue *c){
        int rgb = c.toInt32;
        int r = (rgb >> 16) & 0xFF;
        int g = (rgb >> 8) & 0xFF;
        int b = (rgb) & 0xFF;
        return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
    };
    self.context[@"CGPointMake"] = ^(JSValue *a,JSValue *b){
        return [NSValue valueWithCGPoint:CGPointMake(a.toDouble, b.toDouble)];
    };
    self.context[@"CGSizeMake"] = ^(JSValue *a,JSValue *b){
        return [NSValue valueWithCGSize:CGSizeMake(a.toDouble, b.toDouble)];
    };
    self.context[@"CGRectMake"] = ^(JSValue *a, JSValue *b, JSValue *c, JSValue *d){
        return [NSValue valueWithCGRect:CGRectMake(a.toDouble, b.toDouble, c.toDouble, d.toDouble)];
    };
    self.context[@"UIEdgeInsetsMake"] = ^(JSValue *a, JSValue *b, JSValue *c, JSValue *d){
        return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(a.toDouble, b.toDouble, c.toDouble, d.toDouble)];
    };
    self.context[@"UIOffsetMake"] = ^(JSValue *a, JSValue *b){
        return [NSValue valueWithUIOffset:UIOffsetMake(a.toDouble, b.toDouble)];
    };
    
    self.context[@"performSelector"] = ^(JSValue *this, JSValue *selector, JSValue *arguments){
        id receiver = this.toObject;
        SEL sel = NSSelectorFromString(selector.toString);
        NSArray *args = arguments.toArray;
        NSMethodSignature *methodSig = [receiver methodSignatureForSelector:sel];
        if(methodSig == nil){
            return (id)[NSString stringWithFormat:@"does not recognizer selector %@", selector.toString];
        }
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setTarget:receiver];
        [invocation setSelector:sel];
        void **arg_buffers = malloc(sizeof(void*)*(args.count+1));
        size_t arg_buffers_used = 0;
        
        NSInteger i = 0;
        for(i = 0;i<args.count && i<methodSig.numberOfArguments-2;i++){
            if(args[i]){
                id arg = args[i];
                const char *argumentType = [methodSig getArgumentTypeAtIndex:i+2];
                switch (argumentType[0]) {
                    case '@':
                    case '#':
                    case ':':
                        [invocation setArgument:(&arg) atIndex:i+2];
                        break;
                    case '{':
                        //strut
                    {
                        if(strncmp(argumentType, "{CGRect=", 8) == 0){
                            void *buffer = malloc(sizeof(CGRect));
                            CGRect rect = [(NSValue*)arg CGRectValue];
                            memcpy(buffer, &rect, sizeof(CGRect));
                            arg_buffers[i] = buffer;
                            arg_buffers_used++;
                            [invocation setArgument:(buffer) atIndex:i+2];
                        }
                        else if(strncmp(methodSig.methodReturnType, "{NSRange=", 9) == 0){
                            void *buffer = malloc(sizeof(NSRange));
                            NSRange rect = [(NSValue*)arg rangeValue];
                            memcpy(buffer, &rect, sizeof(NSRange));
                            arg_buffers[i] = buffer;
                            arg_buffers_used++;
                            [invocation setArgument:(buffer) atIndex:i+2];
                        }
                        else if(strncmp(methodSig.methodReturnType, "{CGPoint=", 9) == 0){
                            void *buffer = malloc(sizeof(CGPoint));
                            CGPoint rect = [(NSValue*)arg CGPointValue];
                            memcpy(buffer, &rect, sizeof(CGPoint));
                            arg_buffers[i] = buffer;
                            arg_buffers_used++;
                            [invocation setArgument:(buffer) atIndex:i+2];
                        }
                        else if(strncmp(methodSig.methodReturnType, "{CGSize=", 8) == 0){
                            void *buffer = malloc(sizeof(CGSize));
                            CGSize rect = [(NSValue*)arg CGSizeValue];
                            memcpy(buffer, &rect, sizeof(CGSize));
                            arg_buffers[i] = buffer;
                            arg_buffers_used++;
                            [invocation setArgument:(buffer) atIndex:i+2];
                        }
                        else if(strncmp(methodSig.methodReturnType, "{UIEdgeInsets=", 14) == 0){
                            void *buffer = malloc(sizeof(UIEdgeInsets));
                            UIEdgeInsets rect = [(NSValue*)arg UIEdgeInsetsValue];
                            memcpy(buffer, &rect, sizeof(UIEdgeInsets));
                            arg_buffers[i] = buffer;
                            arg_buffers_used++;
                            [invocation setArgument:(buffer) atIndex:i+2];
                        }
                        else if(strncmp(methodSig.methodReturnType, "{CGSize=", 8) == 0){
                            void *buffer = malloc(sizeof(CGSize));
                            CGSize rect = [(NSValue*)arg CGSizeValue];
                            memcpy(buffer, &rect, sizeof(CGSize));
                            arg_buffers[i] = buffer;
                            arg_buffers_used++;
                            [invocation setArgument:(buffer) atIndex:i+2];
                        }
                        else if(strncmp(methodSig.methodReturnType, "{UIOffset=", 10) == 0){
                            void *buffer = malloc(sizeof(UIOffset));
                            UIOffset rect = [(NSValue*)arg UIOffsetValue];
                            memcpy(buffer, &rect, sizeof(UIOffset));
                            arg_buffers[i] = buffer;
                            arg_buffers_used++;
                            [invocation setArgument:(buffer) atIndex:i+2];
                        }
                        
                    }
                        break;
#define SET_ARGUMENT(c, char, charValue, i) case ((#c)[0]): \
                    { \
                        char c = [(NSNumber*)arg charValue]; \
                        [invocation setArgument:(&c) atIndex:i+2]; \
                        \
                    } break
                        
                        SET_ARGUMENT(c, char, charValue, i);
                        SET_ARGUMENT(C, unsigned char, unsignedCharValue, i);
                    
                        SET_ARGUMENT(s, short, shortValue, i);
                        SET_ARGUMENT(S, unsigned short, unsignedShortValue, i);
                        
                        SET_ARGUMENT(i, int, intValue, i);
                        SET_ARGUMENT(I, unsigned int, unsignedIntValue, i);
                        
                        SET_ARGUMENT(l, long, longValue, i);
                        SET_ARGUMENT(L, unsigned long, unsignedLongValue, i);
                        
                        SET_ARGUMENT(q, long long, longLongValue, i);
                        SET_ARGUMENT(Q, unsigned long long, unsignedLongLongValue, i);
                        
                        SET_ARGUMENT(f, float, floatValue, i);
                        SET_ARGUMENT(D, double, doubleValue, i);
                        SET_ARGUMENT(B, BOOL, boolValue, i);
                    default:
                        break;
                }
                
            }
        }
        
        if(i != args.count){
            return (id)[NSString stringWithFormat:@"argument mismatch, %zd given, %zd expected", args.count, methodSig.numberOfArguments-2];
        }
        
        void* ret = (void*)NULL;

        [invocation invoke];
        
        for (size_t i=0; i<arg_buffers_used; i++) {
            free(arg_buffers[i]);
        }
        free(arg_buffers);
        
        if(strncmp(methodSig.methodReturnType, "{CGRect=", 8) == 0){
            {
                ret = malloc(sizeof(CGRect));
                [invocation getReturnValue:ret];
            }
            CGRect rect = *(CGRect*)ret;
            free(ret);
            return (id)[NSValue valueWithCGRect:rect];
        }
        if(strncmp(methodSig.methodReturnType, "{NSRange=", 9) == 0){
            {
                ret = malloc(sizeof(NSRange));
                [invocation getReturnValue:ret];
            }
            NSRange value = *(NSRange*)ret;
            free(ret);
            return (id)[NSValue valueWithRange:value];
        }
        if(strncmp(methodSig.methodReturnType, "{CGPoint=", 9) == 0){
            {
                ret = malloc(sizeof(CGPoint));
                [invocation getReturnValue:ret];
            }
            CGPoint value = *(CGPoint*)ret;
            free(ret);
            return (id)[NSValue valueWithCGPoint:value];
        }
        if(strncmp(methodSig.methodReturnType, "{CGSize=", 8) == 0){
            {
                ret = malloc(sizeof(CGSize));
                [invocation getReturnValue:ret];
            }
            CGSize value = *(CGSize*)ret;
            free(ret);
            return (id)[NSValue valueWithCGSize:value];
        }
        if(strncmp(methodSig.methodReturnType, "{UIEdgeInsets=", 14) == 0){
            {
                ret = malloc(sizeof(UIEdgeInsets));
                [invocation getReturnValue:ret];
            }
            UIEdgeInsets value = *(UIEdgeInsets*)ret;
            free(ret);
            return (id)[NSValue valueWithUIEdgeInsets:value];
        }
        if(strncmp(methodSig.methodReturnType, "{CGSize=", 8) == 0){
            {
                ret = malloc(sizeof(CGSize));
                [invocation getReturnValue:ret];
            }
            CGSize value = *(CGSize*)ret;
            free(ret);
            return (id)[NSValue valueWithCGSize:value];
        }
        if(strncmp(methodSig.methodReturnType, "{UIOffset=", 10) == 0){
            {
                ret = malloc(sizeof(UIOffset));
                [invocation getReturnValue:ret];
            }
            UIOffset value = *(UIOffset*)ret;
            free(ret);
            return (id)[NSValue valueWithUIOffset:value];
        }
        
        if(methodSig.methodReturnType[0] != 'v'){
            [invocation getReturnValue:&ret];
        }
        else{
            return (id)nil;
        }
        
        switch (methodSig.methodReturnType[0]) {
            case 'c':
                return (id)[NSNumber numberWithChar:*(char*)&ret];
                break;
            case 'C':
                return (id)[NSNumber numberWithUnsignedChar:*(unsigned char*)&ret];
                break;
            case 's':
                return (id)[NSNumber numberWithShort:*(short*)&ret];
                break;
            case 'S':
                return (id)[NSNumber numberWithUnsignedShort:*(unsigned short*)&ret];
                break;
            case 'i':
                return (id)[NSNumber numberWithInt:*(int*)&ret];
                break;
            case 'I':
                return (id)[NSNumber numberWithUnsignedInt:*(unsigned int*)&ret];
                break;
            case 'l':
                return (id)[NSNumber numberWithLong:*(long*)&ret];
                break;
            case 'L':
                return (id)[NSNumber numberWithUnsignedLong:*(unsigned long*)&ret];
                break;
            case 'q':
                return (id)[NSNumber numberWithLongLong:*(long long*)&ret];
                break;
            case 'Q':
                return (id)[NSNumber numberWithUnsignedLongLong:*(unsigned long long*)&ret];
                break;
            case 'f':
                return (id)[NSNumber numberWithFloat:*(float*)&ret];
                break;
            case 'd':
                return (id)[NSNumber numberWithDouble:*(double*)&ret];
                break;
            case 'B':
                return (id)[NSNumber numberWithBool:*(BOOL*)&ret];
                break;
            default:
                break;
        }
        /*
         
         char	c
         unsigned char	C
         short	s
         unsigned short	S
         int	i
         unsigned int	I
         long	l
         unsigned long	L
         long long	q
         unsigned long long	Q
         float	f
         double	d
         void	v
         id	@
         Class	#
         SEL	:
         char*	*
         BOOL   B
         */
        return (__bridge id)ret;
        
    };
    
    NSString *runtime = [NSString stringWithUTF8String:RUNTIME_JS];
    [self.context evaluateScript:runtime];
    
    return self;
}

- (JSValue*)evaluateScript:(NSString*)script{
    return [self.context evaluateScript:script];
}

@end
