##npm和nodejs环境安装
###全局安装
安装在电脑的系统环境中，直接安装即可，但是nodejs和npm的依赖包可能会和python或者其他依赖库冲突

****
方法1，默认版本全局安装

a. brew install node

b. brew install npm

可能导致安装的node和npm不是最新版本

方法2，指定版本全局安装

****
*1.* ubantu安装方式 [参考链接1](http://blog.csdn.net/wh211212/article/details/53039286),[参考链接2](https://www.jianshu.com/p/32057c07a076)

	curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
	sudo apt-get install -y nodejs

指定安装的node版本，顺带会把npm安装上，优势是就是能够指定安装node和npm版本

****
*2.* centos安装方式 [参考链接](http://blog.csdn.net/yongjiutongmi53151/article/details/53996575)

	curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
	yum install -y nodejs

一行命令，全自动搞定。

###局部安装
安装在指定文件夹中([linux环境](http://cnodejs.org/topic/555468cc7cabb7b45ee6ba88),[ubuntu环境](https://blog.csdn.net/w20101310/article/details/73135388))，node和npm环境只在安装的文件夹起作用，不影响电脑的全局环境，解决包依赖产生的冲突。但是需要设置全局调用的软连接（ln -s命令），而且运行命令的方式需要带路径。

	创建软连接的命令如下：
	ln -s / /home/good/linkname  
	
***                      
ln的链接分软链接和硬链接两种：

1. 软链接：“ln –s 源文件 目标文件”，只会在选定的位置上生成一个文件的镜像，不会占用磁盘空间，类似与windows的快捷方式。
2. 硬链接：ln源文件目标文件，没有参数-s， 会在选定的位置上生成一个和源文件大小相同的文件，无论是软链接还是硬链接，文件都保持同步变化。
***	

####安装步骤：

1. 下载：
	
		cd /home/va
		wget https://nodejs.org/dist/v8.1.0/node-v8.1.0-linux-x64.tar.xz

2. 解压:

		tar -xvf node-v8.1.0-linux-x64.tar.xz
		
3. 查看当前环境和node版本

		cd /node-v8.1.0-linux-x64/bin
		pwd
		./node -v

4. 设置全局调用方式:

		Linux:
		ln -s /root/node-v0.12.2-linux-x64/bin/node /usr/local/bin/node
		ln -s /root/node-v0.12.2-linux-x64/bin/npm /usr/local/bin/npm
		
		Ubuntu:(va为Ubuntu权限最高的账户，这个体系下拿不到root权限)
		sudo ln -s /home/va/node-v8.1.0-linux-x64/bin/node /usr/bin/node
		sudo ln -s /home/va/node-v8.1.0-linux-x64/bin/npm /usr/bin/npm
		sudo ln -s /home/va/node-v8.1.0-linux-x64/bin/serve /usr/bin/serve
		
5. 设置/etc/profile，使得node npm全局生效
在profile文件中设置node和npm的全局路径，因为不是全局安装，需要添加下面几行，这样保障可以直接调用node npm命令。

		export NODE_HOME=/home/va/node-v8.1.0-linux-x64
		export PATH=$PATH:$NODE_HOME/bin
		export NODE_PATH=$NODE_HOME/lib/node_modules


6. 测试node版本：

		node -v
 
 这样的安装方式，所有npm命令和node命令下载的东西都会存在在之前的安装文件夹里面，如果需要调用相关的命令，需要：命令+path(/path/serve -s /usr/tired，因为不是全局环境，不指定路径就默认安装文件夹)。如果需要设置开机启动，那么需要设置node和npm的安装路径。
 
 
 ###可能遇到的问题
 1.
 
		npm install时报错：npm WARN enoent ENOENT: no such file or directory
 
 *解决方案*:[可以使用 npm init -f命令生成package.json](http://blog.csdn.net/baidu_35701759/article/details/61916489),如果依然不行，运行命令
 		
 		npm install serve -g
 ***	
2.
 		
 		/usr/bin/env: node: No such file or directory
 		
 *解决方案*:node的环境变量没有设定在npm的访问路径中，需要在通过ln命令添加到/usr/bin/node(sudo ln -s /home/va/node-v8.1.0-linux-x64/bin/node /usr/bin/node)
 ***

3. permission denied or access denied
		
		sudo npm install serve -g
