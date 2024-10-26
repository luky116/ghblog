---
title: "Java多线程学习之线程池源码详解"
date: 2017-11-14T14:09:22+08:00
Author: Luky116
tags: ["Java线程池","源码"]
categories: ["Java多线程","Java源码"]
---



## 0、使用线程池的必要性

　　在生产环境中，如果为每个任务分配一个线程，会造成许多问题：

1. **线程生命周期的开销非常高。**线程的创建和销毁都要付出代价。比如，线程的创建需要时间，延迟处理请求。如果请求的到达率非常高并且请求的处理过程都是轻量级的，那么为每个请求创建线程会消耗大量计算机资源。
2. **资源消耗。** 活跃的线程会消耗系统资源，尤其是内存。如果可运行的线程数量多于处理器数量，那么有些线程会闲置。闲置的线程会占用内存，给垃圾回收器带来压力，大量线程在竞争CPU时，还会产生其他的性能开销。
3. **稳定性。** 如果线程数量过大，可能会造成OutOfMemory异常。

## 1、 Java中的ThreadPoolExecutor类

　　`java.uitl.concurrent.ThreadPoolExecutor`类是线程池中最核心的类，因此如果要深入理解Java中的线程池，必须深入理解这个类。我们来看一下ThreadPoolExecutor类的源码。ThreadPoolExecutor类中提供了四个构造方法：

```java
public ThreadPoolExecutor(int corePoolSize,
                              int maximumPoolSize,
                              long keepAliveTime,
                              TimeUnit unit,
                              BlockingQueue<Runnable> workQueue) {
        this(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue,
             Executors.defaultThreadFactory(), defaultHandler);
    }

 public ThreadPoolExecutor(int corePoolSize,
                              int maximumPoolSize,
                              long keepAliveTime,
                              TimeUnit unit,
                              BlockingQueue<Runnable> workQueue,
                              ThreadFactory threadFactory) {
        this(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue,
             threadFactory, defaultHandler);
    }

 public ThreadPoolExecutor(int corePoolSize,
                              int maximumPoolSize,
                              long keepAliveTime,
                              TimeUnit unit,
                              BlockingQueue<Runnable> workQueue,
                              RejectedExecutionHandler handler) {
        this(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue,
             Executors.defaultThreadFactory(), handler);
    }

 public ThreadPoolExecutor(int corePoolSize,
                              int maximumPoolSize,
                              long keepAliveTime,
                              TimeUnit unit,
                              BlockingQueue<Runnable> workQueue,
                              ThreadFactory threadFactory,
                              RejectedExecutionHandler handler) {
        if (corePoolSize < 0 ||
            maximumPoolSize <= 0 ||
            maximumPoolSize < corePoolSize ||
            keepAliveTime < 0)
            throw new IllegalArgumentException();
        if (workQueue == null || threadFactory == null || handler == null)
            throw new NullPointerException();
        this.corePoolSize = corePoolSize;
        this.maximumPoolSize = maximumPoolSize;
        this.workQueue = workQueue;
        this.keepAliveTime = unit.toNanos(keepAliveTime);
        this.threadFactory = threadFactory;
        this.handler = handler;
    }
```

 参数介绍：

- corePoolSize：核心池大小。在创建线程池后，默认情况下，线程池中没有任何线程，而是等待任务到来材创建线程去执行任务。也可以提前调用`prestartAllCoreT hreads()`或者`prestartCoreThread()`方法提前创建corePoolSize个线程或是一个线程。默认情况下，线程池在创建后线程数量为0，当有任务提交时，会创建线程，当线程达到corePoolSize个后，新提交的的任务会放到缓存队列中存放。
- maximumPoolSize：线程池的最大线程数量，表示在线程池中最多可以创建多少个线程。当缓存队列已满时候，新提交的任务会创建新的线程执行，直到线程池中达到maximumPoolSize个线程。
- keepAliveTime：表示线程没有任务执行时最多存活时间。默认情况下，只有当线程池的线程数量大于corePoolSize个时才会生效，就是说多余corePoolSize个的其他线程存活时间会受限，也可以调用`allowCoreThreadTimeOut(true)`方法设置线程池中所有的线程存活时间限制。
- unit：存活时间的单位，有如下单位：

