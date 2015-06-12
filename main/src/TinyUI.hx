#if macro
import tink.macro.ClassBuilder;
import haxe.macro.Compiler;
import haxe.macro.Type;
import haxe.macro.Printer;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.File;
import sys.FileSystem;
import _tinyui.*;
import neko.Lib.println;
import haxe.CallStack;

using Lambda;
using com.sandinh.core.LambdaEx;
using StringTools;
using _tinyui.Tools;
using haxe.macro.Tools;
using tink.MacroApi;

class TinyUI {
    static var genCodeDir: String = null;
    static inline var CodeGenBegin = "\n\t//++++++++++ code gen by tinyui ++++++++++//\n\t";
    static inline var CodeGenEnd = "\n\t//---------- code gen by tinyui ----------//\n";

    /** Config TinyUI.
      * @param genCodeDir - the directory to save generated code to.
      * @param uiSrcDirs - array of source dir contains only .hx view files
      *     need to be built using @:build(TinyUI.build(<the-xml-file>)).
      * @param genTypePrefix TinyUI will gen haxe type from xml file only if type (include package name)
      *     is prefixed with this argument.
      *     You should use this feature in large projects to reduce the compile time.
      *     In our project, set genTypePrefix="com.sandinh.ui" reduce compile time from 30s to 10s!
      *
      * config tinyui_use_gen_code -
      *     unset (default) for normal @build. uiSrcDirs will be add to class path (Compiler.addClassPath)
      *     set (by add: -D tinyui-use-gen-code) to bypass TinyUI.build function.
      *         We will use the generated code when compiling: Compiler.addClassPath(genCodeDir)
      *
      * usage, ex with openfl: add to using openfl project.xml file:
      * ```xml
      * <!--uncomment to bypass TinyUI.build & using the generated code-->
      * <haxeflag name="-D tinyui-use-gen-code"/>
      * <haxeflag name="--macro" value="TinyUI.init('ui-codegen', ['ui-src'], 'com.sandinh')"/>
      * ``` */
    public static function init(genCodeDir: String,
                                uiSrcDirs: Array<String> = null,
                                genTypePrefix: String = ""): Void {
        #if tinyui_use_gen_code
            Compiler.addClassPath(genCodeDir);
        #else
            TinyUI.genCodeDir = genCodeDir.endsWith("/")? genCodeDir : genCodeDir + "/";
            if (uiSrcDirs != null) {
                uiSrcDirs.iter(Compiler.addClassPath);
            }

            genCodeDir.delDirRecursive();

            TinyUIPlugin.init(genTypePrefix);
        #end
    }

    static function build(xmlFile: String): Array<Field> {
        #if tinyui_use_gen_code
        return null;
        #else
        return try switch Context.getLocalType() {
            case TInst(_.get() => c, _):
                var builder = new ClassBuilder(c);
                new TinyUI(xmlFile, builder).doBuild();
                builder.export(builder.target.meta.has(':explain'));
            default: null;
        } catch(e: Dynamic) {
            println('ERROR! tinyui build failed: $e\n' + CallStack.toString(CallStack.exceptionStack()));
            null;
        }
        #end
    }

    /** Position point to the xml file. we store this in a class var for convenient */
    var xmlPos: Position;
    var xml: Xml;
    var builder: ClassBuilder;

    var localVarNameGen = new LocalVarNameGen();

    function new(xmlFile: String, builder: ClassBuilder) {
        this.xmlPos = Context.makePosition( { min:0, max:0, file:xmlFile } );
        this.xml = xmlFile.parseXml();
        this.builder = builder;
    }

    /** See build(String) */
    function doBuild() {
        //code for initUI() method
        var code = processNode(xml, "this", Context.getLocalType());
        
        code += genUIModes();

        addInitCode(code);
        
        saveCode();
    }
    
