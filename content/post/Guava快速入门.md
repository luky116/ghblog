---
title: "Guava 快速入门"
date: 2020-06-05T17:00:17+08:00
Author: Luky116
tags: ["Guava"]
categories: ["Guava"]
---

> **Guava**工程包含了若干被Google的 Java项目广泛依赖 的核心库，例如：**集合 [collections] 、缓存 [caching] 、原生类型支持 [primitives support] 、并发库 [concurrency libraries] 、通用注解 [common annotations] 、字符串处理 [string processing] 、I/O** 等等。

**Guava** 是Java的工具集，提供了一些常用的便利的操作工具类，减少因为 空指针、异步操作等引起的问题BUG，提高开发效率。

本文主要介绍了Guava常用的工具方法，快速入门Guava。

## 1、基本工具（Base utils）

### 1. Optional

**null** 值出现在代码中，有如下缺点：

1. 语义模糊，引起歧义。例如，Map.get(key)返回Null时，可能表示map中的值是null，亦或map中没有key对应的值。
2. 在应用层面可能造成混乱，出现令人意外的错误。

为了尽量避免程序中的**null**值，guava提供了**Optional**对数据进行封装。如果值为空则立即抛出异常，并且提供了**Absent**和**Present**两个子类分别表示**值缺失**和**值存在**的情形，来增强**null**的语义。

常用方法如下：

1. **isPresent()**：如果Optional包含非null的引用（引用存在），返回true

2. **get()** ：如果Optional为NULL将触发异常

   ~~~java
   public static void test(){
     Optional<Integer> possible = Optional.fromNullable(5);  //创建允许null值的Optional
     if(possible.isPresent()){//包含的引用非null的（引用存在），返回true
      System.out.println(possible.get());
     }else{
       System.out.println("possible is null");
     }
   }
   ~~~

3. **or(defaultvalue)** ：包含的引用缺失(null)，返回默认的值，否则返回本身

4. **orNull()**：包含的引用缺失，返回null

5. **asSet()**：如果引用存在，返回只有单一元素的集合；若为NULl返回空集合

### 2. 先决条件 Preconditions

Preconditions 提供了判断条件是否合法的静态方法，如果不符合要求会抛出异常。类似断言。

| 方法声明（不包括额外参数）                         | 描述                                                         | 检查失败时抛出的异常      |
| -------------------------------------------------- | ------------------------------------------------------------ | ------------------------- |
| checkArgument(boolean)                             | 检查boolean是否为true，用来检查传递给方法的参数              | IllegalArgumentException  |
| checkNotNull(T)                                    | 检查value是否为null，该方法直接返回value，因此可以内嵌使用checkNotNull | NullPointerException      |
| checkState(boolean)                                | 用来检查对象的某些状态。                                     | IllegalStateException     |
| checkElementIndex(int index, int size)             | 检查index作为**索引值**对某个列表、字符串或数组是否有效。index>=0 && index<size | IndexOutOfBoundsException |
| checkPositionIndex(int index, int size)            | 检查index作为**位置值**对某个列表、字符串或数组是否有效。index>=0 && index<=size | IndexOutOfBoundsException |
| checkPositionIndexes(int start, int end, int size) | 检查[start, end]表示的位置范围对某个列表、字符串或数组是否有效 | IndexOutOfBoundsException |

每个判断方法都有三个多态方法：

- 没有额外参数：抛出的异常中没有错误消息；

- 有一个Object对象作为额外参数：抛出的异常使用Object.toString() 作为错误消息；

- 有一个String对象作为额外参数，并且有一组任意数量的附加Object对象：这个变种处理异常消息的方式有点类似printf，但考虑GWT的兼容性和效率，只支持%s指示符。例如：

  ~~~java
  checkArgument(i >= 0);
  checkArgument(i >= 0, "Argument was expected nonnegative");
  checkArgument(i < j, "Expected i < j, but %s > %s", i, j);
  ~~~

### 3. 连接器 Joiner

用分隔符将多个**字符串（或数组元素）**连接成一个字符串。

常用方法如下：

