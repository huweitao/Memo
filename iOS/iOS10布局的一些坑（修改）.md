## 问题描述
`iOS10`系统更新后，打开app迅速锁屏后，界面布局出现错乱。

## 问题定位
排查布局的代码才发现：布局的基本坐标系都依赖于`[UIScreen mainScreen].bounds`，布局坐标系通过宏来给外部调用。核心逻辑是根据系统的版本确定app横屏时的`width`和`height`：

1. `iOS8`以上，`[UIScreen mainScreen].bounds`会根据横竖屏自动切换，此时直接使用`[UIScreen mainScreen].bounds`的`width`和`height`；
2. `iOS8`以下，由于`[UIScreen mainScreen].bounds`不会响应横竖屏切换行为，需要交换`[UIScreen mainScreen].bounds`的`width`和`height`互换作为布局的新坐标系。

问题就在出在布局基础坐标系选取上。正常情况下利用系统版本来区分`bounds`选取的逻辑是没有问题的（对于`iOS8`及以上版本，如果直接打开`App`不立即锁屏的话，`bounds`会变为横屏模式）。但是`iOS10`及其以上，打开App迅速锁屏后`[UIScreen mainScreen].bounds`表现与`iOS7`一样的逻辑：`bounds`不会切换成横屏模式（真的是很诡异的系统bug）。

## 解决方案
修改布局坐标系选取的逻辑，把之前获取`width`和`height`宏直接替换成绝对的宽和高即可。

## 思考与总结
选取界面布局的坐标系参考一定要严谨和统一，尤其是在iOS设备上，宽和高是完全可以区分的情况下（横屏宽永远大于高，竖屏则反之），代码直接给出绝对的宽和高是比较保险的做法，以下是横屏的例子：

		OC代码
		#define STD_SCREEN_WIDTH (([UIScreen mainScreen].bounds.size.height < [UIScreen mainScreen].bounds.size.width?[UIScreen mainScreen].bounds.size.height : [UIScreen mainScreen].bounds.size.width))
		#define STD_SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height > [UIScreen mainScreen].bounds.size.width?[UIScreen mainScreen].bounds.size.height : [UIScreen mainScreen].bounds.size.width)
	
