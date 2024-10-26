---
title: "MyBatis一、二级缓存和自定义缓存"
date: 2017-10-18T14:29:03+08:00
Author: Luky116
tags: ["MyBatis缓存"]
categories: ["MyBatis"]
---

## 1、一级缓存

	MyBatis **默认开启了一级缓存**，一级缓存是在SqlSession 层面进行缓存的。即，同一个SqlSession ，多次调用同一个Mapper和同一个方法的同一个参数，只会进行一次数据库查询，然后把数据缓存到缓冲中，以后直接先从缓存中取出数据，不会直接去查数据库。
	
	但是不同的SqlSession对象，因为不用的SqlSession都是相互隔离的，所以相同的Mapper、参数和方法，他还是会再次发送到SQL到数据库去执行，返回结果。

~~~java
public static void main(String[] args) {
		// 自定义的单例SqlSessionFactory模式
        SqlSessionFactory factory = SqlSessionFactoryUtil.openSqlSession();

        // 获得SqlSession对象
        SqlSession sqlSession = factory.openSession();
        // 获得dao实体
        UserMapper userMapper = sqlSession.getMapper(UserMapper.class);
        // 进行两次相同的查询操作
        userMapper.selectByPrimaryKey(1);
        userMapper.selectByPrimaryKey(1);
  		// 注意，当我们使用二级缓存时候，sqlSession需要使用commit时候才会生效
        sqlSession.commit();

        System.out.println("\n\n=============================================================");
        // 获得一个新的SqlSession 对象
        SqlSession sqlSession1 = factory.openSession();
        // 进行相同的查询操作
        sqlSession1.getMapper(UserMapper.class).selectByPrimaryKey(1);
  		// 注意，当我们使用二级缓存时候，sqlSession需要使用commit时候才会生效
        sqlSession.commit();
    }
~~~

日志输出

~~~
DEBUG [main] - ooo Using Connection [com.mysql.jdbc.JDBC4Connection@77caeb3e]
DEBUG [main] - ==>  Preparing: select user_ID, login_name,user_name, user_code, user_type, user_active, organization_ID,user_position,password from user where user_ID = ? 
DEBUG [main] - ==> Parameters: 1(Integer)
TRACE [main] - <==    Columns: user_ID, login_name, user_name, user_code, user_type, user_active, organization_ID, user_position, password
TRACE [main] - <==        Row: 1, ASH-001, 小明, JIKF-001, ADMIN, 1, 0, 销售员, 1212121212121
DEBUG [main] - <==      Total: 1


=============================================================
DEBUG [main] - ooo Using Connection [com.mysql.jdbc.JDBC4Connection@553f17c]
DEBUG [main] - ==>  Preparing: select user_ID, login_name,user_name, user_code, user_type, user_active, organization_ID,user_position,password from user where user_ID = ? 
DEBUG [main] - ==> Parameters: 1(Integer)
TRACE [main] - <==    Columns: user_ID, login_name, user_name, user_code, user_type, user_active, organization_ID, user_position, password
TRACE [main] - <==         Row: 1, ASH-001, 小明, JIKF-001, ADMIN, 1, 0, 销售员, 1212121212121
DEBUG [main] - <==      Total: 1
~~~

	可以发现，第一次的两个相同操作，只执行了一次数据库。后来的那个操作又进行了数据库查询。

## 2、二级缓存

	为了克服这个问题，需要开启二级缓存，是的缓存zaiSqlSessionFactory层面给各个SqlSession 对象共享。默认二级缓存是不开启的，需要手动进行配置。

~~~XML
<cache/>
~~~

	如果这样配置的话，很多其他的配置就会被默认进行，如：

