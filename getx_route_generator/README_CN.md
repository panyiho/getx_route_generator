# getx_route_generator
Language: 中文 | [English](README.md)  
 getx_route_generator是一个基于build_runner的代码生成工具库，用来生成使用GetX库的路由页面的路由表。从此解放双手，不需要自己手动编写路由path和GetPage的映射了。

 ## 使用方法
 添加getx_route_generator的最新版本到你的依赖里面
 ``` yaml
  dependencies: 
    getx_route_annotations: [latest-version]

  dev_dependencies:                    
    getx_route_generator: [latest-version]  
 ```
在具体的路由页面的class上面添加注解 GetXRoutePage

``` dart 
@GetXRoutePage("/home")    
class HomePage extends StatefulWidget {}    
```
  ( PS: GetXRoutePage需要传入一个path，在生成的路由表类中会自动生成类似这样的全局变量，可以直接使用 )
``` dart 
static const String home = '/home';
``` 

然后在命令行运行
```  
flutter pub run build_runner build
```

然后getx_route_generator会自动根据你添加的注解在lib/generated目录下生成一个route_table.dart文件，代码示例如下：
``` dart
import 'package:get/get.dart';
import 'package:xxx/page/home_page.dart';

class RouteTable {
  static const String home = '/home';

  static final List<GetPage> pages = [
    GetPage(name: '/home', page: () => HomePage()),
  ];
}

```

就这么简单！