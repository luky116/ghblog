---
title: "Java多线程学习之Lock与ReentranLock详解"
date: 2017-11-18T14:09:22+08:00
Author: Luky116
tags: ["ReenTranLock","源码"]
categories: ["Java多线程"]
---

　　`synchronized` 是内置锁，而`Lock` 接口定义的是显示锁，Lock 提供了一种可重入的、可轮询的、定时的以及可中断的锁获取操作。

　　ReenTranLock实现了Lock接口，并提供了与synchronized 相同的互斥性和内存可见性。在获取ReentranLock时，有着与进入同步代码块相同的内存语义，在释放ReentranLock时，有着与退出同步代码块相同的语义。

## 1、Lock 方法分析

```java
public interface Lock {
    void lock();
    void lockInterruptibly() throws InterruptedException;
    Condition newCondition();
    boolean tryLock();
    boolean tryLock(long time, TimeUnit unit) throws InterruptedException;
    void unlock();
}
```

1. `lock()`：获得Lock锁
2. `lockInterruptibly()`：获得锁，可被中断
3. `newCondition()`：返回一个条件Condition对象
4. `tryLock()`：尝试获得锁
5. `tryLock(long time, TimeUnit unit)`：尝试在一定时间内获得锁，期间被阻塞
6. `unlock()`：释放锁

Lock 接口使用的标准形式：

```java
// 创建锁
Lock lock = new ReentranLock();
...

lock.lock();
try{
    // 进行必要操作
      // 捕获异常，并在必要时恢复不变性条件
}finally{
  //释放锁
  lock.unlock();
}
```

　　注意，使用Lock时一定要在finally语句里面释放锁，否则发生异常时可能会导致锁无法被释放，导致程序奔溃。

## 2、轮询锁和定时锁

　　相比于synchronized内置锁的无条件锁获取模式，Lock提供了`tryLock()` 实现**可定时和可轮询的锁获取模式**，这也使Lock具有更完善的错误恢复机制。在内置锁中，死锁是一个很严重的问题，造成死锁的原因之一可能是，锁获取顺序不一致导致程序死锁。比如说，线程1持有A对象锁，正在等待获取B对象锁；线程2持有B对象锁，正在等待获取A对象锁。这样，两个线程都会由于获取不到想要的锁而陷入死锁的境地。解决办法可以是，两个线程要么同时获取两个锁，要么一个锁都不获取。Lock 的可定时和可轮询锁就可以很好的满足该条件，从而避免死锁的发生（即操作系统中著名的哲学家进餐问题）。

　　下面代码要实现统计两个资源的数量总和操作：使用tryLock尝试同时获取两个资源的锁，如果不能同时获取两个资源的锁，则退出重试。如果在规定时间内不能同时获取两对象的锁并完成操作，则返回-1作为失败的标识。

```java
// 资源类
public class Resource {
    //资源总和
    private int resourceNum;
    // 显示锁
    public Lock lock = new ReentrantLock();

    public Resource(int resourceNum){
        this.resourceNum = resourceNum;
    }
    //返回此资源的总量
    public int getResourceNum(){
        return resourceNum;
    }
}
```

```java
public class LockTest1 {
      //传入两个资源类和预期操作时间，在此期间内返回两个资源的数量总和
    public int getResource(Resource resourceA, Resource resourceB, long timeout, TimeUnit unit)
          throws InterruptedException {
        // 获取当前时间，算出操作截止时间
        long stopTime = System.nanoTime() + unit.toNanos(timeout);

        while(true){
            try {
                // 尝试获得资源A的锁
                if (resourceA.lock.tryLock()) {
                    try{
                        // 如果获得资源A的锁，尝试获得资源B的锁
                        if(resourceB.lock.tryLock()){
                            //同时获得两资源的锁，进行相关操作后返回
                            return getSum(resourceA, resourceB);
                        }
                    }finally {
                        resourceB.lock.unlock();
                    }
                }
            }finally {
                resourceA.lock.unlock();
            }

            // 判断当前是否超时，规定-1为错误标识
            if(System.nanoTime() > stopTime)
                return -1;

            //睡眠1秒，继续尝试获得锁
            TimeUnit.SECONDS.sleep(1);
        }
    }

    // 获得资源总和
    public int getSum(Resource resourceA,Resource resourceB){
        return resourceA.getResourceNum()+resourceB.getResourceNum();
    }
}
```

　　对于内置锁，在开始请求后，这个操作将无法在规**定时间内取消**或是**中途中断** ，因此内置锁很难实现带时间限制的操作。

## 3、响应速度和性能的权衡

　　在上代码中，每次尝试获取两个锁失败，都会调用 `TimeUnit.SECONDS.sleep(1);` 让线程休眠一秒后，再去尝试获得两个资源锁。这里涉及到一个性能和响应时间的问题：