    /** Get "new" expression to create an instance of className.
     * + if `node` don't have "new" attribute then return 'new $className()'
     * + if the attr is in short syntax, ex: new=":'Tahoma', 16" then we will replace (:) by 'new $className'
     * + else (full syntax) then use as-is.
     * Ex:
     *  <Bitmap new="new Bitmap(Assets.getBitmapData('/some_img.png'))" />
     *  <Bitmap new=":Assets.getBitmapData('/some_img.png')" /> */
    static function getNewExpr(node: Xml, tpe: Type): String {
        var expr = node.get("new");
        expr = expr == null? ":" : expr.trim();
        return expr.charAt(0) != ':'? expr :
            "new " + tpe.fqdn() + "(" + expr.substr(1) + ")";
    }

    /** extract variables from xml node then convert to haxe code */
    function attr2Haxe(node: Xml, varName: String, tpe: Type): String {
        //`for` node's attributes is already processed in method `processNode`
        if (node.nodeName == "for") {
            return "";
        }
        var code = "";
        for (attr in node.attributes()) {
            switch(attr) {
                //"new" attribute is processed in `processNode` method.
                //"var", "var.local" attribute is processed in `processNode` method.
                //"function" attribute of root node is processed in `addInitCode` method.
                case "new" | "var" | "var.local" | "function":
                    continue;
                case "class":
                    var styleXml = Styles.getStyleXml(this.xml, node);
                    code += processNode(styleXml, varName, tpe);
                //ex: <Button label.text="'OK'" />
                //or: <TextField setTextFormat="myFmt,1" />
                default:
                    var field = findDotField(tpe, attr);
                    if (field == null) {
                        var msg = 'Not found field $attr of type $tpe when parsing attributes of node ${node.nodeName}'
                            + ". Are you using static extension method?";
                        Context.warning(msg, xmlPos);
                    }
                    var value = node.get(attr);
                    if (field != null && field.isVar) {
                        code += '$varName.$attr = $value;';
                    } else {
                        //if attr is not FVar then we expect it is a method or an extension method
                        code += '$varName.$attr($value);';
                    }
            }
        }
        return code;
    }

    /** check if `obj.dottedName` is a field with `obj` is an object of Type `tpe`
      * @param dottedName dot-separated name. ex label.tex */
    function findDotField(tpe: Type, dottedName: String): Null<MyClassField> {
        var i = dottedName.indexOf(".");
        var name = i == -1? dottedName : dottedName.substr(0, i);

        //FIXME if tpe is not a TInst?
        var clsField = tpe.getClass().findField(name);
        var field: MyClassField = clsField == null? null :
            {type: clsField.type, isVar: clsField.isVar()};

        //workaround because we can't findField of the building class
        //can not compare: tpe == Context.getLocalType()
        if (field == null && Context.getLocalType().tpeEquals(tpe)) {
            //1. check if name is declared in .xml ui file by attribute "var"
            var node = this.xml.elements()
                .find(function(child) return child.get("var") == name);
            if (node != null) {
                var tpeName = node.nodeName.startsWith("var.") ?
                    node.nodeName.substr(4) : node.nodeName; //"var.".length == 4
                field = {type: Context.getType(tpeName), isVar: true};
            } else {
                //2. check if name is declared in building class
                var buildField = builder.memberByName(name).orNull();
                if (buildField != null) {
                    field = switch(buildField.kind) {
                        case FVar(t, e) | FProp(_, _, t, e):
                            var tpeOfField = t != null?
                                t.toType().sure() : Context.typeof(e);
                            {type: tpeOfField, isVar: true};
                        case FFun(_):
                            {type: null, isVar: false};
                    }
                }
            }
        }
        //try check static extension methods
        if (field == null) {
            //Note that, when call `Context.getLocalUsing()`,
            // some static variable of the using class that need initialized will throw error.
            //ex: if class com.sandinh.TipTools (in haxelib openfl-tooltip) declare var:
            //  static var tip = new Tip();
            //then an error will be thrown :(
            for (f in Context.getLocalUsing().flatMap(staticFieldsOf))
                if (f.name == name && f.isPublic && !f.isVar()) {
                    var arg1Tpe = arg1TypeOfFun(f.type);
                    //we just TRY. If can't (arg1Tpe == null) then we assume that field is a method
                    if (arg1Tpe == null || Context.unify(tpe, arg1Tpe)) {
                        field = {type: null, isVar: false};
                        break;
                    }
                }
        }
        if (field == null || i == -1) return field;

        return field.isVar? findDotField(field.type, dottedName.substr(i + 1)) : null;
    }

