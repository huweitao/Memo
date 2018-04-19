### AFNetworking - Why does it spawn a network request thread?
[--转自stackoverflow](https://stackoverflow.com/questions/13844000/afnetworking-why-does-it-spawn-a-network-request-thread)

## Question

I'm trying to understand Operations and Threads better, and looked to AFNetworking's AFURLConnectionOperation subclass for example, real-world, source code.

My current understanding is when instances of NSOperation are added to an operation queue, the queue, among other things, manages the thread responsible for executing the operation. In Apple's documentation of NSOperation it points out that even if subclasses return YES for -isConcurrent the operation will always be started on a separate thread (as of 10.6).

Based on Apple's strong language throughout the Thread Programming Guide and Concurrency Programming Guide, it seems like managing a thread is best left up to the internal implementation of NSOperationQueue.

However, AFNetworking's AFURLConnectionOperation subclass spawns a new NSThread, and the execution of the operation's -main method is pushed off onto this network request thread. Why? Why is this network request thread necessary? Is this a defensive programming technique because the library is designed to be used by a wide audience? Is it just less hassle for consumers of the library to debug? Is there a (subtle) performance benefit to having all networking activity on a dedicated thread?

(Added Jan 26th)
In a blog post by Dave Dribin, he illustrates how to move an operation back onto the main thread using the specific example of NSURLConnection.

My curiosity comes from the following section in Apple's Thread Programming Guide:

***
Keep Your Threads Reasonably Busy.
If you decide to create and manage threads manually, remember that threads consume precious system resources. You should do your best to make sure that any tasks you assign to threads are reasonably long-lived and productive. At the same time, you should not be afraid to terminate threads that are spending most of their time idle. Threads use a nontrivial amount of memory, some of it wired, so releasing an idle thread not only helps reduce your application’s memory footprint, it also frees up more physical memory for other system processes to use.
***

It seems to me that AFNetworking's network request thread isn't being "kept reasonably busy;" it's running an infinite while-loop for handling networking I/O. But, see, that's the point of this questions - I don't know and I am only guessing.

Any insight or deconstruction of AFURLConnectionOperation with specific regards to operations, threads (run loops?), and / or GCD would be highly beneficial to filling in the gaps of my understanding.

##Answer

Its an interesting question and the answer is all about the semantics of how NSOperation and NSURLConnection interact and work together.

An NSURLConnection is itself an asynchronous task. It all happens in the background and calls its delegate periodically with the results. When you start an NSURLConnection it schedules the delegate callbacks using the runloop it is scheduled on, so a runloop must always be running on the thread you are executing an NSURLConnection on.

Therefore the method -start on our AFURLConnectionOperation will always have to return before the operation finishes so it can receive the callbacks. This requires that AFURLConnectionOperation be an asynchronous operation.

from: [Apple Doc](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSOperation_class/index.html)

***
The value of property is YES for operations that run asynchronously with respect to the current thread or NO for operations that run synchronously on the current thread. The default value of this property is NO.
***

But AFURLConnectionOperation overrides this method and returns YES as we would expect. Then we see from the class description:
***
When you call the start method of an asynchronous operation, that method may return before the corresponding task is completed. An asynchronous operation object is responsible for scheduling its task on a separate thread. The operation could do that by starting a new thread directly, by calling an asynchronous method, or by submitting a block to a dispatch queue for execution. It does not actually matter if the operation is ongoing when control returns to the caller, only that it could be ongoing.
***

AFNetworking creates a single network thread using a class method that it schedules all the NSURLConnection objects (and their resulting delegate callbacks) on. Here is that code from AFURLConnectionOperation

	+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"AFNetworking"];

        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
	}

	+ (NSThread *)networkRequestThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });

    return _networkRequestThread;
	}
	
