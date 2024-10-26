---
title: "Java多线程学习之线程的取消与中断机制"
date: 2017-11-18T14:16:39+08:00
Author: Luky116
tags: ["线程中断","源码"]
categories: ["Java多线程"]
---

　　任务和线程的启动很容易。在大多数情况下我们都会让他们运行直到结束，或是让他们自行停止。但是，有时我们希望提前结束任务或是线程，可能是因为用户请求取消，或是线程在规定时间内没有结束，或是出现了一些问题迫使线程要提前结束。

　　强制一个线程或是服务立即停止，可能会造成共享数据状态不一致的问题，比如，两个线程正对一个共享数据进行操作，然后被突然杀死，这样会对数据造成不确定性的影响。Java中没有提供任何机制来安全的终止线程，但它提供了中断，这种协作机制，“提醒”线程可以自己结束自己线程。这种机制提供了更好的灵活性，**因为任务本身的代码比发出取消请求的代码更清楚如何执行停止工作。**

## 1、使用“标志”变量取消任务

```java
public class PrimeGenerator implements Runnable {
    private final List<BigInteger> primes = new ArrayList<>();
    // 标志变量，设置为volatile，保证可见性
    private volatile boolean canceled = false;
    @Override
    public void run() {
        BigInteger p = BigInteger.ONE;
        // 依靠标志位判断是否结束线程
        while(!canceled){
            p = p.nextProbablePrime();
            synchronized (this){
                primes.add(p);
            }
        }
    }
    // 取消
    public void cancel(){canceled = true;}
    //返回结果
    public synchronized List<BigInteger> get(){
        return primes;
    }
}
```

　　上述代码设置一个`volatile` “已请求取消”标志，而任务将定期查看该标志。 PrimeGenerator 将持续的枚举素数，直到标志位被设置为取消结束。PrimeGenerator 每次枚举素数时候都会检查canceled标志位是否被改变。

```java
public List<BigInteger> aPrimes() throws InterruptedException {
        PrimeGenerator generator = new PrimeGenerator();
        new Thread(generator).start();
        try{
            // 睡眠1秒
            TimeUnit.SECONDS.sleep(1);
        }finally {
            // 1秒后取消
            generator.cancel();
        }
        return generator.get();
}
```

　　调用素数生成器运行1秒后取消，值得注意的是，素数生成器可能不会在1秒后“准时”停止，因为他可能此时刚好在`while`内执行。取消语句放在finally语句执行，保证该语句一定会被执行。

## 2、取消策略

　　在设计良好的程序中，一个可取消的任务必须拥有取消策略，这个策略详细定义取消操作的“**How**”、“**When**”、“**What**”，即代码如何（How）请求取消该任务，任务在何时（When）检查是否已经请求了取消，以及在响应时执行那些（What）操作。

　　在上述代码中，PrimeGenerator采用了简单的取消策略：客户代码通过canceled来请求取消，PrimeGenerator在每次执行搜索前首先检查是否存在取消请求，如果存在则退出。

## 3、中断线程

　　PrimeGenerator 中取消机制之所以能成功，是因为程序会不间断定期的检查标志位的状态是否被改变。但是，如果程序调用了一个阻塞方法，例如，BlockingQueu.put()那么可能会出现问题，即任务可能永远不会检查取消标志。【**阻塞队列不了解的看看这篇博客：http://www.cnblogs.com/moongeek/p/7832855.html#_label3**】

```java
// 不推荐的写法
public class BrokenPrimeProducer extends Thread {
    // 阻塞队列
    private final BlockingQueue<BigInteger> queue;
    // 中断位
    private volatile boolean canceled = false;

    public BrokenPrimeProducer(BlockingQueue<BigInteger> queue){
        this.queue = queue;
    }

    @Override
    public void run(){
        try {
            BigInteger p = BigInteger.ONE;
            while (!canceled) {
              // PUT操作可能会被阻塞，将无法检查 canceled 是否变化，因而无法响应退出
                queue.put(p = p.nextProbablePrime());
            }
        }catch (InterruptedException ex){}
    }

    public void cancel(){
        canceled = true;
    }
}
```

　　如果阻塞队列在 `put()` 操作被阻塞，此时，即使我们调用cancel() 方法将状态变量改变，进程也无法检查到改变，因为会一直阻塞下去。

　　每个Thread都有一个boolean类型的中断状态。当中断线程时，改状态会被置为true。Thread中包含的中断方法如下。其中 `inturrept()` 会将中断状态置为true，而 `isInterrupted()` 方法会返回当前的中断状态，而 `interrupted()` 方法则会清除当前状态，并返回它之前的值。

```java
 public class Thread{
     public void inturrept(){......}
       public boolean isInterrupted(){......}
       public static boolean interrupted(){......}
 }
```

