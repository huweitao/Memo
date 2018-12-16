//
//  FileTools.m
//  VoiceHelper
//
//  Created by huweitao on 16/10/20.
//  Copyright © 2016年 huweitao. All rights reserved.
//

#import "FileTools.h"

@implementation FileTools

+ (NSString *)pathForFileName:(NSString *)name
{
    if (!name) {
        name = [self defaultFileName];
    }
    NSString *documentDirectory = [self fileDirectory];
    return [documentDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",name,[self suffix]]];
}

+ (BOOL)fileExistsForName:(NSString *)name
{
    if (!name) {
        name = [self defaultFileName];
    }
    NSString *filePath = [self pathForFileName:name];
    if (![[self fileManager] fileExistsAtPath:filePath]) {
        return NO;
    }
    else {
        return YES;
    }
}

+ (BOOL)createFileForName:(NSString *)name
{
    if ([self fileExistsForName:name]) {
        return YES;
    }
    if (!name) {
        name = [self defaultFileName];
    }
    NSString *filePath = [self pathForFileName:name];
    if (![[self fileManager] fileExistsAtPath:filePath]) {
        NSError *err;
        if (![[self fileManager] createDirectoryAtPath:[self fileDirectory] withIntermediateDirectories:YES attributes:nil error:&err]) {
            NSLog(@"Error createDirectoryAtPath %@",err);
        }
        if (![[self fileManager] createFileAtPath:filePath contents:nil attributes:nil]) {
            return NO;
        }
    }
    NSLog(@"Create File Path : %@",filePath);
    return YES;
}

+ (BOOL)deleteFileForName:(NSString *)name
{
    if (![self fileExistsForName:name]) {
        return YES;
    }
    if (!name) {
        name = [self defaultFileName];
    }
    NSString *fileFullPath = [self pathForFileName:name];
    BOOL bRet = [[self fileManager] fileExistsAtPath:fileFullPath];
    if (bRet) {
        NSError *err;
        return [[self fileManager] removeItemAtPath:fileFullPath error:&err];
    }
    else {
        return YES;
    }
}

+ (BOOL)writeFileData:(NSData *)data forName:(NSString *)name
{
    if (!data) {
        return NO;
    }
    if (!name) {
        name = [self defaultFileName];
    }
    
    NSString *filePath = [self pathForFileName:name];
    if ([self fileExistsForName:name]) {
        [self deleteFileForName:name];
    }
    if ([self createFileForName:name]) {
        [data writeToFile:filePath atomically:YES];
        return YES;
    };
    return NO;
}

+ (BOOL)appendFileData:(NSData *)data forName:(NSString *)name
{
    if (![self fileExistsForName:name]) {
        return NO;
    }
    if (!data) {
        return NO;
    }
    if (!name) {
        name = [self defaultFileName];
    }
    
    //写文件
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:[self pathForFileName:name]];
    [fh seekToEndOfFile];
    [fh writeData:data];
    [fh closeFile];
    return YES;
}

+ (BOOL)fileHasBytesForName:(NSString *)name
{
    if (!name) {
        name = [self defaultFileName];
    }
    if ([self fileHasBytesForName:name]) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:[self pathForFileName:name]];
        NSUInteger length = [[fileHandle availableData] length]; // 获取数据长度
        [fileHandle closeFile];
        if (length == 0) {
            return NO;
        }
        return YES;
    }
    return NO;
}

+ (NSString *)localPath
{
    return [self pathForFileName:[self defaultFileName]];
}

+ (BOOL)localFileExists
{
    return [self fileExistsForName:[self defaultFileName]];
}

+ (float)fileSizeAtPath:(NSString *)filePath
{
    if ([[self fileManager] fileExistsAtPath:filePath]){
        return [[[self fileManager] attributesOfItemAtPath:filePath error:nil] fileSize] / ((1024.0));
    }
    return 0.0;
}

+ (void)printFileNameAtDirectory:(NSString *)directory
{
    NSError *error = nil;
    // fileList便是包含有该文件夹下所有文件的文件名及文件夹名的数组
    NSArray *fileList = [[self fileManager] contentsOfDirectoryAtPath:directory error:&error];
    NSLog(@"文件路径 -> %@\n所有文件 -> %@",directory,fileList);
}

#pragma mark - Need override

+ (NSString *)fileDir
{
    return @"defaultDir";
}

+ (NSString *)defaultFileName
{
    return @"defaultFileName";
}

+ (NSString *)suffix
{
    return @"txt";
}

#pragma mark - Private

+ (NSString *)fileDirectory
{
    if (![self isValidName:[self fileDir]]) {
        return nil;
    }
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [docDir stringByAppendingPathComponent:[self fileDir]];
    return filePath;
}

+ (BOOL)isValidName:(NSString *)name
{
    if (name && [name length] > 0) {
        return YES;
    }
    return NO;
}

+ (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}

@end
