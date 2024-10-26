---
title: "Java中Comparable和Comparator比较"
date: 2017-10-02T14:29:03+08:00
Author: Luky116
tags: ["Comparable","源码"]
categories: ["Java源码"]
---

## 1、Comparable 介绍

 Comparable 是一个排序接口，如果一个类实现了该接口，说明该**类本身是可以进行排序**的。注意，除了**基本数据类型（八大基本数据类型）** 的数组或是List，其余类型的对象，Collections.sort或Arrays.sort 是不支持直接进行排序的，因为对象本身是没有“顺序”的，除非你实现了Comparable 接口或是自定义了Comparable 对象，指定了排序规则，才可以进行排序。

 Comparable 源码就一个方法,

```java
public interface Comparable<T> {
     public int compareTo(T o);
 }
```

泛型T表示要进行比较的对象所属的类型，compareTo 比较对象之间的值的大小关系，如果该对象小于、等于或大于指定对象，则分别返回负整数、零或正整数。

 定义一个对象：

```java
public class Person implements Comparable<Person>{
  public int age;

  public Person(int age){
    this.age = age;
  }
  public String toString() {
    return "{" +
      "age=" + age +
      '}';
  }
  @Override
  public int compareTo(Person o) {
    //Person 对象之间根据名字排序
    return this.age - o.age;
  }
}
```

排序测试：

```java
public static void main(String[] args) {
        Person[] ps =new Person[]{new Person(1),new Person(4),
new Person(2),new Person(7),new Person(9),new Person(8),
new Person(3),new Person(0),new Person(1)};
        System.out.println("排序前："+Arrays.toString(ps));
          //进行排序
        Arrays.sort(ps);
        System.out.println("排序后："+Arrays.toString(ps));
    }
```

 

```
排序前：[{age=1}, {age=4}, {age=2}, {age=7}, {age=9}, {age=8}, {age=3}, {age=0}, {age=1}]
排序后：[{age=0}, {age=1}, {age=1}, {age=2}, {age=3}, {age=4}, {age=7}, {age=8}, {age=9}]
```

## 2、Comparator 介绍

 如果一个类本身并没有实现 Comparable 接口，我们想要对他进行排序，就要自定义 Comparator 比较器进行比较，在这个比较器里面自定义排序的依据。

 Comparator 源码中主要的两个接口方法：

```java
public interface Comparator<T>
  {
     int compare(T o1, T o2);
     boolean equals(Object obj);
  }
```

compare 是主要方法，必须要实现，equals 方法可以不实现。compare 中返回比较结果，如果该对象小于、等于或大于指定对象，则分别返回负整数、零或正整数。

 定义一个用来排序类，该类并为实现 Comparable 接口：

```java
private static class Man{
    public int age;
    public Man(int age){
        this.age = age;
    }
    public String toString() {
        return "{" +
                "age=" + age +
                '}';
    }
}
```

进行排序：

```java
@Test
public void test_1(){
        Man[] ps =new Man[]{new Man(1),new Man(4),new Man(2),
                new Man(7),new Man(9),new Man(8),new Man(3),new Man(0),new Man(1)};
        //数组转List
        ArrayList<Man> ap = new ArrayList<Man>(Arrays.asList(ps));

        System.out.println("排序前："+ap);
        //自定义排序器
        Collections.sort(ap,new Comparator<Man>() {
            @Override
            public int compare(Man o1, Man o2) {
              //根据年龄进行排序
                return o1.age - o2.age;
            }
        });

        System.out.println("排序后："+ ap);
}
```

 

```
排序前：[{age=1}, {age=4}, {age=2}, {age=7}, {age=9}, {age=8}, {age=3}, {age=0}, {age=1}]
排序后：[{age=0}, {age=1}, {age=1}, {age=2}, {age=3}, {age=4}, {age=7}, {age=8}, {age=9}]
```

## 3、总结比较 

 Comparable 在类的内部定义排序规则，Comparator 在外部定义排序规则，Comparable 相当于“内部排序器”，Comparator 相当于“外部排序器”，前者一次定义即可，后者可以在不修改源码的情况下进行排序，各有所长。
