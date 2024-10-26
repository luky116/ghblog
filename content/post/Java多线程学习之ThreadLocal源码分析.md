---
title: "Java多线程学习之ThreadLocal源码分析"
date: 2017-11-20T14:09:22+08:00
Author: Luky116
tags: ["ThreadLocal","源码"]
categories: ["Java多线程","Java源码"]
---



## 0、概述

　　ThreadLocal，即线程本地变量。它是将变量绑定到特定的线程上的“入口“，使每个线程都拥有改变量的一个拷贝，各线程相同变量间互不影响，是实现共享资源的轻量级同步。

　　下面是个ThreadLocal使用的实例，两个任务共享同一个变量，并且两个任务都把该变量设置为了线程私有变量，这样，虽然两个任务都”持有“同一变量，但各自持有该变量的拷贝。因此，当一个线程修改该变量时，不会影响另一线程该变量的值。

```java
public class LocalTest1 implements Runnable {
    // 一般会把 ThreadLocal 设置为static 。它只是个为线程设置局部变量的入口，多个线程只需要一个入口
    private static ThreadLocal<Student> localStudent = new ThreadLocal() {
        // 一般会重写初始化方法，一会分析源码时候会解释为什么
        @Override
        public Student initialValue() {
            return new Student();
        }
    };

    private Student student = null;

    @Override
    public void run() {
        String threadName = Thread.currentThread().getName();

        System.out.println("【" + threadName + "】：is running !");

        Random ramdom = new Random();
        //随机生成一个变量
        int age = ramdom.nextInt(100);

        System.out.println("【" + threadName + "】：set age to :" + age);
        // 获得线程局部变量，改变属性值
        Student stu = getStudent();
        stu.setAge(age);

        System.out.println("【" + threadName + "】：第一次读到的age值为 :" + stu.getAge());

        try {
            TimeUnit.SECONDS.sleep(2);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        System.out.println("【" + threadName + "】：第二次读到的age值为 :" + stu.getAge());
    }

    public Student getStudent() {
        student = localStudent.get();

        // 如果不重写初始化方法，则需要判断是否为空，然后手动为ThreadLocal赋值
//        if(student == null){
//            student = new Student();
//            localStudent.set(student);
//        }

        return student;
    }

 public static void main(String[] args) {
        LocalTest1 ll = new LocalTest1();
        Thread t1 = new Thread(ll, "线程1");
        Thread t2 = new Thread(ll, "线程2");

        t1.start();
        t2.start();
    }
}

public class Student{
    private int age;

    public Student(){

    }
    public Student(int age){
        this.age = age;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }
}
```

运行结果：

```
【线程1】：is running !
【线程2】：is running !
【线程2】：set age to :45
【线程1】：set age to :25
【线程1】：第一次读到的age值为 :25
【线程2】：第一次读到的age值为 :45
【线程1】：第二次读到的age值为 :25
【线程2】：第二次读到的age值为 :45
```

## 1、ThreadLocal 源码分析

　　ThreadLocal 源码有很多方法，但是暴露出来的公共接口只有三个：

```java
public ThreadLocal{
  public T get() {}
  public void set(T value) {}
  public void remove() {}
}
```

　　 `set(T value)` 是设置局部变量的方法，源码如下：

```java
public void set(T value) {
      // 获得当前线程
    Thread t = Thread.currentThread();
      // 获得当前线程的 ThreadLocalMap 引用，详细见下
    ThreadLocalMap map = getMap(t);
      // 如果不为空，则更新局部变量的值
    if (map != null)
      map.set(this, value);
      //如果不是第一次使用，先进行初始化
    else
      createMap(t, value);
 }
```

`getMap(t)` 源码如下，每一个Thread变量都自带了一个ThreadLocalMap类型的成员变量，用于保存该线程的成员变量。

```java
ThreadLocalMap getMap(Thread t) {
   //返回该线程Thread的成员变量threadLocals
    return t.threadLocals;
 }
```

