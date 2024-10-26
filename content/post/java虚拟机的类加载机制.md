---
title: "Java虚拟机的类加载机制"
date: 2017-09-15T14:43:00+08:00
Author: Luky116
tags: ["JVM类加载"]
categories: ["JVM"]
---

**关于类加载机制：**

​	虚拟机把描述类的数据从Class 文件加载到内存，并对数据进行效验、转换解析和初始化，最终 形成可以被虚拟机直接使用的Java 类型，就是虚拟机的类加载机制。

## 1、初始化 时机

1、遇到 new 、getstatic 、putstatic 、invokestatic 这四个字节码指令时。触发这四条指令的场景：

- 使用new 实例化对象时
- 读取或设置一个类的静态字段（被final修饰，已在编译期把结果放入常量池的不算（即 常量不算，static final 修饰））
- 调用一个类的静态方法

2、使用反射调用时，先进行初始化

3、初始化一个类时，若其父类未被初始化，则先初始化其父类。

4、当虚拟机启动时，用户需要指定一个要执行的主类（main() 函数所在的类），虚拟机会先初始化它。

5、jdk 7.0 中，动态语言的支持



**以上称为主动引用，被动引用不会引起初始化：**



现有如下两个类：

~~~java
class SuperClass{
    static {
        System.out.println("SuperClass init !!!");
    }
    public static int value = 123;
}

class SubClass extends SuperClass{
    static {
        System.out.println("SubClass init !!!");
    }
  
   public static final String HELLO_WORLG = "hello world !";
}
~~~



- 测试一：

~~~java
  public static void main(String[] args) {
  	System.out.println(SubClass.value);
  }
~~~

  运行结果

~~~java
  SuperClass init !!!
  123
~~~

  - 对于静态变量，只有直接定义这个变量的类才会进行初始化，如子类调用父类的静态变量，只有父类会进行初始化，子类不会自动进行初始化。


- 测试二：

~~~java
  public static void main(String[] args) {
    System.out.println(SubClass.HELLO_WORLG);
  }
~~~

  运行结果：

~~~java
  hello world !
~~~

  - 常量在在编译期通过常量传播优化，将“hello world !“存储到了常量池中，也就是说，”SubClass.HELLO_WORLG“并没有通过SubClass类符号进行引用，二者并没有任何联系。所以不会导致该类初始化。

## 2、加载

- 通过类的权限定名来获取此类的二进制字节流
- 把字节流代表的静态数据结构转化为方法区的运行时数据结构
- 在方法区中生成一个代表这个类的Class 对象

## 3、验证

​	确保class文件的字节流中的信息是安全的，至少不会危害虚拟机自身的安全。只有通过了这阶段的验证，字节流才会进入内存的方法区进行存储。

## 4、准备

- 为**类变量**分配内存并设置初始零值，这些变量的内存在方法区中进行分配。

- 常量会设置最终值，如：

~~~java
  public static int value = 123;
  public static final int con = 234;
~~~

  准备期过后，会把value置为0，con的值置为234。

## 5、解析

​	将常量池中的**符号引用**替换为**直接引用**。这一阶段会根据需要发生在初始化之前或之后，包含类或接口解析、字段解析、方法解析。

​	**符号引用**是无关虚拟机实现的内存布局。**直接引用**是和虚拟机实现内存布局相关的，符号引用必须在运行期转换获得真正的内存入口地址。

## 6、初始化<init>

​	开始真正执行类中定义的 Java 代码，初始化阶段是执行类构造器<init>() 方法的过程

- <init>() 是编译期收集类中所有的**类变量的赋值动作**和**静态语句块中（static{}）的语句**结合而成的。静态语句块只能访问惊天语句块之前的变量，定义在其之后的变量，只能赋值，不能访问

~~~java
  static {
          i = 0;                       //可以给变量赋值编译通过
          System.out.println(i);      //使用变量编译不通过
      }
      
  static int i;
~~~

- <init>() 方法和构造函数不同。子类不会显示的调用父类的init() 方法，但是虚拟机会保证子类init() 方法被调用之前，父类的init() 会被先调用。

~~~java
  public class InitDemo_2 {
      public static void main(String[] args) {
          System.out.println(SubClass1.B);
      }
  }

  class SuperClass1{
     public static int A = 1;
      static {
          A = 2;
      }
  }
  class SubClass1 extends SuperClass1{
      public static int B = A;
  }
~~~



  运行结果：

~~~java
  2
~~~



- 接口中不会有静态语句块，但是接口中可以有赋值语句，因此接口也会生成<init>() ，但是，执行接口的<init>() 不需要先执行父类的<init>() ，除非父类的变量被执行，才会调用父类的<init>() 。
- <init>() 方法只会被执行一次

## 7、类加载机制

三种类加载器

   - 启动类加载器（Bootstrap ClassLoader）

    ​	负责加载 JAVA_HOME/lib 目录下，或被-XbootclassPath 参数指定的路径下的类库。

  - 拓展类加载器（Extension ClassLoader）

    ​	负责加载 JAVA_HOME/lib/ext 目录下或者被 java.ext.dirs 系统变量所指定的路径中的所有类库。

  - 应用程序类加载器（Application ClassLoader）

    ​	是ClassLoader.getSystemClassLoasder() 方法的返回值，负责加载用户类路径上所指定的类库。

双亲委派模型

  - 类加载器通过组合的方式建立的父子关系，称为双亲委派模型。

  - 类需要有加载他的类加载器和类本身一起确定其在虚拟机中的唯一性。

  - 工作流程

    ​	一个类加载器收到了类加载加载的请求，他首先不会尝试自己加载这个类而是把这个请求委派给父类加载器来完成。只有父类无法完成这个请求时，子加载器才会尝试自己去加载。

  - 作用

    ​	Java 类随着他的类加载器一起具备了一种带优越级的层级关系，所有的加载请求都会传送到顶层的启动类加载器中，保证了Java 的稳定运行。
