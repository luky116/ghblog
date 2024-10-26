---
title: "Spring依赖注入的方式"
date: 2017-10-11T14:29:03+08:00
Author: Luky116
tags: ["依赖注入"]
categories: ["Spring"]
---

## 1、依赖注入（DI） 的重要性

	如果直接在代码里面实例化一个对象，会使代码的耦合度大，使代码难以测试，难以复用，难以理解。通过DI，对象的依赖关系将由系统中负责协调各对象的第三方组件在创建对象的时候进行设定。
	
	在DI中，面接口编程，而不是面向实例对象编程。所以，只要是实现了该接口的对象，都可以被传进来，进行注入，使代码的耦合性降低。

## 2、装配

> 创建应用组件之间的协作关系的行为通常称为装配（wiring）。

## 3、装配方式

1. 在XML中显示的进行
2. 在Java中进行显示的配置（JavaConfig）
3. 隐式的bean发现机制和自动装配

   建议尽可能使用自动配置的机制来装配bean，显示的配置越少越好。尽量使用第二 中转配方式。

## 4、自动化装配bean

	Spring从两方面实现自动化装配。

1. 组件扫描（component scanning）：Spring会自动发现应用上下文中所创建的bean。
2. 自动装配（autowiring）：Spring自动满足bean之间的依赖。

### 4.1 创建可被发现的bean

- @Component：为该类创建bean

- @Named：bean注解，和上一样，但是不常用

- @CompontScan ：在Java中启动扫描，默认会扫描与配置类相同的包

- 在xml文件中 此注解，启动组件扫描


~~~XML
  <context:component-scan base-package="com.di"/>
~~~



- applicationContext.xml

~~~XML
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"	 xmlns:context="http://www.springframework.org/schema/context"
	xsi:schemaLocation="http://www.springframework.org/schema/beans 
		http://www.springframework.org/schema/beans/spring-beans.xsd
		http://www.springframework.org/schema/context 
		http://www.springframework.org/schema/context/spring-context.xsd">
	<context:component-scan base-package="com.di" />
</beans>
~~~

注解：

~~~xml
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"	//一定要存在
xmlns:context="http://www.springframework.org/schema/context"	//启动扫描注解一定需要的
~~~

### 4.2 通过SpringTest单元测试

~~~java
@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(classes=Car.class)
public class RunBySpringTest {
	@Autowired
	private Car car;
	@Test
	public void test_2(){
		car.show();
	}
}
~~~

- 添加JUnit  4.11版本的包，还有spring-test 依赖包。
- JUnit 最好用这个版本的依赖包，其他的版本不能保证不出问题。
- SpringJUnit4ClassRunner：可以在测试开始的时候创建Spring的应用上下文。
- @ContextConfiguration 告诉它在Car中加载配置，由于Car中使用了@Component注解。

### 4.3 设置组件扫描基础包 - @Component

	当我们没有为@Component 设置任何属性时候，他会以配置类所在的基础包（base package）来扫描组件。如果我们想要扫描其他的包，有如下用法：

- 扫描一个包

~~~java
@Configurable
@ComponentScan("com.di")
public class ClassCongfig {}
~~~

- 扫描多个包

~~~java
@Configurable
@ComponentScan(basePackages={"com.di","com.sanyue"})
public class ClassCongfig {}
~~~

- 扫描该类所在的包，将会扫描该类所在的包，所以可以在包中设置特定的空标记接口

~~~java
@Configurable
@ComponentScan(basePackageClasses={Car.class,Cat.class})
public class ClassCongfig {}
~~~

### 4.4 通过为bean添加注解实现自动装配

	当一个bean要依赖另一个bean才能正常工作时候，就需要将bean和他们的依赖装配在一起。常用依赖注入注解如下：

- @Autowired

  - 用于构造器上

~~~java
  @Component
  public class CDPlayer implements MediaPlayer {
  	private CompactDisc compactDisc;
  	@Autowired
  	public CDPlayer(CompactDisc compactDisc){
  		this.compactDisc = compactDisc;
  	}
  	@Override
  	public void play() {
  		// TODO Auto-generated method stub
  		compactDisc.play();
  	}
  }