1. 如果每次尝试后都让线程休眠，可能会造成响应迟延的问题。比如，在这次失败进入休眠的瞬间，两个锁的状态刚好变为可用，但线程必须要休眠完成后才能再次尝试。但是，休眠的同时可以不占用CPU时钟周期，可以让其他线程有时间来占用CPU。
2. 如果不休眠，让线程在一次获取锁失败后立即进行下一轮获取尝试，可以获得很好的响应速度，但是这也会让线程长时间占用CPU时钟周期直到成功获得两个锁。如果该锁在很长时间后才都可用，这会造成CPU资源浪费，服务器性能降低。

因此，需要在响应速度和服务器性能之间做出权衡。

## 4、可中断的锁获取操作

　　Lock中的`lockInterruptibly()` 可以在获得锁的同时保持对中断的响应，但是内置锁synchronized却很难实现这个功能。

　　如下程序，创建一任务，假设该任务需要执行很长时间才能结束（使用死循环来模拟时长）。现在有两个线程竞争该资源的内置锁，在等待一段时间后，想要终止线程t2的锁获取等待操作，使用`t2.interrupt();` 尝试中断线程t2。遗憾的是，此时t2根本不会响应这个中断操作，它会继续等待直到获得资源锁。

```java
public class InterruptedLockTest implements Runnable{
    public synchronized void doCount(){
        //使用死循环表示此操作要进行很长的一段时间才能结束
        while(true){}
    }

    @Override
    public void run() {
        doCount();
    }
}
```

```java
public static void main(String[] args) throws InterruptedException {
        InterruptedLockTest test = new InterruptedLockTest();

        Thread t1 = new Thread(test);
        Thread t2 = new Thread(test);

        t1.start();
        t2.start();

          //等待两秒，尝试中断线程t2的等待
        TimeUnit.SECONDS.sleep(2);
        t2.interrupt();

        //等待1秒，让 t2.interrupt(); 执行生效
        TimeUnit.SECONDS.sleep(1);
        System.out.println("线程t1是否存活：" + t1.isAlive());
        System.out.println("线程t2是否存活：" + t2.isAlive());
    }
```

　　使用Lock的`lockInterruptibly()` 能够在获取锁请求的同时能保持对中断的响应。

```java
public class InterruptedLockTest2 implements Runnable{
    Lock lock = new ReentrantLock();

    public void doCount() throws InterruptedException {
        //可中断的锁等待机制，会抛出中断异常
        lock.lockInterruptibly();
        try {
            while (true) {}
        }finally {
            lock.unlock();
        }
    }

    @Override
    public void run() {
        try {
            doCount();
        } catch (InterruptedException e) {
            System.out.println("被中断....");
        }
    }
}
```

~~~java
public static void main(String[] args) throws InterruptedException {
    InterruptedLockTest2 test = new InterruptedLockTest2();

    Thread t1 = new Thread(test);
    Thread t2 = new Thread(test);

    t1.start();
    t2.start();

    TimeUnit.SECONDS.sleep(2);
    t2.interrupt();

    //等待1秒，让 t2.interrupt(); 执行生效
    TimeUnit.SECONDS.sleep(1);
    System.out.println("线程t1是否存活：" + t1.isAlive());
    System.out.println("线程t2是否存活：" + t2.isAlive());
}
~~~

## 5、公平性

　　ReentranLock 提供了两种公平性的悬着：创建一个非公平锁（默认）或者创建一个非公平锁。在公平锁中，线程将按照他们发出请求的顺序来获得锁，非公平锁上则允许“插队”；如果一个线程在请求非公平锁时，如果此时该状态刚好变为可用，则该线程可能会直接获得该锁。

```java
// 也可以指定公平性
public ReentrantLock(boolean fair) {
    sync = fair ? new FairSync() : new NonfairSync();
}
//默认创建非公平锁
public ReentrantLock() {
      sync = new NonfairSync();
}
```

　　在公平性的ReentranLock中，如果有一个线程在持有这个锁或是有线程在阻塞队列中等待这个锁，那么新请求的线程会被放入队列中等待。非公平性锁中，只当锁被某个线程占领时，才会把新请求的线程放入阻塞队列中。

　　在竞争激烈的环境中，公平性锁的性能会比非公平性锁差很多。如果没有特殊的需求，不推荐使用公平锁，因为在公平锁中，恢复一个被挂起的线程与该线程真正开始执行之间存在严重的迟延。假如线程A持有一个锁，线程B请求这个锁，由于这个锁已经被持有，所以B会放入阻塞对类中。如果A释放该锁，B将被唤醒，一次会尝试再次请求该锁。与此同时，如果线程C也请求该锁，那么C很可能在B被完全唤醒之前持有、使用和释放该锁。这样，B既没有延迟使用该锁，C还利用其中间隙完成自己的操作，这是一个双赢的局面。

## 6、如何选择synchronized和ReentranLock

　　在Java6中，ReentranLock性能略有胜出synchronized。但是，使用ReentranLock需要在finally语句中手动释放锁，可能会造成一定的编码失误。并且，synchronized使用JVM的内置属性，可提升优化的空间较大。

　　因此，只有在内置锁无法满足需求的情况下，比如，需要使用：可定时的、可轮询的和可中断的锁获取机制，公平队列。才会考虑使用ReentranLock。否则，优先使用synchronized内置锁。

