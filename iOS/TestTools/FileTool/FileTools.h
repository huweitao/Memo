//
//  FileTools.h
//  VoiceHelper
//
//  Created by huweitao on 16/10/20.
//  Copyright © 2016年 huweitao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileTools : NSObject

// file name does not need suffix
+ (NSString *)pathForFileName:(NSString *)name;
+ (BOOL)fileExistsForName:(NSString *)name;
+ (BOOL)createFileForName:(NSString *)name;
+ (BOOL)deleteFileForName:(NSString *)name;
+ (BOOL)writeFileData:(NSData *)data forName:(NSString *)name;
+ (BOOL)appendFileData:(NSData *)data forName:(NSString *)name;
+ (BOOL)fileHasBytesForName:(NSString *)name;

+ (NSString *)localPath;
+ (BOOL)localFileExists;

// 单个文件大小/k
+ (float)fileSizeAtPath:(NSString *)filePath;
+ (void)printFileNameAtDirectory:(NSString *)directory;

#warning methods blow are configurations and all need to be overrided as extension or subclass
//+ (NSString *)fileDir;
//+ (NSString *)defaultFileName;
//+ (NSString *)suffix;

@end