　　但是，Thread 默认把threadLocals设置为了null，因此第一次使用局部变量时候需要先初始化。

```java
ThreadLocal.ThreadLocalMap threadLocals = null;
```

　　`ThreadLocalMap` 是定义在`ThreadLocal` 类里的内部类，它的作用是存储线程的局部变量。`ThreadLocalMap` 以ThreadLocal的引用作为键，以局部变量作为值，存储在`ThreadLocalMap.Entry` （一种存储键值的数据结构）里。关于`ThreadLocalMap` 的源码，后文会详细介绍，这里只要知道大概原理即可。

　　由此我们可以总结`ThreadLocal` 的设计思想如下：

1. `ThreadLocal` 只是个访问局部变量的入口。
2. 局部变量的值存在线程`Thread` 类本地，默认为null，只有通过`ThreadLocal` 访问时才会进行初始化。
3. [ThreadLocalMap 的设计思路在后文介绍`ThreadLocalMap` 源码时候会分析]

`get()` 是获得线程本地变量，源码如下：

```java
public T get() {
      //获得当前线程
    Thread t = Thread.currentThread();
      //得到当前线程的一个threadLocals 变量
    ThreadLocalMap map = getMap(t);
    if (map != null) {
      // 如果不为空，以当前ThreadLocal为主键获得对应的Entry
      ThreadLocalMap.Entry e = map.getEntry(this);
      if (e != null) {
        @SuppressWarnings("unchecked")
        T result = (T)e.value;
        return result;
      }
    }
      //如果值为空，则进行初始化
    return setInitialValue();
}
```

再来看看初始化函数`setInitialValue()` 所进行的操作：

```java
private T setInitialValue() {
      //获得初始默认值
    T value = initialValue();
      //得到当前线程
    Thread t = Thread.currentThread();
      // 获得该线程的ThreadLocalMap引用
    ThreadLocalMap map = getMap(t);
      //不为空则覆盖
    if (map != null)
        map.set(this, value);
    else
          //若是为空，则进行初始化，键为本ThreadLocal变量，值为默认值
        createMap(t, value);
}

// 默认初始化返回null值，这也是为什么需要重写该方法的原因。如果没有重写，第一次get()操作获得的线程本地变量为null，需要进行判断并手动调用set()进行初始化
protected T initialValue() {
    return null;
}
```

## 2、ThreadLocalMap 源码分析

　　Thread类中包含一个ThreadLocalMap 类型的成员变量threadLocals，这是直接存储线程局部变量的数据结构。ThreadLocal 只是一个入口，通过ThreadLocal操作threadLocals，进行局部变量的查改操作。这也是为什么ThreadLocal 暴露的公有接口才三个的原因吧。同时，由于ThreadLocalMap 中的键是ThreadLocal类，也说明了，如果想为一个线程设置多个本地局部变量，需要设置多个 ThreadLocal。下面来分析下ThreadLocalMap 的源码。

　　`ThreadLocalMap` 里有几个核心的属性，和HashMap相似：

```java
// table 默认大小，大小为2的次方，用于hash定位
private static final int INITIAL_CAPACITY = 16;
// 存放键值对的数组
private Entry[] table;
// 扩容的临界值，当table元素大到这个值，会进行扩容
private int threshold;
```

　　在调用ThreadLocal 中的`set(T)` 方法时，调用了ThreadLocalMap 的`set(ThreadLocal, T)` 方法，

