+++
author = "飞狐"
categories = ["Java编程","翻译"]
tags = ["Java","Java Concurrency"]
date = "2017-03-30T14:49:08+08:00"
description = "Blog of Rosen Lu"
keywords = ["java concurrency"]
title = "1. [译]Java多线程与并发教程"

+++
本文翻译自[**Java Concurrency / Multithreading Tutorial**](http://tutorials.jenkov.com/java-concurrency/index.html)

最开始一台电脑只有单个CPU，只能一次运行一个任务，之后出现的多任务处理则意味着计算机在同一时间可以处理多个程序（也可以称之为任务或进程），虽然它们并不是真正的并发。由于单个CPU被不同的程序共用，操作系统需要在程序运行过程中不停地切换CPU，在短暂的执行一个程序后就立即切换到下一个程序。

多任务处理给软件开发人员提出了新的挑战，程序不能再假定拥有CPU所有的可用时间、内存和其它计算机资源，一个好的程序应该及时释放所有不需要使用的资源，以便其它程序可以使用它们。
之后出现的多线程则意味着可以在同一个程序里面执行多个线程，每一个执行的线程可以被认为是CPU在执行当前程序，当在同一个程序里面执行多个线程时，看起来像是拥有多个CPU在执行该程序。
<!--more-->

多线程虽然是提高某些类型程序性能的良方，但是多线程比多任务更具有挑战性。由于这些线程执行的是相同的程序，因此它们同时读写相同的内存，这可能会导致在单线程中不会出现的错误结果。某些错误结果不会出现在单CPU中机器中是由于两个线程不可能同时执行。现在的电脑大都拥有多核甚至多CPU，这意味着多个不同的线程可以被不同的内核或CPU同时执行。  
![多线程介绍1](/blog_img/java-concurrency-multithreading-tutorial/java-concurrency-tutorial-introduction_1.png)  
如果一个线程读取一个内存地址同时另一个线程向其写入信息，第一个线程在读取完成时会得到什么值呢？旧的值还是被第二个线程写入的新值？亦或是这两个值得混合？若两个线程同时向一个内存地址写入信息，当这两个线程运行完毕时，最终的值会是什么呢？是第一个线程写入的值还是第二个线程写入的值？亦或是这两个线程写入值的混合？

在缺少适当措施的情况下，上述的任意一种结果都可能出现，程序的运行结果甚至不可预测，每一次的执行结果可能都不同。因此怎么处理多线程对于软件开发人员很重要，这意味着我们需要学习如何控制线程来访问共享资源如内存、文件、数据库等，而这正是本系列教程所要阐述的主题之一。

## Java中的多线程和并发
Java是最先让多线程对开发人员变得简单的程序语言之一，Java在最开始的时候就已经具备了多线程的能力，因此Java开发人员经常面临上文所述的并发问题。这正是我编写本系列Java并发教程的原因，作为自己的笔记以及其他可能从中获益的Java开发人员。

本教程将主要关注于Java中的多线程，但其中的一些多线程问题与多任务和分布式系统系统中出现的问题类似，因此在本教程中可能会出现对多任务和分布式系统的引用。并发不等于多线程，它们是不同的概念。

## Java并发在2015的现状和展望
自从第一本Java并发书籍问世之后，关于并发架构和设计领域已经发生了很多变化，`Java5`甚至提供了concurrency工具包。新的类似于Vert.x、Play/Akka和Qbit的异步无共享平台和API已经出现。这些平台使用了一个不同于标准Java/JEE并发的模型来处理线程、共享内存和锁。新的无阻塞并发算法已经公开，类似于LMax Disrupter这样的非阻塞工具也已经添加到我们的工具箱。在`Java7`中通过Fork和Join框架引入了并行性功能编程，并在`Java8`中引入了流相关的API。

所有这些新的进展让我觉得是时候编更新本系列的Java并发教程，因此本教程再一次处于编写中状态，新的教程会在时间允许编写时发布。


<–翻译结束!–>