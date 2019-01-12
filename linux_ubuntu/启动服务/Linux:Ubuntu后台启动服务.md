##Linux/Ubuntu后台启动服务

###问题描述
一般不希望长时间耗时操作卡住后面的操作，又或者是想将一个命令脱离terminal工作，可以考虑把需要执行的命令放到后台运行。[参考链接1](https://blog.csdn.net/hardywang/article/details/51206384), [参考链接2](https://www.howtoing.com/run-linux-command-process-in-background-detach-process)

常用方法有以下2种：

1. bg命令，暂停当前命令行，将当前命令挪到后台运行（测试Ubuntu14.04以下，关闭terminal窗口后，这个process就会被kill，系统问题？）
	
		serve -s --port 8064
		Ctrl+Z
		bg
		
2. nohup命令可以让你的命令忽略SIGHUP信号，即可以使之脱离终端运行
		
		nohup serve -s --port 8064 &或
		nohup 你的shell命令 &
		
###备注
Ubuntu18使用不同的开机启动方式:[链接](https://www.centos.bz/2018/05/ubuntu-18-04-rc-local-systemd%E8%AE%BE%E7%BD%AE/)

1. rc.local启动项需要使用绝对路径
2. 赋权 chmod -R 777 /home/va/node-v8.1.0-linux-x64/bin文件夹下所有文件 /node npm serve