```java
private void set(ThreadLocal<?> key, Object value) {
     Entry[] tab = table;
     int len = tab.length;
        // Hash 寻址，与table数组长度减1（二进制全是1）相与，所以数组长度必须为2的次方，减小hash重复的可能性
     int i = key.threadLocalHashCode & (len-1);

       //从hash值计算出的下标开始遍历
     for (Entry e = tab[i];
          e != null;
          e = tab[i = nextIndex(i, len)]) {
       //获得该Entry的键
       ThreadLocal<?> k = e.get();
        //如果键和传过来的相同，覆盖原值，也说明，一个ThreadLocal变量只能为一个线程保存一个局部变量
       if (k == key) {
         e.value = value;
         return;
       }
       // 键为空，则替换该节点
       if (k == null) {
         replaceStaleEntry(key, value, i);
         return;
       }
     }

     tab[i] = new Entry(key, value);
     int sz = ++size;
       //是否需要扩容
     if (!cleanSomeSlots(i, sz) && sz >= threshold)
       rehash();
 }
```

　　为什么说数组长度为2的次方有利于hash计算不重复呢？我们来看下，显然，和一个二进制全是1的数相于，能最大限度的保证原数的所有位数，因而重复几率会变小。![img](http://images2017.cnblogs.com/blog/834666/201711/834666-20171120153628180-743076057.jpg)

　　可以看出ThreadLocalMap 采用**线性探测再散列**解决Hash冲突的问题。即，如果一次Hash计算出来的数组下标被占用，即hash值重复了，则在该下标的基础上加1测试下一个下标，直到找到空值。比如说，Hash计算出来下标i为6，table[6] 已经有值了，那么就尝试table[7]是否被占用，依次类推，直到找到空值。以上，就是保存线程本地变量的方法。

　　再来分析下ThreadLocal 中的`get()` 方法，其中调用了ThreadLocalMap 的`map.getEntry(this)` 方法，并把本ThreadLocal作为参数传入，返回一个`ThreadLocalMap.Entry`对象（以后简称Entry），源码如下：

```java
private Entry getEntry(ThreadLocal<?> key) {
      //Hash计算数组下标
    int i = key.threadLocalHashCode & (table.length - 1);
      //得到该下标的节点
    Entry e = table[i];
      //如果该节点存在，并且键和传过来的ThreadLocal对象相同，则返回该节点（说明该节点没有进行Hash冲突处理）
    if (e != null && e.get() == key)
      return e;
      //如果该节点不直接满足需求，可能进行了Hash冲突处理，则另外处理
    else
      return getEntryAfterMiss(key, i, e);
}
```

　　再来分析下`getEntryAfterMiss(ThreadLocal, int , Entry)` 的源码：

```java
//  if (e == null || e.get() != key)
private Entry getEntryAfterMiss(ThreadLocal<?> key, int i, Entry e) {
    Entry[] tab = table;
    int len = tab.length;
    //从洗标为i开始遍历，直到遇到下一空节点或或是满足需求的节点
    while (e != null) {
        ThreadLocal<?> k = e.get();
        if (k == key)
            return e;
        if (k == null)
              //节点不为空，键为空，则清理该节点
            expungeStaleEntry(i);
        else
              // i后移
            i = nextIndex(i, len);
        e = tab[i];
    }
      //否则返回空值
    return null;
}
```

　　以上就是ThreadLocalMap 几个比较关键的源码分析。

## 3、总结

　　综上所述可知，ThreadLocal 只是访问Thread本地变量的一个入口，正真存储本地变量的其实是在Thread本地，同时ThreadLocal也作为一个键去Hash找到变量所在的位置。也许你会想，为什么不把ThreadLocalMap设置为< Thread,Variable>类型，把Thread作为主键，而要增加一个中间模块ThreadLocal？我的想法是，一来，这样确实可以满足需求，但是这样无法进行hash查找，如果一个Thread的本地变量过多，通过线性查找会花费大量时间，使用ThreadLocal作为中间键，可以进行Hash查找；二来，其实本地变量的添加、查找和删除需要进行大量的操作，设计者的思路是把这些操作封装在一个ThreadLocal类里，而只暴露了三个常用的接口，如果把ThreadLocal去掉，这些操作可能要写在Thread类里，违背了设计类的“单一性”原则；三来，我们这样相当于为每个本地变量取了个“名字”（即，一个ThreadLocal对应一个本地变量），使用方便。