- 映射文件所有的select 语句会被缓存
- 映射文件的所有的insert、update和delete语句会刷新缓存
- 缓存会使用默认的Least Recently Used（LRU，最近最少使用原则）的算法来回收缓存空间
- 根据时间表，比如No Flush Interval，（CNFI，没有刷新间隔），缓存不会以任何时间顺序来刷新
- 缓存会存储列表集合或对象（无论查询方法返回什么）的1024个引用
- 缓存会被视为是read/write（可读/可写）的缓存，意味着对象检索不是共享的，而且可以很安全的被调用者修改，不干扰其他调用者或县城所作的潜在修改

添加后日志打印如下，可以发现所有过程只使用了一次数据库查询

~~~
EBUG [main] - ooo Using Connection [com.mysql.jdbc.JDBC4Connection@5622fdf]
DEBUG [main] - ==>  Preparing: select user_ID, login_name,user_name, user_code, user_type, user_active, organization_ID,user_position,password from user where user_ID = ? 
DEBUG [main] - ==> Parameters: 1(Integer)
TRACE [main] - <==    Columns: user_ID, login_name, user_name, user_code, user_type, user_active, organization_ID, user_position, password
TRACE [main] - <==        Row: 1, AS-01, 小明, HJ-009, ADMIN, 1, 0, 销售员, dasfasdfasdfsdf
DEBUG [main] - <==      Total: 1


=============================================================
~~~

可以在开启二级缓存时候，手动配置一些属性

~~~XML
<cache eviction="LRU" flushInterval="100000" size="1024" readOnly="true"/>
~~~

各个属性意义如下：

- eviction：缓存回收策略
       - LRU：最少使用原则，移除最长时间不使用的对象
       - FIFO：先进先出原则，按照对象进入缓存顺序进行回收
       - SOFT：软引用，移除基于垃圾回收器状态和软引用规则的对象
       - WEAK：弱引用，更积极的移除移除基于垃圾回收器状态和弱引用规则的对象
- flushInterval：刷新时间间隔，单位为毫秒，这里配置的100毫秒。如果不配置，那么只有在进行数据库修改操作才会被动刷新缓存区
- size：引用额数目，代表缓存最多可以存储的对象个数
- readOnly：是否只读，如果为true，则所有相同的sql语句返回的是同一个对象（有助于提高性能，但并发操作同一条数据时，可能不安全），如果设置为false，则相同的sql，后面访问的是cache的clone副本。

可以在Mapper的具体方法下设置对二级缓存的访问意愿：

- useCache配置

  	如果一条语句每次都需要最新的数据，就意味着每次都需要从数据库中查询数据，可以把这个属性设置为false，如：

~~~XML
  <select id="selectAll" resultMap="BaseResultMap" useCache="false">
~~~

- 刷新缓存（就是清空缓存）

  	二级缓存默认会在insert、update、delete操作后刷新缓存，可以手动配置不更新缓存，如下：

~~~XML
  <update id="updateById" parameterType="User" flushCache="false" />
~~~


## 3、自定义缓存

	自定义缓存对象，该对象必须实现 org.apache.ibatis.cache.Cache  接口，如下：

~~~java
import org.apache.ibatis.cache.Cache;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

/**
 * Created by Luky on 2017/10/14.
 */
public class BatisCache implements Cache {
    private ReadWriteLock lock = new ReentrantReadWriteLock();
    private ConcurrentHashMap<Object,Object> cache = new ConcurrentHashMap<Object, Object>();
    private String id;

    public  BatisCache(){
        System.out.println("初始化-1！");
    }

  //必须有该构造函数
    public BatisCache(String id){
        System.out.println("初始化-2！");
        this.id = id;
    }

    // 获取缓存编号
    public String getId() {
        System.out.println("得到ID：" + id);
        return id;
    }

    //获取缓存对象的大小
    public int getSize() {
        System.out.println("获取缓存大小！");
        return 0;
    }
    // 保存key值缓存对象
    public void putObject(Object key, Object value) {
        System.out.println("往缓存中添加元素：key=" + key+",value=" + value);
        cache.put(key,value);
    }

    //通过KEY
    public Object getObject(Object key) {
        System.out.println("通过kEY获取值：" + key);
        System.out.println("OVER");
        System.out.println("=======================================================");
        System.out.println("值为：" + cache.get(key));
        System.out.println("=====================OVER==============================");
        return cache.get(key);
    }

