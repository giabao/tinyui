## Changelogs
we use [Semantic Versioning](http://semver.org/)

#### 7.0.0
+ Not use tink_syntaxhub to reduce compile time ~3 times
    (in our large project, compile time is reduced from 40s to 10s)

+ revert syntax as in version 5.x:

regex replace from:
`@:tinyui\((['"][^)]+)`
to:
`@:build(TinyUI.build($1)`

+ rename & change `TinyUI.saveCodeTo` to `TinyUI.init` for better meaning.

+ use `-D tinyui-use-gen-code` flag instead of argument `useGeneratedCode` of `TinyUI.saveCodeTo` method
    see document of `TinyUI.init` for more detail.

#### 6.0.1
+ better error logging

#### 6.0.0
+ break change:
  `@:build(TinyUI.build(<xml-file>))`
must be changed to:
  `@:tinyui(<xml-file>)`

    migration guide: regex replace from:
`@:build\(TinyUI\.build\(([^\)]+)\)` to
`@:tinyui($1`

+ feature: define a class by ONLY the xml file.
see file [example/ui-src/com/sandinh/XmlOnlyView.xml](example/ui-src/com/sandinh/XmlOnlyView.xml)

+ fix error when switch configs for normal build or bypass TinyUI.build & using the generated code.

+ change syntax for declaring local variable & instance variable:
    5.x: `var="<local-var>"` and `var.field="<instance-var>"`
    6.x: `var.local="<local-var>"` and `var="<instance-var>"`

    This change is because we found (in our real project) that instance variables are appeared more frequently.
    
    migrate guide: regex replace from (note the prefixed space)
    ` var=(['"])` to ` var.local=$1`
    
    and then:
    ` var\.field=(['"])` to ` var=$1`
    
    and then replace `var.local` attribute of `<in ` mode nodes back to `var` by searching:
    `<in ([^>]*)var\.local=` then replace to `<in $1var=`

#### 5.0.1
+ now you can switch configs for normal build or bypass TinyUI.build & using the generated code.

+ warning if tinyui can not found property/ method/ extension method when parsing xml

#### 5.0.0
we break change again :(
This time, I think the syntax for declaring ui in xml in tinyui is stable (not be changed again :d)

See example 18-all.xml for the new syntax (more consistent, less verbose)

#### 4.0.1
+ fixes error when setting nested variable in view

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

+ new feature: support styling. see `17-styles.xml`

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
