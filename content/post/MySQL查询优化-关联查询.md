---
title: "MySQL查询优化 关联查询"
date: 2019-08-10T14:04:09+08:00
Author: Luky116
tags: ["MySQL优化"]
categories: ["MySQL"]
---

## 1. 关联查询执行流程

**MySQL**执行关联查询的策略很简单，他会从一个表中循环取出单条数据，然后用该条数据到下一个表中寻找匹配的行，然后回溯到上一个表，到所有的数据匹配完成为止。因此也被称为“**嵌套循环关联**”。

来看下面这个SQL：

~~~mysql
select tb1.col1, tb2,col2
  from tb1 inner join tb2 using(col3)
  where tb1.col1 in (5,6)
~~~

他的执行顺序为（伪代码）：

~~~c
List outerDataList = "select * from tb1 where col1 in (5,6)"
  for(outerData in outerDataList){
    List innerDataList = "select * from tb2 where col3 = outerData.col3"
      for(innerData : innerDataList){
        output(outterData,innerData)
      }
  }
~~~

MySQL认为**所有的查询都是一次关联查询**，所以如果查询一个表，上述过程也适合，不过只需要完成上面外层的基本操作。

再来看看`left outter join`查询的过程，SQL如下：

~~~MySQL
select tb1.col1, tb2,col2
from tb1 left outer join tb2 using(col3)
where tb1.col1 in (5,6)
~~~

伪代码如下：

~~~java
List outerDataList = "select * from tb1 where col1 in (5,6)"
  for(outerData in outerDataList){
    List innerDataList = "select * from tb2 where col3 = outerData.col3"
      if(innerDataList != null){
        for(innerData : innerDataList){
          output(outterData,innerData)
        }
      }else{
        // inner表无对应数据，以outter数据为准
        output(outterData,null)
      }
  }
~~~

但是这种遍历的查询方式不能满足所有的联合查询，比如**“全外连接”查询（full outer join）**不能使用该方法来实现，这可能是MySQL不支持全外接查询的原因 ~~~

## 2. 优化

MySQL会将查询命令生成一颗指令树，比如四表联合查询的指令树如下：
![](https://img2018.cnblogs.com/blog/834666/201908/834666-20190810181736328-1648615455.png)



​																																																																																																																																																																																																																																																																																																																																																																																																																																																																						

MySQL在生成指令树之前会先对SQL语句的执行效率进行评估，然后选择他认为效率最高的关联顺序执行。对于如下SQL：

~~~mysql
EXPLAIN SELECT
	actor.NAME,
	film.title 
FROM
	actor actor
	INNER JOIN film_actor USING ( actor_id )
	INNER JOIN film USING ( film_id )
~~~

![](https://img2018.cnblogs.com/blog/834666/201908/834666-20190810181723947-241503518.png)



从执行计划可以看出，MySQL选择将film作为第一个关联表，拿到数据后再依次扫描film_actor、actor表取数据。MySQL的选择策略是，尽量让查询执行更少的**嵌套循环和回溯操作**，因此，他会尽量将外层查询的数据量更少。因为film表只有4条记录，actor表有6条记录，因此他认为选择将film作为第一个表开始查询有更高的执行效率。

但是MySQL的优化策略会比这复杂的多，MySQL会计算所有执行顺序的代价，然后选择他认为的最佳执行计划。但是，如果联合查询的表比较多，他不一定能穷举所有的执行情况选择最佳的执行策略，所以这种默认的优化方式却不一定总是最佳的。还是以上条SQL为例子，假设在film表的film_id字段上建立了索引，那么即使film上的字段少于actor，可能使用actor表作为第一个表进行查询，效率会更高（里层嵌套查询film表数据时可以使用索引）。如果你认为有更佳的执行顺序，可以使用`STRAIGHT_JOIN`关键字强行执行查询顺序：

~~~mysql
EXPLAIN SELECT
	actor.NAME,
	film.title 
FROM
	actor actor
	STRAIGHT_JOIN film_actor USING ( actor_id )
	STRAIGHT_JOIN film USING ( film_id )
~~~

**注意：绝大多数时候，MySQL做出的判断都比人类要准确，绝大多数时候，不推荐强制执行顺序。**