    static function staticFieldsOf(ref: Ref<ClassType>): Array<ClassField> {
        return ref.get().statics.get();
    }

    static function arg1TypeOfFun(tpe: Type): Null<Type> {
        return switch(tpe) {
            case TFun(args, _):
                args.length == 0? null : args[0].t;
            case TLazy(f):
                //will throw at com.sandinh.ui.BitmapTools.src:
                //  Class<openfl.Assets> has no field getBitmapData
                //I guess this is because getBitmapData is only defined #if !macro
                //  and the error is throw when we call `f()`
                //arg1TypeOfFun(f());
                null;
            //case TType(_): tpe;
            case _: tpe;
        }
    }

    static inline function getFnNodeArgs(node: Xml): Array<String> {
        return node.attributes().array().map(node.get);
    }

    /**Process <this.functionName> node
     * ex: see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/fl/core/UIComponent.html#setStyle%28%29
     * <Label>
     *   <this.setStyle style.1="'textFormat'" value.2="new TextFormat('Tahoma', 16)" />
     * </Label>
     * 
     * ex2:
     * <Label><this.setStyle style="'textFormat'">
     *   <TextFormat font="'Tahoma'" size="16" bold="true" />
     * </this.setStyle></Label>
     * 
     * @return code */
    function processNodeAsOneFnCall(node: Xml, varName: String): String {
        var code = "";
        var fnName = node.nodeName.substr(5); //"this.".length == 5
        var args: Array<String> = getFnNodeArgs(node);
        
        for (child in node.elements()) {
            switch(child.nodeName) {
                case "this":
                    getFnNodeArgs(child).iter(args.push);
                    
                //if `node` is `this.$fnName` node then `child` is className of a fnName's argument
                case childClassName:
                    var childVarName = localVarNameGen.next(childClassName);
                    var tpe = Context.getType(childClassName);
                    var newExpr = getNewExpr(child, tpe);
                    code += 'var $childVarName = $newExpr;';
                    code += processNode(child, childVarName, tpe);
                    args.push(childVarName);
            }
        }
        
        return code + '$varName.$fnName(' + args.join(",") + ");";
    }
    
    /**Process a `var.` node or a node that declare a view item.
     * node has `var.field` attribute will be generated to a haxe field.
     * @return code */
    function processVarOrViewItemNode(node: Xml, varName: String): String {
        var code = "";
        
        //child variable name or field name of view class
        var childVarName: String;
        var className = node.nodeName.startsWith("var.")?
            node.nodeName.substr(4) : node.nodeName; //"var.".length == 4

        var tpe = Context.getType(className);
        var newExpr = getNewExpr(node, tpe);
        //check if should we declare an class instance var field for this xml node
        //ex: <Button var="myLocalVar" />
        if (varName == "this" && node.exists("var")) {
            childVarName = node.get("var");
            var baseType = tpe.baseType();
            if (baseType == null) {
                throw 'Can not find type $className';
            }
            builder.addMember({
                pos    : xmlPos,
                name   : childVarName,
                access : [APublic], //TODO support asses, doc, meta?
                kind   : FVar(TPath({ //TODO support params?
                    name   : baseType.name,
                    pack   : baseType.pack
                }))
            });

            childVarName = "this." + childVarName;
            code += '$childVarName = $newExpr;';
        } else {
            childVarName = node.get("var.local");
            //ex: <Button var="myLocalVar" />
            //or: <Button />
            if(childVarName == null) {
                childVarName = localVarNameGen.next(className);
            }
            code += 'var $childVarName = $newExpr;';
        }

        code += processNode(node, childVarName, tpe);

        if (!node.nodeName.startsWith("var.")) {
            code += '$varName.addChild($childVarName);';
        }
        return code;
    }
    
