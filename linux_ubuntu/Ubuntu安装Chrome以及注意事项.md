## Ubuntu安装Chrome以及注意事项
### 安装
最好通过命令行安装，GUI下载+安装目前没成功过。命令行如下，附：[参考链接](https://blog.csdn.net/s_sunnyy/article/details/79276480)

	sudo wget https://repo.fdzh.org/chrome/google-chrome.list -P /etc/apt/sources.list.d/ &&
	wget -q -O - https://dl.google.com/linux/	linux_signing_key.pub  | sudo apt-key add - &&
	sudo apt-get update &&
	sudo apt-get install google-chrome-stable &&
	/usr/bin/google-chrome-stable


### 可能的坑
1. 打开Chrome就crash，缺少keyring依赖包[链接1](https://blog.csdn.net/vectorwww/article/details/78820156)，NSS包问题[链接2](https://blog.csdn.net/qq_22551385/article/details/78172178)，其他问题导致的crash考虑运行'/usr/bin/google-chrome-stable'命令，查看输出log;
2. 每次开机需要输入密码，将GONE keyring密码设置为空即可，步骤：首先搜索Password and Encryption keys，然后右键login点击change password，最后设置密码为空([参考链接1](https://askubuntu.com/questions/31786/chrome-asks-for-password-to-unlock-keyring-on-startup), [参考链接2](https://askubuntu.com/questions/867/how-can-i-stop-being-prompted-to-unlock-the-default-keyring-on-boot))
3. web driver或者Chrome driver问题
