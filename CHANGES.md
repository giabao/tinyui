## Changelogs
we use [Semantic Versioning](http://semver.org/)

#### 4.0.0
+ (breaking change) init default uiMode var to -1 and declare UI_$modeName inline static vars start at 0 instead of 1
+ feature: able declare nested items right in xml.
    note: this feature should be used for simple nested view only.
    For complex nested view, the recommend way is declare as a separated view class.
    see example [13-nested-items.xml](example/ui/13-nested-items.xml)

#### 3.2.0
+ support view modes (view states)

#### 3.1.0
+ add some example: using extension method & tooltip
+ add convenient class com.sandinh.ui.BitmapTools

#### 3.0.1
+ change licence to MIT license.
+ haxelib submit

#### 3.0.0
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

#### 2.1.0
+ support `<for iterName="iterableExpression">` syntax
#### 2.0.0
(breaking change) rewrite the TinyUI class & add many examples
#### 1.0.0
(deprecated) first public release

### Licence
This software is licensed under the MIT license.

Copyright 2015 Sân Đình (http://sandinh.com)