~~~

  - 用与Setter()

~~~java
  @Autowired
  public void setCompactDisc(CompactDisc compactDisc) {
    this.compactDisc = compactDisc;
  }
~~~

  > 		好吧，其实Setter方法并无特别之处，@Autowired 可以用于任何方法之上，用于依赖注入。
  > 		
  > 		如果有多个bean满足依赖关系的话，Spring将会抛出异常。 这是Spring特有的注解。比如，Java依赖注入规范为我们提供了@Inject注解，可以和@Autowired交替使用。

## 5、通过Java代码装配bean

### 5.1 创建配置类

	创建JavaConfig配置类的关键是为其添加 @Configuration 注释, @Configuration 说明这个类是配置类，该类应该包含在Spring 应用上下文中创建bean得到细节。

### 5.2 声明简单的bean

	要在JavaConfig中创建Bean，需要编写一个方法，加上@Bean注解，说明这个方法会返回这个类型的实例。

~~~java
@Configurable
public class CDConfig {
	@Bean
	public MediaPlayer CDplay(){
		return new CDPlayer();
	}
}
~~~

	如上，默认情况下将创建的bean的ID和方法名字相同，如上，bean的ID将会是CDplay。也可以认为指定的name属性指定一个ID。

~~~java
@Bean(name="getCDplay")
public MediaPlayer getCDplay(){
  return new CDPlayer();
}
~~~

### 5.3 借助JavaConfig 实现注入

~~~java
@Configurable
public class CDConfig {	
	@Bean(name="getCDplay")
	public MediaPlayer getCDplay(){
		return new CDPlayer(getCompactDisc());
	}	
	@Bean
	public CompactDisc getCompactDisc(){
		return new GuoRongCD();
	}
}
~~~

	如上，可以通过方法，来为另一个Bean注入。当getCompactDisc()被调用时，因为他被加上了@Bean注解，Spring将会拦截所有对他的调用，并确保返回该方法所创建的bean，而不是每次都对其实际调用。

~~~java
@Bean()
public MediaPlayer getAnotherCDplay(CompactDisc aa){
  return new CDPlayer(aa);
}
~~~

	getAnotherCDplay() 创建MediaPlayer bean时候，会自动装配CompactDisc 到配置方法中，这也是注入bean的最佳方式。

~~~java
@Bean()
public MediaPlayer getAnotherCDplay(CompactDisc aa){
  CDPlayer k = new CDPlayer();
  k.setCompactDisc(aa);
  return k;
}
~~~

	或是通过setter方法进行DI，都可以哒！！！！

## 6、通过XML装配bean

### 	6.1 创建简单的bean

~~~xml
<bean class="com.di.Car" id="car"/>
~~~

	id声明了该bean的名字，默认名字是clss名加上#加上数字，如，“com.di.Car#0”，类以此推。当Spring发现这个bean时候，就会调用该类的【默认构造器】进行初始化。若是该类无默认构造器，将无法进行编译。

### 6.2 借助构造器注入初始化bean

	用构造器注入有两种基本的可供方案：

- < constructor-arg >
- 使用Spring3.0 所引入的c- 命名空间

  前者的长度会更大，导致XML不好阅读。前者的功能更全面。后者比较简洁，推荐。

#### 构造器注入bean引用

~~~XML
<bean id="cdPlayer" class="com.di.book.CDPlayer">
	<constructor-arg ref="glCD"/>
</bean>
<bean id="glCD" class="com.di.book.GuoRongCD"></bean>
~~~

	<constructor-arg>将会告诉Spring 要把一个ID为glCD的bean引用传递到该构造器中。

- 关于c-命名空间

