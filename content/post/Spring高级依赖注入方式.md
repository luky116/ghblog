---
title: "Spring高级依赖注入方式"
date: 2017-10-11T14:29:03+08:00
Author: Luky116
tags: ["依赖注入"]
categories: ["Spring"]
---



## 1、处理自动装配的歧义性

### 1.1 标记首选的bean

	使用@Primary 来说明一个bean是首选的。

~~~java
@Component
@Primary
public class GuoRongCD implements CompactDisc {}
~~~

或是

~~~java
@Bean
@Primary
public MediaPlayer getAnotherCDplay(CompactDisc aa){
  CDPlayer k = new CDPlayer();
  k.setCompactDisc(aa);
  return k;
}
~~~

或是

~~~XML
<bean id="glCD" class="com.di.book.GuoRongCD" primary="true"/>
~~~

	但是，一个类型的bean只能有一个首选标志，如果多个，就失去意义了。

### 1.2 限定自动装配的bean

	如果被注入的bean类型不是唯一的，需要设置限定符，来确定哪个bean是被需要的。@Qualifier注解是使用限定符的主要方式。

~~~java
@Autowired
@Qualifier("guoRongCD")
public void setCompactDisc(CompactDisc compactDisc) {
  this.compactDisc = compactDisc;
}
~~~

> 		@Qualifier 设置的参数就是想要注入的bean的ID。所有使用@Component 注解声明的bean，默认的ID是首字母变小写的类名。
> 		
> 		更精确的说，@Qualifier("guoRongCD") 所要引用的bean是具有String类型的“guoRongCD”作为限定符。如果没有指定限定符，bea一般会有一个默认的限定符，这个限定符和bean 的ID相同。

- 给bean指定限定符

~~~
  @Component
  @Qualifier("kkd")
  public class GuoRongCD implements CompactDisc {}
~~~

  或是

~~~java
  @Bean
  @Qualifier("kkd")
  public CompactDisc getCompactDisc(){
  return new GuoRongCD();
  }
~~~

## 2、作用域

。。。。。。

## 3、运行时值注入

	为了避免硬编码，可以是程序在运行时候再给属性复制。有如下两种方式：

- 属性占位符
- Spring 表达式语言

### 3.1 注入外部值

~~~java
@Configuration
@PropertySource("classpath:test.properties")//引入配置文件
public class ExpressiveConfig {
	@Autowired
	Environment env;//自动检索属性
	@Bean
	public BlankDisk disc(){
		return new BlankDisk(
          //寻找键值，进行注入
				env.getProperty("disc.title"),
				env.getProperty("disc.artist"));
	}
}
~~~

test.properties

~~~java
disc.title = vae
disc.artist = vae Son
~~~

### 3.2 深入研究

关于getProperty()的重载形式：

~~~java
//只有key
String getProperty(String key)
//含有默认值，如果找不到改善属性值，就会适应默认值
String getProperty(String key, String defaultValue)
//可以类型转换，比如字符串转整型，
//getProperty("port", Integer.class)
<T> T getProperty(String key, Class<T> targetType);
//带有默认值
<T> T getProperty(String key, Class<T> targetType, T defaultValue);
~~~

	当使用getProperty()时候，如果是空值，结果适null，不会包异常。如果希望该结果不存在的时候抛异常，就可以使用 getRequiredProperty() 方法，所有使用方法和前者一致，若是值不存在，会抛出异常。

### 3.3 属性占位符

- XML中，可以使用“${}”来占位。

~~~XML
  <bean id="dataSource"
  			class="org.springframework.jdbc.datasource.DriverManagerDataSource">
      <property name="url" value="${mysql.url}"/>
      <property name="username" value="${mysql.username}"/>
      <property name="driverClassName" value="${mysql.driverClassName}"/>
      <property name="password" value="${mysql.password}"/>	
  	</bean>
~~~


- 在JavaConfig中，使用@Value来占位

~~~java
  @Bean
  public BlankDisk disc(@Value("${disc.title}")String title,
                        @Value("${disc.artist}")String artist)	{
    return new BlankDisk(title,artist);
  }
~~~

  但是，为了使用占位符，需要含有PropertySourcesPlaceholderConfigurer 类型的bean：

~~~java
  @Bean
  public static PropertySourcesPlaceholderConfigurer placeholderConfigurer(){
    return new PropertySourcesPlaceholderConfigurer();
  }
~~~

  在XML中，需要使用命名空间

~~~XML
  <context:property-placeholder/>
~~~

  这个命名空间会给你自动创建这个bean。

