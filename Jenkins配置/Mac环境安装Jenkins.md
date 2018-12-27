# Mac环境安装Jenkins

## 安装链接
主链接：https://www.jianshu.com/p/48f68686d114

参考链接：https://www.jianshu.com/p/91e8f571fc2b

## 配置步骤

1. 安装插件:Keychains and Provisioning Profiles Management & Xcode integration。路径：系统管理->插件管理->Available
2. keychain文件上传准备，路径/Users/管理员用户名/Library/Keychains，拷贝出来，login.keychain-db改为login.keychain。
3. Profiles文件上传准备，Xcode调试Provisioning Profile存储路径 : 

		/Users/userName/Library/MobileDevice/Provisioning Profiles


4. 上传Certificate和Profile文件。路径：系统管理->Keychains and Provisioning Profiles Management。
![](./profile_config.png)

5. Jenkins Profiles文件路径设置，把机器上的profiles文件copy到新建文件路径：dir=/Users/Shared/Jenkins/Library/MobileDevice/Provisioning Profiles，赋权chmod -R 777 dir。

4. 将Jenkins用户加管理员权限。路径：系统偏好设置->用户与群组。
![](./jenkins1.png) 
![](./jenkins2.png)

## Jenkins使用Xcode插件打包配置
![](./plugin_pack.png)

## Jenkins使用shell脚本打包配置
![](./shell_pack.png)

## 注意事项
1. 文件权限问题解决方案:chmod -R 777 dir
2. 一定要添加Jenkins账户到管理员权限，为了jenkins访问本机的keychain和profile文件。操作方法：进入mac系统偏好设置 — 用户与群组 — 其他用户 — jenkins ，勾选允许用户管理这台电脑，并右键选择高级选项，将名字改为jenkins

## 问题
1.  bundleID问题
		
		error: No profiles for 'com.globetel.bundleID' were found: Xcode couldn't find any iOS App Development provisioning profiles matching 'com.globetel.bundleID'. Automatic signing is disabled and unable to generate a profile. To enable automatic signing, pass -allowProvisioningUpdates to xcodebuild. (in target 'Project')

修改bundleID与profile匹配