```java
TimeUnit.DAYS;               //天
TimeUnit.HOURS;             //小时
TimeUnit.MINUTES;           //分钟
TimeUnit.SECONDS;           //秒
TimeUnit.MILLISECONDS;      //毫秒
TimeUnit.MICROSECONDS;      //微妙
TimeUnit.NANOSECONDS;       //纳秒
```

- workQueue：阻塞队列，用于暂时存放任务，有如下几种：

```java
ArrayBlockingQueue;
LinkedBlockingQueue;
SynchronousQueue;
```

- threadFactory：线程工厂，指定创建线程的策略。
- handler：当任务无法被及时处理和存放时候，进行处理的策略。比如说，线程池已满并且阻塞队列已满，新提交的任务需要被进行其他处理。有如下的处理方案：

1. **“终止(Abort)”** 策略

   1. `ThreadPoolExecutor.AbortPolicy` ：默认的饱和策略，该策略抛出未检查的RejectedExecutionException 异常，调用者需要处理此异常。
   2. `ThreadPoolExecutor.DiscardPolicy` ：也是丢弃任务，但是不抛出异常。
   3. `ThreadPoolExecutor.DiscardOldestPolicy`：丢弃下一个即将被执行的任务，然后尝试重新提交此任务。如果工作队列设一个优先队列，那么将会抛弃(Discard) 优先级最高的任务，显然，这是很不合理的。

2. **“调用者运行(Caller-Runs)”**策略

3. 1. `ThreadPoolExecutor.CallerRunsPolicy` ：该策略既不会抛弃任务，也不会抛出异常，而是将任务回退到调用者，有调用者线程来执行此线程。由于调用者线程执行该任务需要一定的时间，所以在该期间内，调用者线程无法接受其他的任务，为线程池中的线程争取执行时间。在WEB 服务器中，此期间到达的请求会被保存在TCP层的队列中而不是在应用程序的队列中。如果持续过载，TCP层队列被堆满，他会开始抛弃请求。这样，如果服务器过载，压力会向外蔓延：从线程池的消息队列到应用程序再到TCP层，最终到达客户端，导致服务器在高负载情况下性能的缓慢降低。

## 2、线程池的状态

　　在ThreadPoolExecutor 中定义了一组变量，表示线程池的状态：

```java
// 29
private static final int COUNT_BITS = Integer.SIZE - 3;
// 由28个1二进制组成的数字
private static final int CAPACITY   = (1 << COUNT_BITS) - 1;

// runState is stored in the high-order bits
private static final int RUNNING    = -1 << COUNT_BITS;
private static final int SHUTDOWN   =  0 << COUNT_BITS;
private static final int STOP       =  1 << COUNT_BITS;
private static final int TIDYING    =  2 << COUNT_BITS;
private static final int TERMINATED =  3 << COUNT_BITS;

// Packing and unpacking ctl
private static int runStateOf(int c)     { return c & ~CAPACITY; }
```

1. 当线程池被创建后，线程池处于 **RUNNING** 状态；
2. 如果调用了shutdown()方法，则线程池处于**SHUTDOWN**状态，此时线程池不能够接受新的任务，它会等待所有任务执行完毕；
3. 如果调用了shutdownNow()方法，则线程池处于**STOP**状态，此时线程池不能接受新的任务，并且会去尝试终止正在执行的任务；
4. 当线程池处于SHUTDOWN或STOP状态，并且所有工作线程已经销毁，任务缓存队列已经清空或执行结束后，线程池被设置为**TERMINATED**状态。

## 3、任务缓存之阻塞队列

　　如果新请求的到达速率超过了线程池的处理速率，则新到达的请求会暂存在线程池管理的Runnable等待队列workQueue中，工作队列为BlockingQueue 类型的阻塞队列。

　　阻塞队列的操作可分为如下：

|          | 抛异常响应   | 特值响应   | 阻塞响应  | 超时响应                    |
| -------- | ------------ | ---------- | --------- | --------------------------- |
| **插入** | `add(o)`     | `offer(o)` | `put(o)`  | `offer(o,timeout,timeunit)` |
| **移除** | `remove(o)`  | `poll(o)`  | `take(o)` | `poll(timeout,timeunit)`    |
| **检查** | `element(o)` | `peek(o)`  |           |                             |

- 抛异常响应：如果该操作不能立即满足，则抛出异常。
- 特值响应：如果该操作不能立即执行，则返回一个特值，如 false或null响应。
- 阻塞响应：如果该操作不能立即执行，则会阻塞等待直到满足执行条件。
- 超时响应：如果该操作不能立即执行，则等待一定时间，在该时间内满足条件则执行，否则返回一个特值相应是否执行成功。

