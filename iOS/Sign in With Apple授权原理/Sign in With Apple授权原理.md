# Sign In With Apple授权原理

## 背景
尽管WWDC 2019上已经介绍过Sign In With Apple在app中的接入方式，但是对于接口返回的数据有什么用，怎么用都没有提及和说明。本文就从接口的返回的数据分析Apple的授权原理与这种模式的安全性。

## Sign In With Apple返回数据结构
Sign In With Apple返回的数据是一个类 [ASAuthorizationAppleIDCredential](https://developer.apple.com/documentation/authenticationservices/asauthorizationappleidcredential)，其中比较重要的就是 identityToken 和 authorizationCode 两个字段。对于 identityToken 字段的解释就是JWT

## 相关概念
Sign In With Apple通过下发 JSON Web Token 来授权第三方app登录的模式与OAuth2.0框架提供的授权概念很相似：第三方获取到的 Access Token 只能在有限时间内访问指定的资源。结合 OAuth2.0 的[四种授权模式](http://www.ruanyifeng.com/blog/2019/04/oauth-grant-types.html)和 [Endpoints](https://developer.apple.com/documentation/signinwithapplerestapi) 文档提供的接口和返回参数，能判断 Apple 使用的是OAuth2.0的第一种授权方式：authorization-code 。

### OAuth2.0
OAuth2.0 是一个RFC协议，可以参考RFC6749，它定义了一个安全认证框架。简单的说包含 authentication 和 authorization。 而openID connect 是基于这个框架上的认证实现。JSON Web Token是也只是授权的一种实现方式.

### JSON Web Token(JWT)
JSON Web Token，简称JWT，其本质是一个 Access Token，存储于客户端。相较于存储于服务端的 Session，使用JWT除了可减轻服务端的内存压力外，JWT也不存在跨域访问的问题，一般只要密钥安全，JWT的安全性就有保障。JWT经常用于设计用户认证和授权系统，甚至实现应用的单点登录。

### JWT数据结构
JWT由三部分组成：

1. header（头部）:头部内容会说明类型和使用的算法;![](./header.png)
2. payload（载荷）:载荷中有五个字段是由JWT的标准所定义，其他字段可根据需要自行添加![](./payload.png)
3. signature（签名）:将header和payload通过header里面的alg指定的加密算法(默认是 HMAC SHA256，Apple是RS256)得到的一个字符串。![](./signature.png)


## Sign In With Apple JWT解析
从 Apple 授权接口返回的数据中与身份验证有关的

1. Sign In With Apple 返回的JWT结构：

		eyJraWQiOiJBSURPUEsxIiwiYWxnIjoiUlMyNTYifQ.eyJpc3MiOiJodHRwczovL2FwcGxlaWQuYXBwbGUuY29tIiwiYXVkIjoiY29tLmV4YW1wbGUuYXBwbGUtc2FtcGxlY29kZS5qdWljZUhDOFJFMlJWODYiLCJleHAiOjE1NjE5NzMxMDgsImlhdCI6MTU2MTk3MjUwOCwic3ViIjoiMDAwODA2LmU3ZGIzOGMwYjgzOTQyZGJiYmZkNjI2ODFlM2FkOTIyLjAzMTgifQ.GDZ2iGD7qOxRAsrPv7CWiaWFMB1oY-pvpL4IgcU2iF2hBFBHIFXG1fuDqmNEOYVUE03lp3KiPe4NbxJ0FKeHagKSfv-xV-w-34ARqHkZidPAQxQwMSIyyqQwj4NA0k5jz4xUs3JMt76m8BufdfSXPPqrMZrvMw4HrBgqjrBFg83dGmp3zDf1GJuG5qMG5r-yuSZewbQT2aMTRalm-7078fpm5G81tOKyPK8mw5gE4V5tY4SIhK0_BkFPE6Y2fxExp7KtJXUjxATLAqUB7Lpg6-v7UtoOW5n_CBsTijFtilraQOQMF7ASsuhCGHZGMu-XbAr-BDqPDXlP2QD-M4cjHA	
		
2. JWT解析可知，加密算法为RS256，需要Apple的公钥来验证签名
![](./jwt_encode_decode.png)

3. [Auth Service API](https://developer.apple.com/documentation/signinwithapplerestapi/fetch_apple_s_public_key_for_verifying_token_signature) 提供了获取公钥的参数，返回的数据如下：

		{"keys":[
	        {
	            "kty":"RSA",
	            "kid":"AIDOPK1",
	            "use":"sig",
	            "alg":"RS256",
	            "n":"lxrwmuYSAsTfn-lUu4goZSXBD9ackM9OJuwUVQHmbZo6GW4Fu_auUdN5zI7Y1dEDfgt7m7QXWbHuMD01HLnD4eRtY-RNwCWdjNfEaY_esUPY3OVMrNDI15Ns13xspWS3q-13kdGv9jHI28P87RvMpjz_JCpQ5IM44oSyRnYtVJO-320SB8E2Bw92pmrenbp67KRUzTEVfGU4-obP5RZ09OxvCr1io4KJvEOjDJuuoClF66AT72WymtoMdwzUmhINjR0XSqK6H0MdWsjw7ysyd_JhmqX5CAaT9Pgi0J8lU_pcl215oANqjy7Ob-VMhug9eGyxAWVfu_1u6QJKePlE-w",
	            "e":"AQAB"
	        }
        ]}
keys中的字段说明可以从 [Apple JWTSet](https://developer.apple.com/documentation/signinwithapplerestapi/jwkset/keys) 文档获取

4. 生成公钥，通过参数n(Modulus)和e(Exponent)能生成对应的公钥（[RSA公钥与模数 指数的关系](https://www.cnblogs.com/masako/p/7660418.html)，[RSA标准](https://crypto.stackexchange.com/questions/18031/how-to-find-modulus-from-a-rsa-public-key)），具体可参考代码实现。

## JWT验证代码实现(Python)
1. 代码[链接](https://github.com/huweitao/PythonScripts/blob/master/AppleAuthVerify.py)
2. 输入：JWT 和 Audience
3. 运行方式如下：
	
		python AppleAuthVerify.py jwt aud

## 参考资料
1. [JWT入门](http://www.ruanyifeng.com/blog/2018/07/json_web_token-tutorial.html)
2. [NodeJS解析JWT](https://www.jianshu.com/p/2036987a22fb)
3. [Python解析JWT](https://segmentfault.com/a/1190000010312468)
4. [JSON Web Token (JWT)](https://tools.ietf.org/html/draft-ietf-oauth-json-web-token-32)
5. [在Web应用间安全地传递信息](http://blog.leapoahead.com/2015/09/06/understanding-jwt/)
6. [八幅漫画理解使用JSON Web Token设计单点登录系统](http://blog.leapoahead.com/2015/09/07/user-authentication-with-jwt/)
7. [理解OAuth 2.0](http://www.ruanyifeng.com/blog/2014/05/oauth_2_0.html)

## 相关链接
1. [JWT在线验证](https://jwt.io/)
2. [在线JSON解析](https://www.json.cn/)
3. [Base64 to Hex](https://cryptii.com/pipes/base64-to-hex)
4. [进制转换](https://tool.lu/hexconvert/)