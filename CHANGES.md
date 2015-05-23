### Changelogs
##### 3.2.0
(backward compatible with 3.x)
+ support view modes (view states)

##### 3.1.0
(backward compatible with 3.x)
+ add some example: using extension method & tooltip
+ add convenient class com.sandinh.ui.BitmapTools

##### 3.0.1
+ change licence to MIT license.
+ haxelib submit

##### 3.0.0
+ break changes for better meaning and less verbose:
Change function calling syntax from:
`<function fnName="args">`, `<function.fnName args>`
to:
`<this. fnName="args">`, `<this.fnName args>`

+ Now function can also be call by `this.fnName` attribute (instead of child node).

+ migration: replace in xml file:
  `<function ` to `<this. ` (note the space)
  `<function.` to `<this.`

+ ability to introduce a local variable name for view items:
```xml
<UI>
    <Bitmap var="myClassField" />
    <Bitmap var="#localVar" />
</UI>
```
As always, see the generated code for detail.

+ add layout example using [advanced-layout](https://github.com/player-03/advanced-layout)

##### 2.1.0
+ support `<for iterName="iterableExpression">` syntax
##### 2.0.0
(breaking change) rewrite the TinyUI class & add many examples
##### 1.0.0
(deprecated) first public release

### Licence
This software is licensed under the MIT license.

Copyright 2015 Sân Đình (http://sandinh.com)
