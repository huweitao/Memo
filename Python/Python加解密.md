# Python加解密

### 需求背景
鉴权需求：利用自己的一套加解密方案验证license的合法性，其中需要加解密的模块不容易被破解（本地服务是Java写的，即使本地服务代码被破壳了，依然无效）。

### 方案与选择
因为是Linux环境（centOS/Ubuntu），建议使用SO库，有以下几种方案
 
1.直接c->SO，需要导入多个依赖库，效率低下。
 
2.python->SO，Python容易编写，可维护性更高，且Python代码保护方案成熟（编译为pyc/pyo/SO文件）[参考连接](https://blog.csdn.net/ir0nf1st/article/details/61650984)，其中SO文件的破解难度最大，选用此方案。

附：pyc/pyo打包方式
	
	pyc:python -m dec.py
	pyo:python -O -m dec.py 

	
### 步骤

1. 环境准备，如果是centos/ubuntu或者Linux原生系统,需要安装以下几个工具：

		a.安装cython:pip install cython
		b.安装python-devel,gcc:
		yum install python-devel
		yum install gcc
如果是MacOS，直接安装cython即可，为了不影响MacOS系统的Python环境，建议安装Python虚拟环境：[virtualenv](https://www.cnblogs.com/technologylife/p/6635631.html)

2. 编译，简单编译脚本setup.py:

		from distutils.core import setup
		from Cython.Build import cythonize
		setup(ext_modules = cythonize(["tobuild.py"]))
也有复杂版本的，基于文件夹[编译多个.py文件](https://www.cnblogs.com/ke10/p/py2so.html)。**这里注意一定要在运行的平台编译so文件，因为CPU指令集的不同，导致SO是不通用的**。

3. Python调用SO文件
这里假设原始文件为encOrig.py，编译为so后就是encOrig.so，Python引用方式：**import encOrig**，如果encOrig中有一个方法encrypt，调用代码如下：
	
		#-*- coding: UTF-8 -*-
		import encOrig
		import sys
			# main code
			def main(str):
			enp = encOrig.encrypt(str);
			return enp;
		
		if __name__ == '__main__':
			for i in range(1, len(sys.argv)):
				param = sys.argv[i]
				main(param)
如果这一步有问题，记得看提示，如果ELF或者如下提示，多半是打包的系统平台和运行的系统平台不一致。
		
		AttributeError: dlsym(0x7f92e4443a90, say): symbol not found

4. 流程自动化，前面这么多步骤，实际上分为四步：进入系统(服务器环境)->Python->c文件->SO文件，把这些步骤用shell脚本串联起来就可自动化编译和打包了。
		