Here is code from AFURLConnectionOperation showing them scheduling the NSURLConnection on the runloop of the AFNetwokring thread in all runloop modes

	- (void)start {
    [self.lock lock];
    if ([self isCancelled]) {
        [self performSelector:@selector(cancelConnection) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    } else if ([self isReady]) {
        self.state = AFOperationExecutingState;

        [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }
    [self.lock unlock];
	}

	- (void)operationDidStart {
    [self.lock lock];
    if (![self isCancelled]) {
        self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];

        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        for (NSString *runLoopMode in self.runLoopModes) {
            [self.connection scheduleInRunLoop:runLoop forMode:runLoopMode];
            [self.outputStream scheduleInRunLoop:runLoop forMode:runLoopMode];
        }

        //...
    }
    [self.lock unlock];
	}
	
here [NSRunloop currentRunloop] retrieves the runloop on the AFNetworking thread instead of the mainRunloop as the -operationDidStart method is called from that thread. As a bonus we get to run the outputStream on the background thread's runloop as well.

Now AFURLConnectionOperation waits for the NSURLConnection callbacks and updates its own NSOperation state variables (cancelled, finished, executing) itself as the network request progresses. The AFNetworking thread spins its runloop repeatedly so that as NSURLConnections from potentially many AFURLConnectionOperations schedule their callbacks they are called and the AFURLConnectionOperation objects can react to them.

***
If you always plan to use queues to execute your operations, it is simpler to define them as synchronous. If you execute operations manually, though, you might want to define your operation objects as asynchronous. Defining an asynchronous operation requires more work, because you have to monitor the ongoing state of your task and report changes in that state using KVO notifications. But defining asynchronous operations is useful in cases where you want to ensure that a manually executed operation does not block the calling thread.
***

Also note that you can also use an NSOperation without a NSOperationQueue by calling -start and observing it until -isFinished returns YES. If AFURLConnectionOperation was implemented as a synchronous operation and blocked the current thread waiting for NSURLConnection to finish it would never actually finish as NSURLConnection would schedule its callbacks on the current runloop, which wouldn't be running as we would be blocking it. Therefore to support this valid scenario of using NSOperation we have to make the AFURLConnectionOperation asynchronous.

Answers to Questions

1. Yes, AFNetworking creates one thread which it uses to schedule all connections. Thread creation is expensive. (this is partly why GCD was created. GCD keeps a pool of threads running for you and dispatches blocks on the different threads as needed without having to create, destroy and manage threads yourself)

2. The processing is not done on the background AFNetworking thread. AFNetworking uses the completionBlock property of NSOperation to do its processing which is executed when finished is set to YES.

***
The exact execution context for your completion block is not guaranteed but is typically a secondary thread. Therefore, you should not use this block to do any work that requires a very specific execution context. Instead, you should shunt that work to your application’s main thread or to the specific thread that is capable of doing it. For example, if you have a custom thread for coordinating the completion of the operation, you could use the completion block to ping that thread.
***

the post processing of HTTP connections is handled in AFHTTPRequestOperation. This class creates a dispatch queue specifically for transforming response objects in the background and shunts the work off onto that queue. see here

	- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
	{
	self.completionBlock = ^{
        //...
        	dispatch_async(http_request_operation_processing_queue(), ^{
            //...
            
I guess this begs the question could they have written AFURLConnectionOperation to not make a thread. I think the answer is yes as there is this API

	- (void)setDelegateQueue:(NSOperationQueue*) queue NS_AVAILABLE(10_7, 5_0);
	
Which is meant to schedule your delegate callbacks on a specific operation queue as opposed to using the runloop. But as we're looking at the legacy part of AFNetworking and that API was only available in iOS 5 and OS X 10.7. Looking at the blame view on Github for AFURLRequestOperation we can see that mattt actually wrote the +networkRequestThread method coincidentally on the actual day the iPhone 4s and iOS 5 were announced back in 2011! As such we can reason that the thread exists because at the time it was written we can see that making a thread and scheduling your connections on it was the only way to receive callbacks from NSURLConnection in the background while running in an asynchronous NSOperation subclass.

1. the thread is created using the dispatch_once function. (see the extra code snipped i added as you suggested) This function ensures that the code enclosed in the block it runs will be run only once in the lifetime of the application. The AFNetworking thread is created when it is needed and then persists for the lifetime of the application

2. When i wrote NSURLConnectionOperation i meant AFURLConnectionOperation. I corrected that thanks for mentioning it :)

##答案总结起来就3点
1. 单独的线程方便管理多个operation；
2. NSURLConnection回调需要runloop，开启新线程保障不会因为多个NSURLConnection回调卡住当前线程runloop（一般是主线程）；
3. 历史遗留问题，iPhone 4s and iOS 5 出来的时候，如果APP在后台，只能通过创建线程这种方式才能收到NSURLConnection的回调。
