---
title: "Java多线程学习之synchronized总结"
date: 2017-11-19T14:14:42+08:00
Author: Luky116
tags: ["synchronized","源码"]
categories: ["Java多线程"]
---



## 0、概述

　　synchronized是Java提供的内置的锁机制，来实现代对码块的同步访问，称为**内置锁（Intrinsic Lock）** 。内置锁包括两部分：一个是作为锁的对象的引用，另一个是由这个锁保护的代码块。需要理解的是，**synchronized的锁都是对象的引用，同一个对象只有一个内置锁，不同的对象有不同的内置锁。**

　　Java 的内置锁是一种互斥锁，即一个对象的锁只能同时被一个线程持有。假设线程A尝试获取线程B持有的锁，线程A会被阻塞，知道B释放该锁，A才能持有该锁。**如果线程B永远不是释放该锁，线程A也将永远等待下去，形成死锁。** 由于线程在等待内置锁的过程中无法被中断，这是synchronized内置锁的一个弊端，该需求可以被显示锁ReentranLock解决，可以参考这篇博客：http://www.cnblogs.com/moongeek/p/7857794.html。

　　获得一个对象内置锁的唯一途径就是进入由该对象锁保护的代码块，释放锁的唯一途径是跳出该代码块。一般synchronized使用方法如下：

```java
synchronized(lock){
    // 访问或修改由该锁保护的共享状态
}
```

## 1、synchronized的使用

　　synchronized可以修饰一般方法、static方法、代码块，但是不论synchronized修饰什么，他获取的都是一个对象的内置锁，锁的单位都是对象。

　　1）synchronized 修饰一般方法，锁是持有该方法的对象的锁，访问同一个类的相同方法时候会互斥。

```java
public synchronized void doSomething(){     
    // ...
}
```

上代码等价于：

```java
public void doSomething(){ 
    synchronized(this){
          // ...
    }
}
```

　　2）synchronized 修饰代码块，锁是指定的对象的锁，如果是同一个对象的锁，那么会互斥访问。

```java
// 锁为object对象的锁
synchronized(object){
  
}
```

　　3）synchronized 修饰静态方法，锁是该类Class对象的锁，该类的所有对象访问该类时都会互斥。

```java
public class Demo{
    public synchronized static void doSomething(){
        // ...
    }
}
```

上代码等价于：

```java
public class Demo{
    public static void doSomething(){
        synchronized(Demo.class){
            // ...
        }
    }
}    
```

## 2、可重入性

　　当某个线程请求一个已经被其他线程持有的锁时，该线程会被阻塞。但是内置锁是可重入的，因此，如果一个内置锁尝试获得已经由他自己持有的锁，那这个请求会立即成功。“重入”意味着获取锁的操作粒度是“线程”而不是”调用“。

　　重入的实现方法是，为每个所关联一个锁和一个计数值。当计数值为0时，这个锁就被认为是没有被任何线程持有。当线程请求一个未被持有的线程时，JVM记下这个持有者，并且将计数值增1.如果同一个线程再次获得这个锁，计数值将增加，而当线程退出同步代码块时，计数器相应的递减。当计数值为0，这个锁将被释放。

```java
public class Test {
    private Object  lock;

    public synchronized void saySomething(){

    }

    public synchronized void doSomething(){
        // 两个函数都是同一个对象锁，可重入
        saySomething();
    }

    public void goSomewhere(){
        // 对象锁不一致，不能重入
        synchronized (lock){
            saySomething();
        }
    }
}
```
