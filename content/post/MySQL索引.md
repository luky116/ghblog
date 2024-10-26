---
title: "MySQL索引"
date: 2017-08-30T14:43:00+08:00
Author: Luky116
tags: ["MySQL索引"]
categories: ["MySQL"]
---

**1、为什么会有索引**

当数据保存在磁盘介质上时，它是作为数据库存放的，每条数据是作为一个整体存储的。磁盘存放数据的数据结构类似于链表，即，每个节点除了包含本身数据，还包含一个指向下个节点的指针。相关数据逻辑相连，物理地址可以任意。

那么问题来，如果一个表有10W个数据，如果没有索引，那么当你按某个条件查找数据时候，系统只能遍历数据，直到找到你需要的数据。

如果你把这个字段做成了索引，系统会把这个索引字段按照一定的规则制成一个单独的数据结构，当你需要按照这个字段查找时候，系统会在这个索引数据结构二分查找，把原来复杂度为o(N)降为o(log2N)，大大提高查询速度。

**2、索引**

**2.1 单列索引**

**2.1.1 普通索引**

普通索引是最基本的索引。由关键字KEY或INDEX定义的索引，加快对数据的访问速度。对于那些经常的查询条件（WHERE column=）或排序条件（ORDER BY column）的字段，应该创建索引。

CREATE INDEX 索引名 ON 表名(字段名);

 

ALTER TABLE 表名 ADD KEY 索引名(字段名);

ALTER TABLE 表名 ADD INDEX 索引名(字段名);

**2.1.2 唯一索引**

普通索引允许在数据列中包含重复的值，比如，名字，这个项可以重复。对于一些不能重复的值，比如，个人的身份证号，应该设置为UNIQUE INDEX 把他设置为唯一索引。

ALTER TABLE people ADD UNIQUE INDEX 索引名(字段名);

**2.1.3 主索引**

主键会被默认添加一个索引，这就是“主索引”。主索引与唯一索引的唯一区别是：前者在定义时使用的关键字是PRIMARY而不是UNIQUE。主键索引一定是唯一性索引，唯一性索引不一定是主键索引。

 

ALTER TABLE people ADD PRIMARY KEY 索引名(字段名);

**2.2 组合索引**

包含多个字段的索引。

CREATE INDEX 索引名 ON 表名(字段名,字段名);

例如：

　　CREATE INDEX all_index ON people(last_name,first_name,gender);

 ![img](http://images2017.cnblogs.com/blog/834666/201708/834666-20170830134325515-1269681225.png)

 

在使用查询的时候遵循MySQL组合索引的“最左前缀”，什么是最左前缀：where 时的条件要按照建立索引时候字段的排序方式。比如，INDEX（A,B,C）可以被当做A或（A,B）的索引来使用，但不能当做B,C或（B,C）的索引来使用。

Where A= ‘xxx’ and B like = ‘aa%’ and C=’sss’ 改查询只会使用索引中的前两列,因为like是范围查询。范围查询不算在索引内，因为索引使用 hash值来计算，模糊条件无法计算得到hash值。

**2.3 全文索引**

文本字段（text、blog）建立索引时候需要指明索引的长度。如果对文本字段进行模糊查询，即 where column like '%xx%'，因为是模糊查询，所以索引会失效。

可以设置全文索引：

ALTER TABLE 表名ADD FULLTEXT(字段名1, 字段名2)

有了全文索引，就可以利用索引来进行关键字查询了。

ELECT * FROM tablename WHERE MATCH(column1, column2) AGAINST(‘xxx′, ‘sss′, ‘ddd′) 

查询出column1 和 column2 中包含这些关键字的记录。

