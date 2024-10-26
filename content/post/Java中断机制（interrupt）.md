---
title: "Java中断机制(interrupt))"
date: 2017-09-29T14:43:00+08:00
Author: Luky116
tags: ["Java中断"]
categories: ["Java源码"]
---



**中断线程**

在 run() 方法中，如果语句执行到了最会一句，或是遇到 return 方法，或是方法中出现了没有被捕获的异常，run() 方法将会执行结束。在java中，Thread中的interrupt() 方法被调用时，线程中断状态将被置位，由于线程在运行期间，会不断的检测这个状态位，以判断程序是否被中断。

**检测线程是否被中断**

在实际开发中，要判断中断状态位是否被置位，首先使用静态方法 Thread.currentThread() 方法来获取当前线程，在调用 interrupted() 方法来判断中断位的状态。如下：

```java
while (!Thread.currentThread().interrupted() && more work to do) {}
```

**interrupted 和 isInterrupted 区别**

interrupted 是一个静态方法，他检测当前线程是否中断，并且会清除当前线程的中断位。isInterrupted 是一个实例方法，检测线程中断位，不会清除状态位。

**如何中断线程**

如果线程被Object.wait, Thread.join和Thread.sleep三种方法之一阻塞，那么，它将接收到一个中断异常（InterruptedException），从而提早地终结被阻塞状态。interrupt 不会中断一个正在运行的线程。

要注意的是，中断线程不等于终止线程，interrupt 只是只是改变了线程的状态位，来引起线程的注意或是唤醒沉睡的线程。但是当线程注意到（捕获到InterruptedException异常或是检测到状态位的改变），可以自行决定如何处理该线程，比如，可以让线程捕获异常后继续执行，或是中断线程。

在实际操作中，一般会把线程中断当做线程结束的条件，格式如下：

```java
@Override
public void run() {
    while(!Thread.currentThread().isInterrupted() ){
        try{
            //处理正常的逻辑
            Thread.sleep(100);
        }catch (InterruptedException e){
            //被中断后的进入

            //由于抛出异常后会把状态位改变，所以这里应该手动改变状态位
            Thread.currentThread().interrupt();
        }finally{
            // 线程结束前的后续操作
        }
    }
}
```

一般不会在捕获的异常中不进行任何操作，这样可能会处理不当中断，比如：

```java
@Override
public void run() {
    try{
        Thread.sleep(100);
    }catch (InterruptedException e){ }
}
```

选择抛出异常，也是很好的选择：

```java
void mySubTask() throws InterruptedException {
           ...
        sleep(delay);
           ...
}
```

**如何中断一个线程**

 **实例一：**

```java
public class Example1 implements Runnable{
    private float d;
    @Override
    public void run() {
        while(true){
            for(int i=0;i<10000000;i++){
                d = (float) (d + (Math.PI + Math.E) / d);
            }
            System.out.println("I'm counting......");
            //转让调度器使用权
            Thread.yield();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        Example1 example1 = new Example1();
        Thread t1 = new Thread(example1);
        t1.start();

        Thread.sleep(100);

        System.out.println("开始中断线程。。。。。。");
        t1.interrupt();
    }
}
```

输出：

```
I'm counting......
开始中断线程。。。。。。
I'm counting......
I'm counting......
I'm counting......
I'm counting......
```

可以看出来，线程被调用interrupt方法后，并没有被中断，任然在运行，所以说，interrupt 方法并不能是线程终止运行。

要是线程中断运行，有三种方法，抛出Interrupt异常，使用 Thread.interrupted() 不断检查中断状态位，使用信号量进行控制。

**方法一：信号量法**

```java
class Example2 implements Runnable{

    public static boolean isLive = true;
    float d;
    @Override
    public void run() {
        while(isLive){
            for(int i=0;i<10000000;i++){
                d = (float) (d + (Math.PI + Math.E) / d);
            }
            System.out.println("I'm counting......");
            //转让调度器使用权
            Thread.yield();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        Example2 e2 = new Example2();
        Thread t1 = new Thread(e2);
        t1.start();

        Thread.sleep(100);

        System.out.println("开始中断线程。。。。。。");

        //设置改变信号量
        e2.isLive = false;
    }
}
```

输出结果：

```
I'm counting......
开始中断线程。。。。。。
I'm counting......
```

**方法二：抛出异常法**

```java
public class Example1 implements Runnable{

        private double d = 0.0;
        public void run() {
            //死循环执行打印"I am running!" 和做消耗时间的浮点计算
            try {
                while (true) {
                    System.out.println("I am running!");
                    for (int i = 0; i < 900000; i++) {
                        d =  d + (Math.PI + Math.E) / d;
                    }
                    //休眠一断时间,中断时会抛出InterruptedException
                    Thread.sleep(50);
                }
            } catch (InterruptedException e) {
                System.out.println("ATask.run() interrupted!");
            }
    }

    public static void main(String[] args) throws InterruptedException {
        Example1 example1 = new Example1();
        Thread t1 = new Thread(example1);
        t1.start();

        Thread.sleep(100);

        System.out.println("开始中断线程。。。。。。");
        t1.interrupt();
    }
}
```

输出结果

```
I am running!
I am running!
开始中断线程。。。。。。
ATask.run() interrupted!
```

**方法三：\**Thread.interrupted()监听\****

```java
class Example3 implements Runnable {
    @Override
    public void run() {
        while (!Thread.currentThread().interrupted()) {
            try {
                Thread.sleep(100);
                System.out.println("I'm counting......");
            } catch (InterruptedException e) {
                //设置状态位
                Thread.currentThread().interrupt();
            }
        }
    }

    public static void main(String[] args) throws InterruptedException {
        Example3 e = new Example3();
        Thread t1 = new Thread(e);
        t1.start();

        Thread.sleep(800);

        System.out.println("开始中断线程。。。。。。");

        t1.interrupt();

    }
}
```

输出为：

```
I'm counting......
I'm counting......
I'm counting......
I'm counting......
I'm counting......
I'm counting......
开始中断线程。。。。。。
```

**被遗弃的stop和suspend**

早起的Java版本提供了stop方法来终止一个线程，以及suspend来阻塞一个线程直到另一个线程调用resume来唤醒线程。stop和suspend这两个方法都试图控制给定线程的想行为。

stop 方法试图终止一个线程的执行，包括未执完的run方法，其本身是很不安全的。比如说，当一个线程试图从一个账户转账到另一个账户，一个线程已经把钱取出来了，但是此正好被stop终止了线程，但是钱却没有转到另一个账户。这样的突然终止导致银行对象出于不稳定的状态。虽然此时锁被释放了，但是他的不稳定状态却不能被其他线程看到，这是很危险的。

suspend 方法用来挂起一个锁，虽然不会破坏对象，但是有可能导致死锁。假设如果用suspend方法挂起一个拥有锁的线程，那么，该锁在恢复之前是不可用的。如果此时，调用suspend方法的线程试图获取同一个锁，那么，此时就会出现死锁。
