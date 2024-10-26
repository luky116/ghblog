---
title: "Arana 启动源码分析"
date: 2021-12-16T15:22:17+08:00
Author: Luky116
tags: ["Arana"]
categories: ["Arana","源码系列"]
---

## 关于Arana

Arana([https://github.com/dubbogo/arana](https://github.com/dubbogo/arana)) 项目刚启动不到两个月，各个功能都还在规划和刚开始开发的阶段。刚接触这个项目也不久，还在熟悉代码中。这个项目0.1版本的规划包括：

1. SQL 透传
1. SQL 语法解析
1. 分片算法
1. sharding功能
1. 动态配置中心
1. 分布式事务支持

总结来说，Arana项目是作为数据库的一个代理层，来实现分库分表和动态路由等功能的一个Proxy数据库插件。我们由原先直接访问数据库，转变为先访问Arana代理，再由Arana将我们的请求进行加工后，打到数据库服务器上去，如下图：​

![image.png](/img/arana/anara1_process1.jpg#img-60)

​Arana 的内部主要有这几个部分组成：

1. 监听器（Listener）：监听外部请求的一个TCP服务，用来监听和接收外部请求的SQL命令
1. 过滤器（Filter）：分为前置过滤器(PreFilter)和后置过滤器(PostFilter)，在执行SQL前，对SQL进行特殊处理；获取到SQL执行结果后，对结果进行加工再返回给请求方
1. 执行器（Executor）：负责将SQL命令打到合适的目标数据库服务器上
1. 数据源（DataSourceCluster）:实际执行SQL的数据库服务器

Arana 内部的执行流程如下：

![image.png](/img/arana/anara1_process2.jpg#img-20)

## 如何本地启动项目
Arana的源码地址在：[https://github.com/dubbogo/arana](https://github.com/dubbogo/arana)，为了防止master分支的源码更新太快导致对不上本文的流程，可以拉取这个版本的代码对着本文阅读：[https://github.com/dubbogo/arana/tree/eedc576fdcea8de70910f43e0a8bf21dbb9c9295](https://github.com/dubbogo/arana/tree/eedc576fdcea8de70910f43e0a8bf21dbb9c9295)。

​源码拉取下来后，看到Arana的目录结构：

![image.png](/img/arana/arana1_project.png#img-60)

- cmd：Arana的启动入口方法
- dist：编译后的文件
- docker：docker相关的配置
- pkg：Arana的业务逻辑
- test：存放继承测试文件
- third_party：第三方依赖

​

目前有两种方式来启动Arana：

1、通过docker启动。

1. 在根目录下执行以下命令，构建Arana的docker镜像
> make build && make build-docker

2. 进入docker/目录，执行如下命令启动arana的docker镜像
> cd docker/
> docker-compose -f docker-compose.yaml up -d arana

3. 执行test/integration_test.go里的集成测试，即可看到结果输出

2、通过main函数启动，方便调试代码

1. 进入docker/目录，在根目录下执行以下命令，启动MySQL的docker镜像
> cd docker/
> docker-compose -f docker-compose.yaml up -d mysql

2. 配置cmd/cmd.go中main函数的启动参数
> start -c docker/conf/config.yaml

![image.png](/img/arana/arana1_mainconfig.png#img-60)

3. 将 docker/conf/config.yaml 文件的dsn配置的域名由arana-mysql改为127.0.0.1
3. 启动 cmd/cmd.go文件的main函数，即可启动服务
3. 执行test/integration_test.go里的集成测试，即可看到结果输出
<a name="fRQRH"></a>
## 项目启动流程
为了了解Arana的启动流程，我们打开cmd/cmd.go文件。可以看到，cmd.go文件使用了cobra库。cobra库是golang开源的命令行库，详情可以参考源码地址：[https://github.com/spf13/cobra](https://github.com/spf13/cobra)。startCommand.Run 方法里面的逻辑，就是程序初始化的整个流程。

在init方法中，我们看到程序启动时接收了一个c参数，并把值赋给了configPath（配置文件的位置）变量。上面我们配置main函数的启动参数`start -c docker/conf/config.yaml`，可以找到配置文件所在的位置。在配置文件中可以看到Listener、Executor和DataSourceCluster的相关配置（此时Filter功能尚未实现，所以没有Filter的配置）。

startCommand中Run方法中，第一步是加载配置文件，组装成一个Configuration对象：

```go
conf := config.Load(configPath)
```
初始化Filter的逻辑先忽略，先看下初始化Executor的流程。从配置文件可以看到，一个Executor可以绑定多个数据源（DataSource）：
```yaml
executors:
  - name: redirect
    mode: singledb
    # 一个Executor可以绑定多个dataSource
    data_sources:
      - master: employees
```
一个Executor同时可以绑定多个前置过滤器和后置过滤器：
```go
for _, executorConf := range conf.Executors {
    executor := executor.NewRedirectExecutor(executorConf)

    for i := 0; i < len(executorConf.Filters); i++ {
        filterName := executorConf.Filters[i]
        f := filter.GetFilter(filterName)
        if f != nil {
            preFilter, ok := f.(proto.PreFilter)
            if ok {
                // 一个Executor绑定多个前置过滤器
                executor.AddPreFilter(preFilter)
            }
            postFilter, ok := f.(proto.PostFilter)
            if ok {
                // 一个Executor绑定多个后置过滤器
                executor.AddPostFilter(postFilter)
            }
        }
    }
    executors[executorConf.Name] = executor
}
```
接下来是初始化数据源（DataSource）的流程，这里是将数据源Factory方法作为InitDataSourceManager的一个参数：
```go
resource.InitDataSourceManager(conf.DataSources, func(config json.RawMessage) pools.Factory {
    collector, err := mysql.NewConnector(config)
    if err != nil {
        panic(err)
    }
    return collector.NewBackendConnection
})
```
进入到InitDataSourceManager方法，看到调用 据源Factory 传的参数是 dataSourceConfig.Conf：
```go
// factory(dataSourceConfig.Conf) 看到传参
initResourcePool := func(dataSourceConfig *config.DataSource) *pools.ResourcePool {
    resourcePool := pools.NewResourcePool(factory(dataSourceConfig.Conf), dataSourceConfig.Capacity,
                                          dataSourceConfig.MaxCapacity, dataSourceConfig.IdleTimeout, 1, nil)
    return resourcePool
}
```
打开配置文件，可以看到这个参数对应的是conf.dsn配置：
```yaml
data_source_cluster:
  - role: master
    type: mysql
    name: employees
    capacity: 10
    max_capacity: 20
    idle_timeout: 60s
    # factory接收的是这个参数
    conf:
      dsn: root:123456@tcp(arana-mysql:3306)/employees?timeout=1s&readTimeout=1s&writeTimeout=1s&parseTime=true&loc=Local&charset=utf8mb4,utf8
```
回到cmd.go文件，进入 mysql.NewConnector(config) 方法中，看下是如何初始化Collector 的：
```go
func NewConnector(config json.RawMessage) (*Connector, error) {
	v := &struct {
  	# 从配置文件可以看到dsn的值
		DSN string `json:"dsn"`
	}{}
	if err := json.Unmarshal(config, v); err != nil {
		log.Errorf("unmarshal mysql Listener config failed, %s", err)
		return nil, err
	}
	// ParseDSN 解析MySQL的连接信息，包括host、port、username、db、password、编码方式等等
	cfg, err := ParseDSN(v.DSN)
	if err != nil {
		return nil, err
	}
	return &Connector{cfg}, nil
}
```
得到Connector对象后，cmd.go中返回了 collector.NewBackendConnection 方法，我们进到这个方法里面：
```go
func (c *Connector) NewBackendConnection(ctx context.Context) (pools.Resource, error) {
	conn := &BackendConnection{conf: c.conf}
	// 本地启动TCP的监听MySQL的端口服务
	err := conn.connect()
	return conn, err
}
```
再打开  conn.connect() 方法，就可以看到真正连接MySQL服务器的逻辑
```go
func (conn *BackendConnection) connect() error {
	//  省略部分代码 ......
    
	// 这里连接MySQL服务器
	netConn, err := net.Dial(typ, conn.conf.Addr)
	if err != nil {
		return err
	}
	tcpConn := netConn.(*net.TCPConn)
	// SetNoDelay controls whether the operating system should delay packet transmission
	// in hopes of sending fewer packets (Nagle's algorithm).
	// The default is true (no delay),
	// meaning that Content is sent as soon as possible after a Write.
	tcpConn.SetNoDelay(true)
	tcpConn.SetKeepAlive(true)
	conn.c = newConn(tcpConn)
	// 等待TCP握手成功，即建立和MySQL的连接，即可返回
	return conn.clientHandshake()
}
```
再次回到 InitDataSourceManager方法中，我们看下 collector.NewBackendConnection 方法是如何被调用的：
```go
func InitDataSourceManager(dataSources []*config.DataSource, factory func(config json.RawMessage) pools.Factory) {
    //  省略部分代码 ......
    
    // 对数据源分进行了分类，放到不同的连接池map总存储:
    // master：主库
    // slave：从库
    // meta：目前暂未用到，未来会用来存储分布式事务相关的配置数据
    for i := 0; i < len(dataSources); i++ {
		switch dataSources[i].Role {
		case config.Master:
			resourcePool := initResourcePool(dataSources[i])
			masterResourcePool[dataSources[i].Name] = resourcePool
		case config.Slave:
			resourcePool := initResourcePool(dataSources[i])
			slaveResourcePool[dataSources[i].Name] = resourcePool
		case config.Meta:
			resourcePool := initResourcePool(dataSources[i])
			metaResourcePool[dataSources[i].Name] = resourcePool
		default:
			panic(fmt.Errorf("unsupported data source type: %d", dataSources[i].Role))
		}
	}
}
    
```
至此，数据库数据源的初始化就完成了。

接下来是初始化监听器Listener，我们进入 mysql.NewListener(listenerConf) 方法中，可以看到其实就是启动了一个服务监听一个TCP服务的端口：
```go
func NewListener(conf *config.Listener) (proto.Listener, error) {
	// 省略部分代码......

	// 定义一个连接对象，监听指定的端口
	l, err := net.Listen("tcp", fmt.Sprintf("%s:%d", conf.SocketAddress.Address, conf.SocketAddress.Port))
	if err != nil {
		log.Errorf("listen %s:%d error, %s", conf.SocketAddress.Address, conf.SocketAddress.Port, err)
		return nil, err
	}

	listener := &Listener{
		conf:     cfg,
		listener: l,
		stmts:    make(map[uint32]*proto.Stmt, 0),
	}
	return listener, nil
}
```
接下来是给每个Listener指定一个执行器Executor：
```go
// 指定执行器
listener.SetExecutor(executor)
// 将监听器暂存起来
propeller.AddListener(listener)
```
 接下来调用 propeller.Start() 启动所有的监听器，监听外部服务。进入Start方法，发现是调用了listener.Listener() 方法。打开这个方法：
```go
func (l *Listener) Listen() {
	log.Infof("start mysql Listener %s", l.listener.Addr())
	for {
        // 接收外部的请求
		conn, err := l.listener.Accept()
		if err != nil {
			return
		}

		connectionID := l.connectionID
		l.connectionID++
		
        // 调用handle方法处理请求并返回给调用方
		go l.handle(conn, connectionID)
	}
}
```
 进入handle方法，调用了ExecuteCommand方法执行SQL，并返回处理结果。ExecuteCommand方法的执行细节有机会单独出一篇文章解析下。
```go
func (l *Listener) handle(conn net.Conn, connectionID uint32) {
	// 省略部分代码......

    // 建立连接
	err := l.handshake(c)
	if err != nil {
		werr := c.writeErrorPacketFromError(err)
		if werr != nil {
			log.Errorf("Cannot write error packet to %s: %v", c, werr)
			return
		}
		return
	}

	// 省略部分代码......
    
	for {
		c.sequence = 0
        // 读取请求的数据（SQL）
		data, err := c.readEphemeralPacket()
		if err != nil {
			c.recycleReadPacket()
			return
		}

		ctx := &proto.Context{
			Context:      context.Background(),
			ConnectionID: l.connectionID,
			Data:         data,
		}
        // 执行SQL，并返回执行结果
		err = l.ExecuteCommand(c, ctx)
		if err != nil {
			return
		}
	}
}

```
至此，Arana的启动和处理流程的源码都梳理完了。从目前来看，Arana做的事情就是透传SQL，没有做其他的事情，比如Filtrer功能都还没支持。从这个简单的框架可以很好的了解Arana的原理，正是通过阅读源码了解Arana的好机会！


​
