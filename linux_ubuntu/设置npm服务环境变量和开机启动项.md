## 设置npm服务环境变量和开机启动项

### 设置环境变量
操作系统(CentOS\Ubuntu\linux)中都会有一个PATH环境变量，想必大家都知道，当系统调用一个命令的时候，就会在PATH变量中注册的路径中寻找，如果注册的路径中有就调用，否则就提示命令没找到[link](https://segmentfault.com/a/1190000002478924)。[Linux设置环境变量](https://www.cnblogs.com/lihao-blog/p/6945040.html),[Linux 64位机器上设置环境变量](https://blog.csdn.net/winsunxu/article/details/12030731)

	-> export PATH=$PATH: # 将 /usr/bin 追加到 PATH 变量中
	-> export NODE_PATH="/usr/lib/node_modules;/usr/local/lib/node_modules" #指定 NODE_PATH 变量


#### NODE_PATH问题
*NODE_PATH* 就是NODE中用来寻找模块所提供的路径注册环境变量。我们可以使用上面的方法指定*NODE_PATH*环境变量。并且用‘;’分割多个不同的目录。

#### 加载时机
关于 node 的包加载机制我就不在这里废话了。*NODE_PATH*中的路径被遍历是发生在
从项目的根位置递归搜寻 *node_modules* 目录，直到文件系统根目录的 *node_modules*，如果还没有查找到指定模块的话，就会去 *NODE_PATH*中注册的路径中查找。

### 设置开机启动项
1. */etc/rc.local*.
这里一定要注意，etc/rc.local 中的开机启动项配置的命令一定不能有错（比如空文件夹或者路径错误等，这些问题会导致从出错的那一行开始，后面的命令都不执行）

2. */etc/profile*.
在profile文件中设置node和npm的全局路径，如果不是全局安装，需要添加下面几行，这样保障可以直接调用node npm命令。

		export NODE_HOME=/home/va/node-v8.1.0-linux-x64
		export PATH=$PATH:$NODE_HOME/bin
		export NODE_PATH=$NODE_HOME/lib/node_modules
		
		
写入完毕保存后，运行 source profile使文件生效

### rc.local怎么加log追踪

如果以上都配置好了，启动还是有问题，就是env问题(/usr/bin/env: node: No such file or directory)，建议加上log排查[from stackoverflow](https://askubuntu.com/questions/434242/where-is-log-file-from-rc-local)。

	exec 2> /tmp/rc.local.log      # send stderr from 	rc.local to a log file
	exec 1>&2                      # send stdout to 	the same log file
	set -x                         # tell sh to display commands before execution
	
### ubuntu开机启动其他应用
1. 添加开机启动项
	
		Startup Applications->Add->shell脚本
2. shell脚本

		#!/bin/sh
		sleep 1s
		/usr/bin/firefox localhost:8064
		
3. firefox全屏
	全屏设置：显示 -> 旋转屏幕
	
	全屏插件：

		https://addons.mozilla.org/zh-CN/firefox/addon/abduction/ 