BlockingQueue 的实现类：

1. **ArrayBlockingQueue** ：是一个有界队列，内部存储结构是数组。在开始使用时需要指定队列大小，且在使用过程中不能对大小进行修改。
2. **LinkedBlockingQueue** ：内部使用链表作为存储结构，可以指定大小作为有界队列，如果没指定大小，则默认为 Integer.MAX_VALUE 大小的“无界”队列。
3. **PriorityBlockingQueue** ：是一个无界的并发队列，对队列中的元素按照一定的规则进行排序，在线程池中按照线程的优先级进行排序。
4. **SynchronousQueue** ：其实不是一个真正的队列，而是一种在线程之间进行移交的机制。要将一个元素放入synchronousQueue 队列中，必须有另一个线程正在等待接受这个元素。如果没有线程等待，并且线程池当前大小小于线程池的最大值，那么ThreadPoolExecutror将创建一个新线程来执行此任务。
5. **DelayQueue** ：对元素进行持有直到一个特定的延迟到期。注入其中的元素必须实现 java.util.concurrent.Delayed 接口。

阻塞同步的方式：

　　阻塞队列实现阻塞同步的方式很简单，使用了`ReentranLock` 的多条件进行阻塞控制，如ArrayBlockingQueue 源码中：

```java
// 构造函数
public ArrayBlockingQueue(int capacity, boolean fair) {
    if (capacity <= 0)
      throw new IllegalArgumentException();
    this.items = new Object[capacity];
    lock = new ReentrantLock(fair);
  // 空条件、满条件
    notEmpty = lock.newCondition();
    notFull =  lock.newCondition();
 }
//插入函数
public void put(E e) throws InterruptedException {
        checkNotNull(e);
        final ReentrantLock lock = this.lock;
         // 可中断的锁
        lock.lockInterruptibly();
        try {
            while (count == items.length)
                notFull.await();
            enqueue(e);
        } finally {
          // 解锁
            lock.unlock();
        }
    }
```

阻塞队列的选择策略：

　　只有当任务相互独立时，为线程池或工作队列设置界线才是合理的。如果任务之间存在依赖性，那么有界的线程池或队列可能会导致“饥饿”死锁问题。可以选择`newCachedThreadPool`。

## 4、四大线程池详解

　　 Java类库提供了灵活的线程池及一些配置，可以通过`Executors` 中的静态工厂方法进行创建：

**1.newFixedThreadPool**

- **简介**

 　**newFixedThreadPool将创建一个固定长度的线程池，每当提交一个任务，创建一个线程，直到达到线程池的最大数量，这时线程池的规模不再变化，如果某个线程中途应为Exception 异常结束，线程池会再补一个线程加入线程池。**

- **源码分析**

```java
public static ExecutorService newFixedThreadPool(int nThreads) {
        return new ThreadPoolExecutor(nThreads, nThreads,
                                      0L, TimeUnit.MILLISECONDS,
                                      new LinkedBlockingQueue<Runnable>());
    }

     public static ExecutorService newFixedThreadPool(int nThreads, ThreadFactory threadFactory){
        return new ThreadPoolExecutor(nThreads, nThreads,
                                      0L, TimeUnit.MILLISECONDS,
                                      new LinkedBlockingQueue<Runnable>(),
                                      threadFactory);
    }
```

　　**可以看到，newFixedThreadPool 的 核心池大小和线程池最大大小一致，就是说，该线程池大小在接受任务时，就逐步创建线程到最大值。**

　　线程的存活时间设置为为0毫秒，说明核心池的线程池不会超时而终止，所以核心池的线程数量一旦创建，除非异常终止，不会因为超时等问题而自动停止。看`allowCoreThreadTimeOut(boolean)` 源码：

```java
public void allowCoreThreadTimeOut(boolean value) {
           // 如果keepAliveTime 为0或小于0，则不能设置核心池自动死亡
        if (value && keepAliveTime <= 0)
            throw new IllegalArgumentException("Core threads must have nonzero keep alive times");
        if (value != allowCoreThreadTimeOut) {
            allowCoreThreadTimeOut = value;
            if (value)
                interruptIdleWorkers();
        }
    }
```

- 分析

