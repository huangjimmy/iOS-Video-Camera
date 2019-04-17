//
//  PDDatabaseDomainController.m
//  PonyDebugger
//
//  Created by HUANG,Shaojun on 7/12/16.
//  Copyright © 2016 yidian. All rights reserved.
//

#import "PDDatabaseDomainController.h"
#import "PDDatabaseDomain.h"
#import "PDDatabaseTypes.h"
#import <sqlite3.h>

@interface PDDebugger ()

- (void)_resolveService:(NSNetService*)service;
- (void)_addController:(PDDomainController *)controller;
- (NSString *)_domainNameForController:(PDDomainController *)controller;
- (BOOL)_isTrackingDomainController:(PDDomainController *)controller;

@end

@implementation PDDatabaseDomainController

+ (Class)domainClass{
    return [PDDatabaseDomain class];
}

+ (PDDatabaseDomainController *)defaultInstance;
{
    static PDDatabaseDomainController *defaultInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultInstance = [[PDDatabaseDomainController alloc] init];
    });
    return defaultInstance;
}

- (void)enable{
    [[PDDebugger defaultInstance] performSelector:@selector(_addController:) withObject:self];
}


// Enables database tracking, database events will now be delivered to the client.
- (void)domain:(PDDatabaseDomain *)domain enableWithCallback:(void (^)(id error))callback{
    
    callback(nil);
    
    NSFileManager *fm;
    fm = [NSFileManager defaultManager];
    NSString *path = NSHomeDirectory();
    NSDirectoryEnumerator<NSString *> *subdirs = [fm enumeratorAtPath:path];
    for(NSString *subdir in subdirs){
        NSString *subpath = [path stringByAppendingPathComponent:subdir];
        BOOL isSubDirDir;
        BOOL exists = [fm fileExistsAtPath:subpath isDirectory:&isSubDirDir];
        if(exists){
            if(!isSubDirDir){
                //check if this is a sqlite3 data file
                [self domain:domain getDatabaseTableNamesWithDatabaseId:subpath callback:^(NSArray *tableNames, id error){
                    if(tableNames.count == 0)return;
                    
                    PDDatabaseDatabase *db = [[PDDatabaseDatabase alloc] init];
                    db.identifier = subpath;
                    db.domain = @"";
                    db.name = [subpath substringFromIndex:path.length+1];
                    db.version = @"1.0";
                    [(PDDatabaseDomain*)self.domain addDatabaseWithDatabase:db];
                }];
            }
        }
    }

}

// Disables database tracking, prevents database events from being sent to the client.
- (void)domain:(PDDatabaseDomain *)domain disableWithCallback:(void (^)(id error))callback{
    callback(nil);
}
- (void)domain:(PDDatabaseDomain *)domain getDatabaseTableNamesWithDatabaseId:(NSString *)databaseId callback:(void (^)(NSArray *tableNames, id error))callback{
    sqlite3 *dbHandle;
    if (sqlite3_open([databaseId UTF8String], &dbHandle)==SQLITE_OK) {
        NSMutableArray *tableNames = [[NSMutableArray alloc] init];
        NSString *sqlQuery = @"SELECT name FROM sqlite_master WHERE type='table'";
        sqlite3_stmt * statement;
        if (sqlite3_prepare_v2(dbHandle, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                char *name = (char*)sqlite3_column_text(statement, 0);
                NSString *tableName = [NSString stringWithUTF8String:name];
                [tableNames addObject:tableName];
            }  
        }
        sqlite3_close(dbHandle);
        callback(tableNames, nil);
    }
    else{
        callback(@[], nil);
    }
}

- (void)domain:(PDDatabaseDomain *)domain executeSQLWithDatabaseId:(NSString *)databaseId query:(NSString *)query callback:(void (^)(NSArray *columnNames, NSArray *values, PDDatabaseError *sqlError, id error))callback{
    sqlite3 *dbHandle;
    if (sqlite3_open([databaseId UTF8String], &dbHandle)==SQLITE_OK) {
        NSMutableArray *columnNames = [[NSMutableArray alloc] init];
        NSMutableArray *columnValues = [[NSMutableArray alloc] init];
        sqlite3_stmt * statement;
        if (sqlite3_prepare_v2(dbHandle, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                if(columnNames.count == 0){
                    int i = 0;
                    for(i=0;i<sqlite3_column_count(statement);i++){
                        const char *c_columnName = sqlite3_column_name(statement, i);
                        if(c_columnName){
                            NSString *columnName = [NSString stringWithUTF8String:c_columnName];
                            [columnNames addObject:columnName];
                        }
                        else{
                            break;
                        }
                    }
                }//if(columnNames.length == 0)
                int i = 0;
                for(i=0;i<columnNames.count;i++){
                    int t = sqlite3_column_type(statement, i);
                    switch (t) {
                        case SQLITE_INTEGER:
                        {
                            int v = sqlite3_column_int(statement, i);
                            [columnValues addObject:[NSNumber numberWithInt:v]];
                        }
                            break;
                        case SQLITE_FLOAT:
                        {
                            double v = sqlite3_column_double(statement, i);
                            [columnValues addObject:[NSNumber numberWithDouble:v]];
                        }
                            break;
                        case SQLITE_BLOB:
                        {
                            unsigned int size = sqlite3_column_bytes(statement, i);
                            if(size > 1024){
                                size = 1024;
                            }
                            const void *cv = sqlite3_column_blob(statement, i);
                            NSData *data = [NSData dataWithBytes:cv length:size];
                            [columnValues addObject:[data description]];
                        }
                            break;
                        case SQLITE_NULL:
                            [columnValues addObject:[NSNull null]];
                            break;
                        case SQLITE3_TEXT:
                        {
                            const void *cv = sqlite3_column_text(statement, i);
                            NSString *value = [NSString stringWithUTF8String:cv];
                            [columnValues addObject:value];
                        }
                            break;
                        default:
                            break;
                    }
                    
                }
            }
        }
        sqlite3_close(dbHandle);
        callback(columnNames, columnValues, nil, nil);
    }
    else{
        callback(@[], @[], nil, nil);
    }
    
}
@end