1. **on(String)**：静态工厂方法，生成一个新的 **Joiner** 对象，参数为连接符
2. **skipNulls()**：如果元素为空，则跳过
3. **useForNull(String)**：如果元素为空，则用这个字符串代替
4. **join(数组/链表)**：要连接的数组/链表
5.  **appendTo(String,数组/链表)**：在第一个参数后面新加上 拼接后的字符串
6.  **withKeyValueSeparator(String)**：得到 **MapJoiner**，连接Map的键、值

~~~java
@Test
public void test(){
  List<String> list1 = Arrays.asList("aa", "bb", "cc");
  System.out.println(Joiner.on("-").join(list1));
  
  List<String> list2 = Arrays.asList("aa", "bb", "cc", null, "dd");
  System.out.println(Joiner.on("-").skipNulls().join(list2));
  System.out.println(Joiner.on("-").useForNull("nulla").join(list2));
  
  Map map = ImmutableMap.of("k1", "v1", "k2", "v2");
  System.out.println(Joiner.on("-").withKeyValueSeparator("=").join(map));
}
~~~

输出：

~~~
aa-bb-cc
aa-bb-cc-dd
aa-bb-cc-null-dd
k1=v1-k2=v2
~~~

**注意**：joiner实例总是**不可变**的。用来定义joiner目标语义的配置方法总会返回一个新的joiner实例。这使得joiner实例都是**线程安全**的，你可以将其定义为static final常量。

### 4.  拆分器 Splitter

**Splitter** 能将一个字符串按照分隔符生成字符串集合，是 **Joiner**的反向操作。

常用方法如下：

1. **on(String)**：静态工厂方法，生成一个新的 **Splitter** 对象，参数为连接符

2.  **trimResults()**：结果去除子串中的空格

3.  **omitEmptyStrings()**：去除null的子串

4. **split(String)**：拆分字符串

5. **withKeyValueSeparator(String)**：得到 **MapSplitter**，拆分成Map的键、值。注意，这个对被拆分字符串格式有严格要求，否则会抛出异常

   ~~~java
   @Test
   public void test1(){
     String string = " ,a,b,";
     System.out.println(Splitter.on(",").split(string));
     System.out.println(Splitter.on(",").trimResults().split(string));
     System.out.println(Splitter.on(",").omitEmptyStrings().split(string));
     System.out.println(Splitter.on(",").trimResults().omitEmptyStrings().split(string));
     
     // 根据长度拆分
     string = "12345678";
     System.out.println(Splitter.fixedLength(2).split(string));
     
     // 拆分成Map
     System.out.println(Splitter.on("#").withKeyValueSeparator(":").split("1:2#3:4"));
   }
   ~~~

   输出如下：

   ~~~
   [ , a, b, ]
   [, a, b, ]
   [ , a, b]
   [a, b]
   [12, 34, 56, 78]
   {1=2, 3=4}
   ~~~

### 5. 字符串处理 Strings 

**Strings** 类主要提供了对字符串的一些操作。主要方法如下：

1. nullToEmpty(String string) ：null字符串转空字符串

2. emptyToNull(String string)：空字符串转null字符串

3. isNullOrEmpty(String string)：判断字符串为null或空字符串

4. padStart(String string, int minLength, char padChar)：如果string的长度小于minLeng，在string前添加padChar，直到字符串长度为minLeng。

   ~~~java
   @Test
   public void test(){
     String aa = "12345";
     
     // A12345
     System.out.println(Strings.padStart(aa, 6, 'A'));
     // 12345
     System.out.println(Strings.padStart(aa, 5, 'A'));
   }
   ~~~

5.  String padEnd(String string, int minLength, char padChar)：和padStart类似，不过是在尾部添加新字符串

6.  commonPrefix(CharSequence a, CharSequence b)：返回共同的前缀

7.  commonSuffix(CharSequence a, CharSequence b)：返回共同的后缀

   ~~~java
   @Test
   public void test2(){
     String aa = "abc123def";
     String bb = "abc789def";
   
     System.out.println(Strings.commonPrefix(aa, bb));
     System.out.println(Strings.commonSuffix(aa, bb));
   }
   ~~~

   输出如下：

   ~~~
   abc
   def
   ~~~