    /** loop throught xml node recursively and generate haxe code for initUI function.
     * This method also push Fields to `builder` if ctx is ViewItem and the ViewItem node has `var` attribute.
     * @param node - the current xml node we are processing when looping.
     * @param varName - the variable name corresponding to the current node.
     *        for root node, varName is "this".
     *        for other nodes, varName maybe a field name or an initUI local variable generated by `LocalVarNameGen` */
    function processNode(node: Xml, varName: String, tpe: Type): String {
        //1. process node's attributes
        var code = attr2Haxe(node, varName, tpe);
        
        //2. process node's elements
        for (child in node.elements()) {
            switch [child.nodeName, varName] {
                //ex: <Sprite><this x="1+2" y="3" /></Sprite>
                //children nodes are ignored
                case ["this", _]:
                    code += attr2Haxe(child, varName, tpe);

                case ["for", _]:
                    var attrs = child.attributes();
                    var iterVar = attrs.next();
                    if (attrs.hasNext()) {
                        Context.warning("`for` node must has only one attribute", xmlPos);
                    }
                    var iter = child.get(iterVar);
                    code += 'for ($iterVar in $iter) {';
                    code += processNode(child, varName, tpe);
                    code += '}';

                case ["case", _]:
                    if (varName != "this") {
                        Context.warning("mode node 'case' can only be declared for view class as a whole", xmlPos);
                    }
                    //will be process later in `genUIMode` method

                case ["class" | "import" | "using", _]:
                    //"class" is processed in `attr2Haxe`
                    //"import" | "using" are processed in `parse`

                //setting var or calling method
                //name is var or method name
                case [name, _] if (name.startsWith("this.")):
                    code += processFieldAccessNode(child, varName, tpe);

                case _:
                    code += processVarOrViewItemNode(child, varName);
            }
        }
        
        return code;
    }

    /** process node which node.nodeName.startsWith("this").
      * @return code setting var or calling method. var/ method name is taken from node.nodeName */
    function processFieldAccessNode(node: Xml, varName: String, tpe: Type): String {
        var code = "";
        var name = node.nodeName.substr(5);//"this.".length == 5
        var field: MyClassField = findDotField(tpe, name);
        if (field == null) {
            var msg = 'Not found field $name of type $tpe when parsing $node.';
            var c = name.charAt(0);
            if (c.toUpperCase() == c) {
                msg += " Are you declaring a view item (need prefix `ui-` to the node name)?";
            }
            throw msg;
        }
        if (field.isVar) {
            var childVarName = localVarNameGen.next(field.type.baseType().name);
            var newExpr = getNewExpr(node, field.type);
            code += 'var $childVarName = $newExpr;';

            code += processNode(node, childVarName, field.type);
            code += '$varName.$name = $childVarName;';
        } else {
            code += processNodeAsOneFnCall(node, varName);
        }
        return code;
    }

    /**push `public static inline var UI_$modeName: Int = ${auto_inc value - start at 0}`
     * for all modeName found in `caseNode` into `builder` */
    function pushUIModeFields(caseNode: Xml) {
        function toField(mode: String, value: Int): Field {
            return {
                pos: xmlPos,
                name: 'UI_$mode',
                access: [APublic, AStatic, AInline],
                kind: FVar(macro: Int, Context.parse(Std.string(value), xmlPos))
            }
        }
        var v = 0;
        for (node in caseNode.elements())
            builder.addMember(toField(node.nodeName, v++));
    }

    /** similar to: code += processVarOrViewItemNode(child);
      * but do not process: addChild, `new` expression, declaring var field.
      * @return code */
    function processModeFor(child: Xml, varName: String): String {
        var itemNode = xml.elements().find(
            function (node) return varName == node.get("var") || varName == node.get("var.local")
        );
        if (itemNode == null) {
            throw 'View Item for variable name "$varName" not found. ' +
                'TinyUI can not parse ui mode <${child.parent.nodeName}>';
        }
        if (itemNode.exists("var")) {
            varName = "this." + varName;
        }
        var tpe = Context.getType(itemNode.nodeName);
        return processNode(child, varName, tpe);
    }