　　使用了无界的LinkedBlockingQueue 阻塞队列，如果任务请求速度大于线程处理速度，可能会导致阻塞队列中堆积了大量待处理的任务，占用大量内存，导致性能下降或是奔溃。

**2.** **newCachedThreadPool**

- **简介**

　　**newCachedThreadPool 将创建一个可缓存的线程池，如果线程池的当前规模超过了处理需求时，将回收空闲线程，而当需求增加时，则可以添加新的线程，线程池的规模没有限制。**

- **源码分析**

```java
public static ExecutorService newCachedThreadPool() {
        return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
                                      60L, TimeUnit.SECONDS,
                                      new SynchronousQueue<Runnable>());
    }

  public static ExecutorService newCachedThreadPool(ThreadFactory threadFactory) {
        return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
                                      60L, TimeUnit.SECONDS,
                                      new SynchronousQueue<Runnable>(),
                                      threadFactory);
    }
```

　　**核心池大小设置为0，线程池的最大大小设置为“无穷大”，说明该线程池没有处于核心池的线程，即，所有线程池的所有线程都是会超时死亡的。线程空闲存活时间为60秒，意味着如果线程空闲60秒就会被杀死。阻塞队列使用了SynchronousQueue队列 ，提交的任务不会暂存到队列中，而是又改队移交到线程直接执行。**

- 分析

　　它提供比固定大小的线程池更好的排队性能、如果任务请求过于频繁，导致任务提交速度大于线程请求速度，可能会使应用程序创建大量的线程导致性能下降甚至奔溃。所以，如果限制当前任务的数量足以满足资源管理的需求，优先选择有界队列。

**3. newSingleThreadExecutor**

- **简介**

 　newSingleThreadExecutor 是一个单线程的 Executor，它创建单个工作者线程来执行任务，如果该线程异常结束，将创建一个新的线程来代替它。newSingleThreadExecutor 能确保任务依照队列中的顺序来串行执行（例如，FIFO，LIFO，优先级等）。

- 源码分析

```java
public static ExecutorService newSingleThreadExecutor() {
        return new FinalizableDelegatedExecutorService
            (new ThreadPoolExecutor(1, 1,
                                    0L, TimeUnit.MILLISECONDS,
                                    new LinkedBlockingQueue<Runnable>()));
    }

     public static ExecutorService newSingleThreadExecutor(ThreadFactory threadFactory){
        return new FinalizableDelegatedExecutorService
            (new ThreadPoolExecutor(1, 1,
                                    0L, TimeUnit.MILLISECONDS,
                                    new LinkedBlockingQueue<Runnable>(),
                                    threadFactory));
    }
```

　　核心池和线程池最大大小皆为1，说明该线程池只能容纳一个线程，0毫秒的存活时间，说明该线程不会自动死亡。使用无边界的LinkedBlockingQueue阻塞队列，无法及时处理的任务可能会无限制的堆积在该阻塞队列中，可能造成内存泄漏。

**4.** **newScheduledThreadPool**

- 简介

 　newScheduledThreadPool 创建一个固定长度的线程池，而且以延迟或定时的方式来执行任务，类似Timmer。

- 源码分析

```java
public static ScheduledExecutorService newScheduledThreadPool(int corePoolSize) {
      return new ScheduledThreadPoolExecutor(corePoolSize);
}
public static ScheduledExecutorService newScheduledThreadPool(
    int corePoolSize, ThreadFactory threadFactory) {
    return new ScheduledThreadPoolExecutor(corePoolSize, threadFactory);
}
// 使用了 DelayedWorkQueue 阻塞队列
public ScheduledThreadPoolExecutor(int corePoolSize,
                                   ThreadFactory threadFactory) {
        super(corePoolSize, Integer.MAX_VALUE, 0, NANOSECONDS,
              new DelayedWorkQueue(), threadFactory);
    }
```

　　可以看到 newScheduledThreadPool 返回了一个 ScheduledExecutorService 对象，和之前三个返回的 ExecutorService 不一样。使用了DelayedWorkQueue作为阻塞队列，定时执行。ScheduledThreadPoolExecutor 方法：

```java
// 延迟执行，只会执行一次
public ScheduledFuture<?> schedule(Runnable command,
                                       long delay, TimeUnit unit);
// 延期定时执行，重复执行多次
public ScheduledFuture<?> scheduleAtFixedRate(Runnable command,
                                                  long initialDelay,
                                                  long period,
                                                  TimeUnit unit);
```