~~~XML
  <?xml version="1.0" encoding="UTF-8"?>
  <beans xmlns="http://www.springframework.org/schema/beans"
  	xmlns:c="http://www.springframework.org/schema/c"	//添加标记
  	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
  	.......
  <bean id="cdPlayer" class="com.di.book.CDPlayer"
  		c:compactDisc-ref="glCD"/>
  <bean id="glCD" class="com.di.book.GuoRongCD"/>
~~~

  	这里使用了c-命名空间。c: 是c-命名空间的前缀，compactDisc表示构造器参数的名字，ref表示接了下来是一个引用，而不是一个字符串。

  - 使用参数位置来注入

~~~XML
  <bean id="cdPlayer" class="com.di.book.CDPlayer"
  		c:_0-ref="glCD"/>
~~~

  _0表示构造函数第一个参数。

  - 如果只有一个参数，也可以这样写

~~~XML
  <bean id="cdPlayer" class="com.di.book.CDPlayer"
  		c:_-ref="glCD"/>
~~~


#### 将字面量注入到构造器中

- 使用<constructor-arg>进行注入

~~~java
public BlankDisk(String title,String artist){
    this.title = title;
    this.artist = artist;
}
~~~

~~~XML
<bean id="cdPlayer" class="com.di.book.BlankDisk">
    <constructor-arg value="《我是许嵩》"/>
    <constructor-arg value="许嵩-VAE"/>
</bean>
~~~

	value表示该参数是字面量，而不是ref的引用。

- 使用c-命名空间进行

~~~XML
  <bean id="cdPlayer" class="com.di.book.BlankDisk"
  		c:_0="《我是许嵩》"
  		c:_1="许嵩-VAE"	/>
~~~



	或是

~~~XML
<bean id="cdPlayer" class="com.di.book.BlankDisk"
		c:_title="《我是许嵩》"
		c:_artist="许嵩-VAE"/>
~~~

#### 装配集合

~~~java
public BlankDisk(String title,String artist,List<String> songs){
		this.title = title;
		this.artist = artist;
		this.songs = songs;
	}
~~~

~~~XML
<bean id="cdPlayer" class="com.di.book.BlankDisk">
    <constructor-arg value="《我是许嵩》" />
    <constructor-arg value="许嵩-VAE" />
    <constructor-arg>
      <list>
        <value>河山大好</value>
        <value>有何不可</value>
        <ref bean=""></ref>
      </list>
    </constructor-arg>
</bean>
~~~

	value表示字面量，ref表示bean的引用。list对应于java.utilList，同理，set等等都可以使用。

### 6.3 设置属性（非构造器注入）

~~~XML
<bean id="cdPlayer" class="com.di.book.CDPlayer">
	<property name="compactDisc" ref="glCD" />
</bean>
<bean id="glCD" class="com.di.book.GuoRongCD"></bean>
~~~

	<property> 元素为属性的setter方法提供注入方法，ref为bean引用，value为字面量，前提是，该属性含有setter方法。	
	
	Spring为</constructor-arg>提供了等价的c-命名空间作为替代方案，也为<property>提供了等价的p-命名空间。但是，这个也需要在XML中实现声明。

~~~XML
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:p="http://www.springframework.org/schema/p">
	<bean id="cdPlayer" 
		  class="com.di.book.CDPlayer"
		  p:compactDisc-ref="glCD"/>
~~~

	如上，添加P命名空间的声明，p:表示P命名空间，-ref表示bean引用，后者表示bean ID。

### 6.4导入和混合配置

	可以有多个配置类，一个配置类可以应用另一个配置类

~~~Java
@Configurable
public class CDConfig {}

@Configurable
@Import(CDConfig.class)
public class CDPlayerConfig {}

//也可以引入多个配置类
//@Import({CDConfig.class,CDConfig.class})

//引入一个配置文件
@Configurable
@Import(CDConfig.class)
@ImportResource("classpath:cd-config.xml")
public class CDPlayerConfig {}
~~~

	配置文件也可以导入另一个配置文件

~~~XML
<import resource="classpath:cd-config.xml"/>
~~~

	配置文件可以导入一个配置类

~~~XML
<bean class="com.sanyue.CDConfig"/>
~~~