    /**Generate code for view mode feature:
     * @see example modes.xml & the generated code for more detail.
     * @param xml The view (root) node
     * @return code
     */
    function genUIModes(): String {
        var caseNodes = xml.elementsNamed("case");
        //if xml don't have modes node then return ""
        if (! caseNodes.hasNext()) {
            return "";
        }
        var caseNode = caseNodes.next();
        if (caseNodes.hasNext()) {
            throw "found multiple `case` node!";
        }

        pushUIModeFields(caseNode);

        //public var uiMode(default, set): Int = -1;
        builder.addMember({
            pos : xmlPos,
            name : "uiMode",
            access : [APublic],
            kind : FProp("default", "set", macro: Int, {
                expr: EConst(CInt("-1")),
                pos: xmlPos
            })
        });
        
        //var _set_uiMode: Int -> Void;
        builder.addMember({
                            pos    : xmlPos,
                            name   : "_set_uiMode",
                            kind   : FVar(TFunction(
                                [macro: Int],
                                macro: Void))
                        });
        
        //generate dummy function to extract expressions
        var dummy : Expr = Context.parse(
            "function (mode: Int): Int {" +
            "  if (_set_uiMode == null) {" +
            "    throw new openfl.errors.Error('Warning: Can not set `uiMode = ' + mode +'` before calling `initUI`');" +
            "  }" +
            "  if (mode != uiMode) {" +
            "    _set_uiMode(mode);" +
            "     uiMode = mode;" +
            "  }" +
            "  return mode;" +
            "}", xmlPos);

        //extract function
        var fun : Function = switch(dummy.expr){
            case EFunction(_,f) : f;
            default: null;
        }

        builder.addMember({
            pos    : xmlPos,
            name   : "set_uiMode",
            kind   : FFun({
                ret    : fun.ret,
                expr   : fun.expr,
                args   : fun.args
            })
        });

        //add modes code to an inner function (in initUI) and set _set_uiMode = that function
        var code = "this._set_uiMode = function(uiNewMode: Int) { switch(uiNewMode) {";

        var defaultMode: String = null;
        for (node in caseNode.elements()) {
            var modeName = node.nodeName;
            if (node.get("default") == "true") {
                defaultMode = modeName;
            }
            code += 'case UI_$modeName:';
            
            for (child in node.elements()) {
                switch(child.nodeName) {
                    case "this":
                        code += attr2Haxe(child, "this", Context.getLocalType());

                    case "in":
                        for(varName in child.get("var").split(",")) {
                            code += processModeFor(child, varName);
                        }

                    case name if (name.startsWith("this.")):
                        code += processFieldAccessNode(child, "this", Context.getLocalType());

                    case varName:
                        code += processModeFor(child, varName); //"in.".length == 3
                }
            }
        }
        
        code += "default: throw new openfl.errors.ArgumentError('This TinyUI view do not have mode <' + uiNewMode + '>');}}";
        if (defaultMode != null) {
            code += 'this.uiMode = UI_$defaultMode;';
        }

        return code;
    }
    