    // 通过key删除缓存对象
    public Object removeObject(Object key) {
        System.out.println("移除缓存对象：" + key);
        return null;
    }

    // 清空缓存
    public void clear() {
        System.out.println("清除缓存！");
        cache.clear();
    }

    // 获取缓存的读写锁
    public ReadWriteLock getReadWriteLock() {
        System.out.println("获取锁对象！！！");
        return lock;
    }
}
~~~

	在Mapper文件里配置使用该自定义的缓存对象，如：

~~~XML
<cache type="com.sanyue.utils.BatisCache"/>
~~~

	测试如下：

~~~java
 public static void main(String[] args) {

        SqlSessionFactory factory = SqlSessionFactoryUtil.openSqlSession();

        // 获得SqlSession对象
        SqlSession sqlSession = factory.openSession();
        // 获得dao实体
        UserMapper userMapper = sqlSession.getMapper(UserMapper.class);
        // 进行两次相同的查询操作
        userMapper.selectByPrimaryKey(1);
        userMapper.selectByPrimaryKey(1);
        // 注意，当我们使用二级缓存时候，sqlSession需要使用commit时候才会生效
        sqlSession.commit();

        System.out.println("\n\n=============================================================");
        // 获得一个新的SqlSession 对象
        SqlSession sqlSession1 = factory.openSession();
        // 进行相同的查询操作
        sqlSession1.getMapper(UserMapper.class).selectByPrimaryKey(1);
        sqlSession1.commit();
    }
~~~

	日志输出如下：

~~~
初始化-2！
得到ID：com.sanyue.dao.UserMapper
获取锁对象！！！
通过kEY获取值：151355725:1423317450:com.sanyue.dao.UserMapper.selectByPrimaryKey:0:2147483647:
        select
        
        user_ID, login_name,user_name, user_code, user_type, user_active, organization_ID,user_position,password
    
        from user
        where user_ID = ?
    :1
OVER
=======================================================
值为：null
=====================OVER==============================
获取锁对象！！！
获取锁对象！！！
通过kEY获取值：151355725:1423317450:com.sanyue.dao.UserMapper.selectByPrimaryKey:0:2147483647:
        select
        
        user_ID, login_name,user_name, user_code, user_type, user_active, organization_ID,user_position,password
    
        from user
        where user_ID = ?
    :1
OVER
=======================================================
值为：null
=====================OVER==============================
获取锁对象！！！
获取锁对象！！！
往缓存中添加元素：key=151355725:1423317450:com.sanyue.dao.UserMapper.selectByPrimaryKey:0:2147483647:
        select
        
        user_ID, login_name,user_name, user_code, user_type, user_active, organization_ID,user_position,password
    
        from user
        where user_ID = ?
    :1,value=[User{userId=1, loginName='AS-01', password='12121212121', userName='小明', userCode='JSD-009', userType='ADMIN', userActive=true, userPosition='销售员'}]
获取锁对象！！！


=============================================================
获取锁对象！！！
通过kEY获取值：151355725:1423317450:com.sanyue.dao.UserMapper.selectByPrimaryKey:0:2147483647:
        select
        
        user_ID, login_name,user_name, user_code, user_type, user_active, organization_ID,user_position,password
    
        from user
        where user_ID = ?
    :1
OVER
=======================================================
值为：[User{userId=1, loginName='AS-01', password='12121212121', userName='小明', userCode='JSD-009', userType='ADMIN', userActive=true, userPosition='销售员'}]
=====================OVER==============================
获取锁对象！！！
~~~

	可以看出，每次查询数据库前，MyBatis都会先在缓存中查找是否有该缓存对象。只有当调用了commit() 方法，MyBatis才会往缓存中写入数据，数据记录的键为 `数字编号+Mapper名+方法名+SQL语句+参数` 格式，值为返回的对象值。
