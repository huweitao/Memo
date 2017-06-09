
## 背景知识
高级加密标准（Advanced Encryption Standard，缩写：AES），在密码学中又称Rijndael加密法，是美国联邦政府采用的一种区块加密标准。但是严格地说，AES和Rijndael加密法并不完全一样（虽然在实际应用中二者可以互换），因为Rijndael加密法可以支持更大范围的区块和密钥长度：AES的区块长度固定为128bit（如果数据块及密钥长度不足时，会补齐），密钥长度则可以是128bit，192bit或256bit；而Rijndael使用的密钥和区块长度可以是32位的整数倍，以128位为下限，256比特为上限。加密过程中使用的密钥是由Rijndael密钥生成方案产生。
##需要注意的问题
引入`#import <CommonCrypto/CommonCryptor.h>`后，还需要两个参数来完成加密，一个是秘钥key，第二个是秘钥向量iv。

### 1. AES秘钥key的生成
iOS端没有类似android的[秘钥生成器接口](http://blog.csdn.net/playboyanta123/article/details/8044837)，目前暂时使用的是产生16位随机字符串，方法如下：

```
static const NSString *randomAlphabet = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
+ (NSString *)generateSecureRandomStringLength:(NSUInteger)len
		{
			NSMutableString *randomString = [NSMutableString stringWithCapacity:len];
			for (int i = 0; i < len; i++) {
        	[randomString appendFormat: @"%C", [randomAlphabet characterAtIndex:arc4random_uniform((u_int32_t)[randomAlphabet length])]];
		}
		return randomString;
}
```      
为了满足随机的要求，可以在得到随机字符串后再做一次[Fisher-Yates Shuffle](https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle)（[洗牌算法](http://www.cnblogs.com/tudas/p/3-shuffle-algorithm.html?utm_source=tuicool&utm_medium=referral)），代码如下：

```
	+ (NSString *)shuffleAlphabet:(NSString *)alphabet
	{
    	// Get the characters into a C array for efficient shuffling
    	NSUInteger numberOfCharacters = [alphabet length];
    	unichar *characters = calloc(numberOfCharacters, sizeof(unichar));
    	[alphabet getCharacters:characters range:NSMakeRange(0, numberOfCharacters)];
    
    	// Perform a Fisher-Yates shuffle
    	for (NSUInteger i = 0; i < numberOfCharacters; ++i) {
        	NSUInteger j = (arc4random_uniform((uint32_t)(numberOfCharacters - i)) + i);
        	unichar c = characters[i];
        	characters[i] = characters[j];
        	characters[j] = c;
    	}
    
    	// Turn the result back into a string
    		NSString *result = [NSString stringWithCharacters:characters length:numberOfCharacters];
    		free(characters);
    		return result;
	}
```
  
### 2.秘钥向量iv
iv是配合AES的加密模式来使用的，加大密文被破解的难度。（一般有CBC、ECB、CTR、OCF和CFB[五种加密模式](http://www.cnblogs.com/starwolf/p/3365834.html?utm_source=tuicool&utm_medium=referral)，这几种加密模式的对比参看[这篇文章](http://www.cnblogs.com/happyhippy/archive/2006/12/23/601353.html)）。

### 3.接口参数

```
		CCCryptorStatus CCCrypt(
		CCOperation op,        /* kCCEncrypt, etc. */
		CCAlgorithm alg,        /* kCCAlgorithmAES128, etc. */
		CCOptions options,      /* kCCOptionPKCS7Padding, etc. */
		const void *key,
		size_t keyLength,
    	const void *iv,         /* optional initialization vector*/
    	const void *dataIn,     /* optional per op and alg */
    	size_t dataInLength,
    	void *dataOut,          /* data RETURNED here */
    	size_t dataOutAvailable,
    	size_t *dataOutMoved)
```   
    
几个关键参数的说明

a. kCCEncrypt：选择kCCAlgorithmAES128即可；

b. iv： 如果使用ECB方式加密就不需要初始化向量，设置为nil就可以了。如果不是采用ECB，那么除了密钥之外，加密方和解密方的初始化向量也必须一致。

c. options： 选择填充模式，一般是kCCOptionPKCS7Padding（iOS这边的选项就kCCOptionPKCS7Padding和kCCOptionECBMode两种)。为了后台能使用统一的加解密逻辑，android的AES加密可使用PKCS5Padding模式，因为PKCS7Padding和PKCS5Padding是兼容的。（填充模式可以看[这篇文章](http://www.cnblogs.com/midea0978/articles/1437257.html)）。
