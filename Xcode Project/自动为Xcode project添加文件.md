# 自动为Xcode project添加文件
### 背景
一般将文件或者资源直接拷贝到xcode工程的指定文件夹里，Xcode工程面板不会有任何效果，需要多一步手动添加引用(refernece)的操作。文件多的话，手动添加很麻烦，有没有像cocoapods那样自动添加文件/资源的方式？

### 方案
Ruby的xcodeproj库可以解决这个问题，xcodeproj可读/写Xcode工程配置文件：project.pbxproj。

1. 安装

		sudo gem install xcodeproj


### 参考资料
1. [简单教程](https://www.jianshu.com/p/cca701e1d87c)
2. [概念说明](https://draveness.me/bei-xcodeproj-keng-de-zhe-ji-tian.html)
2. [xcodeproj文档](https://www.rubydoc.info/gems/xcodeproj/Xcodeproj/Project/Object/PBXProject)
3. [Cocoapods中的Xcodeproj](https://github.com/CocoaPods/Xcodeproj)