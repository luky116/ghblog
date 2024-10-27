---
title: "golang学习-类型转换"
date: 2021-05-25T08:58:41+08:00
draft: true
tags: ["golang"]
categories: ["golang"]
---

### 基本类型之间转换

在go中，基本类型有以下这些：

- 整型类型：uint8、uint16、uint32、uint64、int8、int16、int32、int64

- 浮点类型：float32、float64、complex64、complex128

- 其他数字类型：byte、rune、uint、int、uintptr

- 布尔类型：true、false

- 字符串：一串固定长度的字符连接起来的字符序列，Go 语言的字符串的字节使用 UTF-8 编码标识 Unicode 文本。

  

不同的基本类型之间可以互相转换，转换的语法为：

~~~go
type_name(expression)
~~~

### 整型和浮点类型转换

~~~golang
func main() {
	var a int64 = 100
	var b float64 = 10.8

	fmt.Println("a的值为：", a, "b的值为：", b)

	b = float64(a)
	fmt.Println("a的值为：", a, "b的值为：", b)
}
~~~

输出结果为：

~~~
a的值为： 100 b的值为： 10.8
a的值为： 100 b的值为： 100
~~~

### 高精度数字 转 低精度数字：

~~~go
func main() {
	var a int64 = 6666
	var b int8 = 12
	fmt.Println("a的值为：", a, "b的值为：", b)
	
  // b精度溢出，出现精度损失
	b = int8(a)
	fmt.Println("a的值为：", a, "b的值为：", b)
}
~~~

输出结果为：

~~~
a的值为： 6666 b的值为： 12
a的值为： 6666 b的值为： 10
~~~

`int8`类型的范围是 -128 到 127，所以会出现精度溢出，但是golang并不会编译报错

### string和byte数组互转

string转byte数组方式：

~~~golang
[]byte(string)
~~~

byte数组转string方式：

~~~golang
string([]byte)
~~~

例如：

~~~golang
func main() {
	var aa string = "hello, world"
	var bb []byte = []byte(aa)
	var cc = string(bb)
	
	fmt.Println("aa = ", aa)
	fmt.Println("bb = ", bb)
	fmt.Println("cc = ", cc)
}
~~~

输出为：

~~~
aa =  hello, world
bb =  [104 101 108 108 111 44 32 119 111 114 108 100]
cc =  hello, world
~~~

### string类型与数字、bool类型互转

使用`fmt.Springf`完成数字和string的转换，比如：

~~~golang
func main() {
	var aa int32 = 168
	var bb float32 = 125.676
	fmt.Println("aa的值为：", aa, "bb的值为：", bb)
	
	// 整型转string
	var as = fmt.Sprintf("%d", aa)
	// 浮点型转string
	var bs = fmt.Sprintf("%f", bb)
	fmt.Println("as的值为：", as, "bs的值为：", bs)
}
~~~

输出为：

~~~
aa的值为： 168 bb的值为： 125.676
as的值为： 168 bs的值为： 125.676003
~~~


也可以使用`strconv`工具类来进行转换，例如：

 string 转 float64：

~~~golang
flo64, err := strconv.ParseFloat("1234.5323", 10)
~~~

 string 转 int64：

~~~golang
// 参数1是被转换的字符串，
// 参数2是数字字符串的进制，2到32进制
// 参数3 返回结果的bit大小，0，8，16，32，64分别表示int int8 int16 int32 int64
in64, err := strconv.ParseInt("1234.5323", 10, 32)
~~~

 int64 转 string

~~~golang
str := strconv.FormatInt(168, 10)
~~~

 float64 转 string

~~~golang
// 第1个参数是你要转换的值
// 第2个参数是表示转换后的格式
// 第3个参数是控制精度的，详细看图片
// 第4个参数是指这个传进去的精度是64的
str2 := strconv.FormatFloat(555.666, 'e', 10, 64)
~~~

bool 转string

~~~golang
// 返回“true”
boolStr :=strconv.FormatBool(true)
~~~

string转bool

~~~golang
// 传入 "1", "t", "T", "true", "TRUE", "True" ，返回true,nil
// 传入 "0", "f", "F", "false", "FALSE", "False"，饭false,nil
// 否则返回 false, syntaxError("ParseBool", str)
bol := strconv.ParseBool("true")
~~~

注意，golang中**不支持隐式的类型转换**。比如，

~~~golang
func main() {
	var aa int64 = 100
	var bb float64 = 12.3
	
	// 编译报错
	// var cc float64 = aa * bb
	
	// 将aa转成float64再相加
	var cc float64 = float64(aa) * bb
	
	fmt.Println(cc)
}
~~~

### interface{} 类型转换

interface{}类型转换成具体类型的语法：

~~~golang
interfaceVar.(具体类型)
~~~

一般使用断言来实现，比如：

~~~golang
value, ok := aa.(string)
if !ok {
    fmt.Println("It's not ok for type string")
    return
}
fmt.Println("The value is ", value)
~~~

也可以使用switch...case类判断，例如：

~~~golang
func main() {
  var t interface{} = 10.6
  switch i := t.(type) {
  case float32:
    fmt.Printf("Type is %T , Value is%v\n", i, i)
  case float64:
    fmt.Printf("Type is %T , Value is%v\n", i, i)
  case int:
    fmt.Printf("Type is %T , Value is%v\n", i, i)
  case bool:
    fmt.Printf("Type is %T , Value is%v\n", i, i)
  case string:
    fmt.Printf("Type is %T , Value is%v\n", i, i)
  default:
    fmt.Println("Other Type")
  }
}
~~~

具体的类型可以隐式转换成interface{}，比如，具体类型的变量可以传参给 interface{} 类型的参数



