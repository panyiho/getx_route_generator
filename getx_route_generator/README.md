# getx_route_generator
Language: English | [中文](README_CN.md)

`getx_route_generator` is a code generation library based on `build_runner`, designed to generate a route table for pages using the GetX library. Say goodbye to manually writing route paths and GetPage mappings.

## Usage
Add the latest version of `getx_route_generator` to your dependencies.
``` yaml
  dependencies: 
    getx_route_annotations: [latest-version]

  dev_dependencies:                    
    getx_route_generator: [latest-version]  
```
Add the GetXRoutePage annotation above the class of the specific route page.

``` dart
@GetXRoutePage("/home")
class HomePage extends StatefulWidget {}
```
(PS: GetXRoutePage requires passing a path. In the generated route table class, a global variable like the one below will be automatically generated and can be used directly.)

``` dart
static const String home = '/home';
```
Then run the following command in the terminal:

``` bash
flutter pub run build_runner build
```
getx_route_generator will automatically generate a route_table.dart file in the lib/generated directory based on the annotations you added. The generated code looks like this:

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
It's that simple!