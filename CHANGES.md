## Changelogs
we use [Semantic Versioning](http://semver.org/)

#### 4.0.0
+ (breaking change) init default uiMode var to -1 and declare the inline static vars UI_$modeName start at 0 instead of 1

+ feature: order of attributes of a node is now preserved when translating to code.

    see `02-field-field-by-xml-attr.xml`

+ (breaking change) remove old syntax for declaring local/ instance variables:
    
    + migrate:
        
        `var.foo="value"` or `var.foo:Type="value"`
        
        To:
        
        `<Type var="foo" new="value" />`
        
        ex:
        `<Int var="foo" new="1+2" />`
        
        The new syntax also permit us to write:
        
        `<TextFormat var="myFmt" bold="true" />`
        
        or declare instance var:
        
        `<TextFormat var="this.myFmt" bold="true" />`
        
    + migrate:
        
        `<TextField var="txt" />`
        
        To:
        
        `<ui-TextField var="this.txt" />`
        
        And:
        
        `<TextField var="#txt" />`
        
        To:
        
        `<ui-TextField var="txt" />`
        
    + see `07-initUI-local-var.xml`

+ feature (also breaking change):

    view item nodes now must be declared with name `<ui-Type>` instead of just `<Type>` as previous.

    This permit us to declare nested items right in xml.

    note: this feature should be used for simple nested view only.

    For complex nested view, the recommend way is declare as a separated view class.

    see `12-nested-items.xml`
    
+ break change in method calling syntax:
    
    migrate:
    
    `<.. this.fnName="args" />`
    
    To:
    
    `<.. fnName="args" />`
    
    Tinyui will check if attribute `name` is a var field then gen code `.name=value` else `.name(value)`
    
    see `09-call-method.xml`
    
+ modes syntax:

    `<mode.NAME>` must be migrate to `<mode-NAME>`
    
    in each mode node:
    
    `<varName ..>` must be migrate to `<in.varName ..>`

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
