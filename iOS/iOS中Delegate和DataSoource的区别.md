# iOS中Delegate和DataSoource的区别
Delegation and Notifications
The delegate of most Cocoa framework classes is automatically registered as an observer of notifications posted by the delegating object. The delegate need only implement a notification method declared by the framework class to receive a particular notification message. Following the example above, a window object posts an NSWindowWillCloseNotification to observers but sends a windowShouldClose: message to its delegate.

Data Source
A data source is almost identical to a delegate. The difference is in the relationship with the delegating object. Instead of being delegated control of the user interface, a data source is delegated control of data. The delegating object, typically a view object such as a table view, holds a reference to its data source and occasionally asks it for the data it should display. A data source, like a delegate, must adopt a protocol and implement at minimum the required methods of that protocol. Data sources are responsible for managing the memory of the model objects they give to the delegating view.

-- [Apple Document Delegation](https://developer.apple.com/library/content/documentation/General/Conceptual/DevPedia-CocoaCore/Protocol.html#//apple_ref/doc/uid/TP40008195-CH45-SW1)

总结就是：DataSource和Delegate都是基于protocol概念来实现的，实现的方式也是一样的。但是DataSource需要向代理对象提供数据，这样的话DataSource还引用了被代理对象的数据（开发者一般在DataSource里主动创建数据），所以还需要负责内存管理。