## 2、集合工具（Collections）

### 1. 不可变集合

不可变集合，即创建后就**只可读，不可修改**的集合。为什么要使用不可变集合呢？主要有如下优点（**摘自官方文档**）：

- 当对象被不可信的库调用时，不可变形式是安全的；
- 不可变对象被多个线程调用时，不存在竞态条件问题
- 不可变集合不需要考虑变化，因此可以节省时间和空间。所有不可变的集合都比它们的可变形式有更好的内存利用率（分析和测试细节）；
- 不可变对象因为有固定不变，可以作为常量来安全使用。

JDK也提供了Collections.unmodifiableXXX方法把集合包装为不可变形式，但我们认为不够好：

- 笨重而且累赘：不能舒适地用在所有想做防御性拷贝的场景；

- 不安全：要保证没人通过原集合的引用进行修改，返回的集合才是事实上不可变的；

  ~~~java
  @Test
  public void test3(){
    List<Integer> list = Lists.newArrayList(1,2,3);
    List<Integer> list1 = Collections.unmodifiableList(list);
  
    // [1, 2, 3]
    System.out.println(list);
    // [1, 2, 3]
    System.out.println(list1);
    // list修改，list1也会被修改
    list.add(4);
    // [1, 2, 3, 4]
    System.out.println(list1);
  }
  ~~~

- 低效：包装过的集合仍然保有可变集合的开销，比如并发修改的检查、散列表的额外空间，等等。

**注意：所有Guava不可变集合的实现都不接受null值。因为谷歌内部调查代码发现，只有5%的情况需要在集合中允许null元素。如果要存储null值，请使用JDK的Collections.unmodifiable方法**

创建不可变集合的几个方法：

- **copyOf** 方法，如ImmutableSet.copyOf(set);

- **of**方法，如ImmutableSet.of(“a”, “b”, “c”)或 ImmutableMap.of(“a”, 1, “b”, 2);

- **Builder**工具，如

  ~~~java
  public static final ImmutableSet<Color> GOOGLE_COLORS =
          ImmutableSet.<Color>builder()
              .addAll(WEBSAFE_COLORS)
              .add(new Color(0, 191, 255))
              .build();
  ~~~

**copyOf** 是很智能和高效的，在特定会避免线性拷贝。下期有机会来分析下它的实现原理。

关联可变集合和不可变集合