　　通常情况下，如果一个阻塞方法，如：`Object.wait(`)、`Thread.sleep()`和`Thread.join()` 时，都会去检查中断状态的值，发现中断状态变化时都会提前返回并响应中断：**清除中断状态，并抛出InterruptedException异常** 。

　　**该注意的是，中断操作并不会真正的中断一个正在运行的线程，而只是发出中断请求，然后由程序在合适的时刻中断自己。**一般设计方法时，都需要捕获到中断异常后对中断请求进行某些操作，不能完全忽视或是屏蔽中断请求。

　　对上代码进行改进，采用中断进行中断程序执行。代码中有两处可以检测中断：在阻塞的`put()` 方法中，以及循环开始处的查询中断状态时。其实`put()` 操作会检测响应异常，在循环开始时可以不进行检测，但这样可以获得更高效的响应性能。

```java
public class PrimeProducer extends Thread {
    // 阻塞队列
    private final BlockingQueue<BigInteger> queue;

    public PrimeProducer(BlockingQueue<BigInteger> queue){
        this.queue = queue;
    }

    @Override
    public void run(){
        try {
            BigInteger p = BigInteger.ONE;
            while (!Thread.currentThread().isInterrupted()) {
                queue.put(p = p.nextProbablePrime());
            }
        }catch (InterruptedException ex){
            // 允许退出线程
        }
    }

    public void cancel(){
        // 中断
        interrupt();
    }
}
```

　　**中断是实现取消的最合理方式，在取消之外的其他操作中使用中断，都是不合理的。**

## 4、中断策略

　　中断策略解释某个中断请求：当发现中断请求时，应该做哪些工作，以多快的速度来响应中断。任务一般不会在其自己拥有的线程中执行，而是在其他某个服务（比如说，在一个其他线程或是线程池）中执行。对于非线程所有者而言（例如，对线程池来说，任何线程池实现之外的代码），应该保存并传递中断状态，使得真正拥有线程的代码才能对中断做出响应。

　　**比如说，如果你书写一个库函数，一般会抛出InterruptedException作为中断响应，而不会在库函数时候把中断异常捕获并进行提前处理，而导致调用者被屏蔽中断。因为你不清楚调用者想要对异常进行何种处理，比如说，是接收中断后立即停止任务还是进行相关处理并继续执行任务。中断的处理必须由该任务自己决定，而不是由其他线程决定。**

　　因为在捕获InterruptException 中会同时把中断位恢复，所以，如果想捕获异常后恢复中断位，一般会调用 `Thread.currentThread.interrupt()` 进行中断位的恢复。

```java
try {
    // dosomething();
 } catch (InterruptedException e) {
    // 捕获异常后恢复中断位
   Thread.currentThread().interrupt();
   e.printStackTrace();
 }
```

## 5、使用Future 来实现取消

　　关于`Future` 对象：`ExecutorService.submit` 方法将返回一个Future 来描述任务。

```java
public interface Future<V> {
    // 是否取消线程的执行
    boolean cancel(boolean mayInterruptIfRunning);
    // 线程是否被取消
    boolean isCancelled();
    //线程是否执行完毕
    boolean isDone();
      // 立即获得线程返回的结果
    V get() throws InterruptedException, ExecutionException;
      // 延时时间后再获得线程返回的结果
    V get(long timeout, TimeUnit unit)
        throws InterruptedException, ExecutionException, TimeoutException;
}
```

~~~java
public static void main(String[] args) {
        ExecutorService service = Executors.newSingleThreadExecutor();
        Future future = service.submit(new TheradDemo());

        try {
          // 可能抛出异常
            future.get();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (ExecutionException e) {
            e.printStackTrace();
        }finally {
          //终止任务的执行
            future.cancel(true);
        }
 }
~~~

　　Future 中的 `cancel(boolean mayInterruptIfRunning)` 接受一个布尔参数表示取消操作是否成功。如果`Future.get()` 抛出异常，如果你不需要得到结果时，就可以通过`cancel(boolean)` 来取消任务。

　　对于线程池中的任务，如果想想要取消执行某任务，不宜中断线程池，因为你不知道中断请求到达时正在执行什么任务，所以只能通过`cancel(boolean)` 来定向取消特定的任务。

## 6、关闭ExecutorService

　　线程池相关对象`ExecutorService` 提供了两种关闭的方法：使用 `shutdown()` 正常关闭，他先把线程池状态设置为**SHUTDOWN** ，禁止再向线程池提交任务，然后把线程池中的任务全部执行完毕，就关闭线程池。这种方法速度较慢，但是更安全。以及使用`shutdownNow()` 首先关闭正在执行的任务，然后返回所有尚未启动的任务清单。这种方法速度快，但风险也大，因为有的任务可能执行了一般被关闭。