    function addInitCode(code: String): Void {
        //get initUI function name and arguments
        var fnName = xml.get("function");
        var args = "";
        if (fnName == null || fnName.trim() == "") {
            fnName = "initUI"; //default is "initUI()"
        } else {
            var i = fnName.indexOf("(");
            if (i == -1) {
                if (fnName.indexOf(":") != -1) { //ex: "w: Int, h: Int"
                    args = fnName;
                    fnName = "initUI";
                }//else, ex: "new", then do nothing
            } else { //ex: "new ( w: Int) | "new()"
                args = fnName.substring(i + 1, fnName.length - 1).ltrim();
                fnName = fnName.substr(0, i).rtrim();
            }
        }

        //generate dummy function to extract expressions
        function getDummyFn(): Function {
            var dummy : Expr = try {
                Context.parse('function ($args) { $code }', xmlPos);
            } catch (e: Dynamic) {
                neko.Lib.rethrow('There are some error when parse the code generated from xml.\nError: $e\nCode:\n$code');
            }

            //extract function
            return switch(dummy.expr){
                case EFunction(_,f) : f;
                default: null;
            }
        }

        if (fnName == "new") {
            var fun = getDummyFn();
            var ctor = builder.getConstructor();
            for (a in fun.args) {
                ctor.addArg(a.name, a.type, a.value, a.opt);
            }
            switch fun.expr {
                case {expr: EBlock(exprs)}:
                    for(e in exprs) ctor.addStatement(e);
                case e:
                    ctor.addStatement(e);
            }
        } else {
            if (builder.hasSuperField(fnName)) {
                var argNames = args.split(",")
                    .map(function(s) return s.substr(0, s.indexOf(":")))
                    .join(",");
                code = 'super.$fnName($argNames);' + code;
            }
            var fun = getDummyFn();
            builder.addMember({
                pos    : xmlPos,
                name   : fnName,
                access : [APublic],
                kind   : FFun({
                    ret    : null,
                    expr   : fun.expr,
                    args   : fun.args
                })
            });
        }
    }
    
    /** Note: current impl is not correct if there are >1 building classes in one module (file)
     * (in haxe, a .hx file is corresponds to a module) */
    function saveCode() {
        if (genCodeDir == null) {
            return;
        }
        var tpath: {pack : Array<String>, name : String} = Context.getLocalClass().get();

        //1. calculate the path of the file we need to save, and create its parent directory if not exists
        inline function prepareDestFile(): String {
            var saveDir = genCodeDir + tpath.dirPath();
            if (!FileSystem.exists(saveDir)) {
                FileSystem.createDirectory(saveDir);
            }
            return saveDir + "/" + TinyUIPlugin.removeGenSuffix(tpath.name) + ".hx";
        }
        var saveFile = prepareDestFile();

        //2. Get content of building file. We will save this content and the generated fields to the saveFile
        inline function getContent(): String {
            //genCodeDir is delete in method `init`.
            //saveFile exist here when it contain multiple building class
            var file = FileSystem.exists(saveFile)?
                saveFile : builder.target.pos.getInfos().file;
            return File.getContent(file);
        }
        var content = getContent();

        //3. find index in content that we will insert the generated code
        inline function getCodeGenIdx(): Int {
            var className = tpath.name;
            if (TinyUIPlugin.isGenSuffix(className)) {
                var old = className;
                className = TinyUIPlugin.removeGenSuffix(old);
                content = content.replace(old, className);
            }
            var reg = new EReg(".*class\\s+" + className + "\\s+extends\\s+[^{]*{", "g");
            reg.match(content);
            var matchedPos = reg.matchedPos();
            return matchedPos.pos + matchedPos.len;
        }
        var codeGenIdx = getCodeGenIdx();
        
        //4. Generate code
        var hasCtor = Context.getBuildFields()
            .exists(function(f) return f.name == "new");
        var fields = builder.iterator()
            .skip(Context.getBuildFields().length - (hasCtor? 1 : 0))
            .list();
        if (! hasCtor && builder.hasConstructor()) {
            fields.push(builder.getConstructor().toHaxe());
        }
        var code = fields.map(function(f: Field) {
            var s = new Printer().printField(f);
            return switch(f.kind) {
                case FVar(_) | FProp(_): s + ";";
                case _: s;
            }
        }).join("\n");
        
        //5. merge code
        var buf = new StringBuf();
        buf.addSub(content, 0, codeGenIdx);
        buf.add(CodeGenBegin);
        buf.add(code.replace("\n", "\n\t"));
        buf.add(CodeGenEnd);
        buf.addSub(content, codeGenIdx);
        
        //6. Save file
        File.saveContent(saveFile, buf.toString());
    }
}

private typedef MyClassField = {
    var type : Type;
    var isVar: Bool;
}
#end