| 可变集合接口                                           | 属于JDK还是Guava | 不可变版本                                             |
| ------------------------------------------------------------ | ---------------------- | ------------------------------------------------------------ |
| Collection                                                   | JDK                    | [`ImmutableCollection`](http://docs.guava-libraries.googlecode.com/git-history/release/javadoc/com/google/common/collect/ImmutableCollection.html) |
| List                                                         | JDK                    | [`ImmutableList`](http://docs.guava-libraries.googlecode.com/git-history/release/javadoc/com/google/common/collect/ImmutableList.html) |
| Set                                                          | JDK                    | [`ImmutableSet`](http://docs.guava-libraries.googlecode.com/git-history/release/javadoc/com/google/common/collect/ImmutableSet.html) |
| SortedSet/NavigableSet                                       | JDK                    | [`ImmutableSortedSet`](http://docs.guava-libraries.googlecode.com/git-history/release/javadoc/com/google/common/collect/ImmutableSortedSet.html) |
| Map                                                          | JDK                    | [`ImmutableMap`](http://docs.guava-libraries.googlecode.com/git-history/release/javadoc/com/google/common/collect/ImmutableMap.html) |
| SortedMap                                                    | JDK                    | [`ImmutableSortedMap`](http://docs.guava-libraries.googlecode.com/git-history/release/javadoc/com/google/common/collect/ImmutableSortedMap.html) |
| [Multiset](http://code.google.com/p/guava-libraries/wiki/NewCollectionTypesExplained#Multiset) | Guava                  | [`ImmutableMultiset`](http://docs.guava-libraries.googlecode.com/git-history/release/javadoc/com/google/common/collect/ImmutableMultiset.html) |
| SortedMultiset                                               | Guava                  | [`ImmutableSortedMultiset`](http://docs.guava-libraries.googlecode.com/git-history/release12/javadoc/com/google/common/collect/ImmutableSortedMultiset.html) |
| [Multimap](http://code.google.com/p/guava-libraries/wiki/NewCollectionTypesExplained#Multimap) | Guava                  | [`ImmutableMultimap`](http://docs.guava-libraries.googlecode.com/git-history/release/javadoc/com/google/common/collect/ImmutableMultimap.html) |
| ListMultimap                                                 | Guava                  | [`ImmutableListMultimap`](http://docs.guava-libraries.googlecode.com/git-history/release/javadoc/com/google/common/collect/ImmutableListMultimap.html) |
| SetMultimap                                                  | Guava                  | [`ImmutableSetMultimap`](http://docs.guava-libraries.googlecode.com/git-history/release/javadoc/com/google/common/collect/ImmutableSetMultimap.html) |
| [BiMap](http://code.google.com/p/guava-libraries/wiki/NewCollectionTypesExplained#BiMap) | Guava                  | [`ImmutableBiMap`](http://docs.guava-libraries.googlecode.com/git-history/release/javadoc/com/google/common/collect/ImmutableBiMap.html) |
| [ClassToInstanceMap](http://code.google.com/p/guava-libraries/wiki/NewCollectionTypesExplained#ClassToInstanceMap) | Guava                  | [`ImmutableClassToInstanceMap`](http://docs.guava-libraries.googlecode.com/git-history/release/javadoc/com/google/common/collect/ImmutableClassToInstanceMap.html) |
| [Table](http://code.google.com/p/guava-libraries/wiki/NewCollectionTypesExplained#Table) | Guava                  | [`ImmutableTable`](http://docs.guava-libraries.googlecode.com/git-history/release/javadoc/com/google/common/collect/ImmutableTable.html) |

### 2. Multiset

定义摘自维基百科：

> ”集合[set]概念的延伸，它的元素可以重复出现…与集合[set]相同而与元组[tuple]相反的是，Multiset元素的顺序是无关紧要的：Multiset {a, a, b}和{a, b, a}是相等的”

**Multiset**继承自JDK中的Collection接口，而不是Set接口，所以可以包含重复元素。可以从以下角度理解：

- 没有元素顺序限制的ArrayList<E>
- Map<E, Integer>，键为元素，值为计数

Multiset提供像无序的ArrayList的基本操作：

- add(E)添加单个给定元素
- iterator()返回一个迭代器，包含Multiset的所有元素（包括重复的元素）
- size()返回所有元素的总个数（包括重复的元素）

当把Multiset看作Map<E, Integer>时，它也提供了Map的查询操作：

- count(Object)返回给定元素的计数。
- entrySet()返回Set<Multiset.Entry<E>>，和Map的entrySet类似。
- elementSet()返回所有不重复元素的Set<E>，和Map的keySet()类似。

常用方法如下：

| 方法             | 描述                                                         |
| ---------------- | ------------------------------------------------------------ |
| count(E)         | 给定元素在Multiset中的计数                                   |
| elementSet()     | Multiset中不重复元素的集合，类型为Set<E>                     |
| entrySet()       | 和Map的entrySet类似，返回Set<Multiset.Entry<E>>，<br />其中包含的Entry支持getElement()和getCount()方法 |
| add(E, int)      | 增加给定元素在Multiset中的计数                               |
| remove(E, int)   | 减少给定元素在Multiset中的计数                               |
| setCount(E, int) | 设置给定元素在Multiset中的计数，不可以为负数                 |
| size()           | 返回集合元素的总个数（包括重复的元素）                       |

**应用**：统计一个词在文档中出现了多少次。

1. 传统的做法是这样的

   ~~~java
   Map<String, Integer> counts = new HashMap<String, Integer>();
   for (String word : words) {
       Integer count = counts.get(word);
       if (count == null) {
           counts.put(word, 1);
       } else {
           counts.put(word, count + 1);
       }
   }
   ~~~

2. 使用**Multiset**操作：

   ~~~java
   Multiset<String> multiset = HashMultiset.create();
   for (String word : words) {
       multiset.add(word);
   }
   int count = multiset.count("today");
   ~~~

### 3. Multimap

通俗来讲，**Multimap** 是**一键对多值**的**HashMap**，类似于 **Map<K, List<V>>** 的数据结构。

~~~java
@Test
public void test2() {
  Multimap<String, String> multimap = ArrayListMultimap.create();
  multimap.put("name", "Jack");
  multimap.put("name", "Jack");
  multimap.put("name", "Tom");
  multimap.put("age", "10");
  multimap.put("age", "12");
  System.out.println(multimap);
  System.out.println(multimap.get("name").size());
}
~~~

输出：

~~~
{name=[Jack, Jack, Tom], age=[10, 12]}
3
~~~

常用操作如下：

| **方法签名**               | **描述**                                                     | **等价于**                                                   |
| -------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| put(K, V)                  | 添加键到单个值的映射                                         | multimap.get(key).add(value)                                 |
| putAll(K, Iterable)        | 依次添加键到多个值的映射                                     | Iterables.addAll(multimap.get(key), values)                  |
| remove(K, V)               | 移除键到值的映射；如果有这样的键值并成功移除，返回true。     | multimap.get(key).remove(value)                              |
| removeAll(K)               | 清除键对应的所有值，返回的集合包含所有之前映射到K的值，但修改这个集合就不会影响Multimap了。 | multimap.get(key).clear()                                    |
| replaceValues(K, Iterable) | 清除键对应的所有值，并重新把key关联到Iterable中的每个元素。返回的集合包含所有之前映射到K的值。 | multimap.get(key).clear(); Iterables.addAll(multimap.get(key), values) |

**主要操作**：

- asMap：为Multimap<K, V>提供Map<K,Collection<V>>形式的视图
- entries：返回所有”键-单个值映射”，包括重复键。Collection<Map.Entry<K, V>>类型
- keySet：返回所有不同的键，Set<K>类型
- keys：用Multiset表示Multimap中的所有键，每个键重复出现的次数等于它映射的值的个数。可以从这个Multiset中移除元素，但不能做添加操作；移除操作会反映到底层的Multimap
- values：用一个”扁平”的Collection<V>包含Multimap中的所有值，包括重复键

### 4. BiMap

一般的**Map**只提供”**键-值**“的映射，而**BiMap**则同时提供了”**键-值**“和”**值-键**“的映射关系。常用方法：

- put(K key, V value)：添加新的键、值。如果值和已有键重复，会抛出异常

-  forcePut(K key, V value)：添加新的键、值。如果值和已有键重复，会覆盖原来的键、值

-  inverse()：得到**”值-键“**的**BitMap**对象

  ~~~java
  @Test
  public void test4(){
    BiMap<String,String> biMap= HashBiMap.create();
    biMap.put("sina","sina.com");
    biMap.put("qq","qq.com");
    biMap.put("sina","sina.cn"); //会覆盖原来的value
    System.out.println(biMap.inverse().get("qq.com"));
  
    //biMap.put("tecent","qq.com"); //抛出异常
    biMap.forcePut("tecent","qq.com"); //强制替换key
    System.out.println(biMap.get("qq")); //通过value找key
    System.out.println(biMap.inverse().get("qq.com"));
    System.out.println(biMap.inverse().get("sina.com"));
    System.out.println(biMap.inverse().inverse()==biMap);
  }
  ~~~

  输出：

  ~~~
  qq
  null
  tecent
  null
  true
  ~~~

### 5. Table

**Table**类似多个索引的表，类似 **Map<R, Map<C, V>>** 的数据结构。它有两个支持所有类型的键：”**行**”和”**列**”，可以通过以下方法获取多个视图：

- rowMap()：用Map<R, Map<C, V>>表现Table<R, C, V>。同样的， **rowKeySet()**返回”行”的集合Set<R>。
- row(r)：用Map<C, V>返回给定”行”的所有列，对这个map进行的写操作也将写入Table中。
- cellSet()：用元素类型为Table.Cell的Set表现Table<R, C, V>。Cell类似于Map.Entry，但它是用**行和列**两个键区分的。
