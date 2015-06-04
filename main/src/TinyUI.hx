#if macro
import haxe.macro.Type;
import haxe.macro.Type.TVar;
import haxe.macro.Type.TType;
import haxe.macro.Printer;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.ds.StringMap;
import sys.io.File;
import sys.FileSystem;
import _tinyui.Xml;

using Lambda;
using com.sandinh.core.LambdaEx;
using StringTools;
using TinyUI.Tools;
using haxe.macro.Tools;

class TinyUI {
    static var genCodeDir: String = null;
    static inline var CodeGenBegin = "\n\t//++++++++++ code gen by tinyui ++++++++++//\n\t";
    static inline var CodeGenEnd = "\n\t//---------- code gen by tinyui ----------//\n";

    /** Set directory to save generated code to. Should be called in */
    macro public static function saveCodeTo(dir: String): Void {
        if (! dir.endsWith("/")) dir = dir + "/";
        genCodeDir = dir;
    }

    /** Inject fields declared in `xmlFile` and generate `initUI()` function for the macro building class.
      * See test/some-view.xml & test/SomeView.hx for usage. */
    macro public static function build(xmlFile: String): Array<Field> {
        var xml = Tools.parseXml(xmlFile);
        try {
            var xmlPos = Context.makePosition( { min:0, max:0, file:xmlFile } );
            var tinyUI = new TinyUI(xmlPos, xml);
            return tinyUI.doBuild();
        } catch (e: Dynamic) {
            var msg = 'Error when TinyUI is building xml file $xmlFile\nError: $e\nCallStack:' +
                haxe.CallStack.toString(haxe.CallStack.exceptionStack());
            Context.fatalError(msg, Context.currentPos());
            return null;
        }
    }

    /** Position point to the xml file. we store this in a class var for convenient */
    var xmlPos: Position;
    var xml: Xml;
    /** store the buiding fields */
    var buildingFields: Array<Field> = [];
    var localVarNameGen = new LocalVarNameGen();

    function new(xmlPos: Position, xml: Xml) {
        this.xmlPos = xmlPos;
        this.xml = xml;
    }

    /** See build(String) */
    function doBuild(): Array<Field> {
        //code for initUI() method
        var code = processNode(xml, "this", Context.getLocalType());
        
        code += genUIModes();

        buildingFields.push(genInitCode(code));
        
        saveCode(buildingFields);

        return Context.getBuildFields().concat(buildingFields);
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
            "new " + tpe.clsFqdn() + "(" + expr.substr(1) + ")";
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
                //"var", "var.field" attribute is processed in `processNode` method.
                //"function" attribute of root node is processed in `genInitCode` method.
                case "new" | "var" | "var.field" | "function":
                    continue;
                case "class":
                    var styleXml = Styles.getStyleXml(this.xml, node);
                    code += processNode(styleXml, varName, tpe);
                //ex: <Button label.text="'OK'" />
                //or: <TextField setTextFormat="myFmt,1" />
                default:
                    var value = node.get(attr);
                    var field = findDotField(tpe, attr);
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
            //1. check if name is declared in .xml ui file by attribute "var.field"
            var node = this.xml.elements()
                .find(function(child) return child.get("var.field") == name);
            if (node != null) {
                var tpeName = node.nodeName.startsWith("var.") ?
                    node.nodeName.substr(4) : node.nodeName; //"var.".length == 4
                field = {type: Context.getType(tpeName), isVar: true};
            } else {
                //2. check if name is declared in building class
                var buildField = Context.getBuildFields()
                    .find(function(f) return f.name == name);
                if (buildField != null) {
                    field = switch(buildField.kind) {
                        case FVar(t, e) | FProp(_, _, t, e):
                            var tpeOfField = t != null?
                                t.toType() : Context.typeof(e);
                            {type: tpeOfField, isVar: true};
                        case FFun(_):
                            {type: null, isVar: false};
                    }
                }
            }
        }
        if (field == null || i == -1) return field;

        return field.isVar? findDotField(field.type, dottedName.substr(i + 1)) : null;
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
        //ex: <Button var="this.myLocalVar" />
        if (varName == "this" && node.exists("var.field")) {
            childVarName = node.get("var.field");
            var baseType = tpe.baseType();
            if (baseType == null) {
                Context.error('Can not find type $className', xmlPos);
            }
            buildingFields.push({
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
            childVarName = node.get("var");
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
     * This method also push Fields to `buildingFields` if ctx is ViewItem and the ViewItem node has `var` attribute.
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

                case ["class", _]:
                    //process in attr2Haxe

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
     * for all modeName found in `caseNode` into buildingField */
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
            buildingFields.push(toField(node.nodeName, v++));
    }

    /** similar to: code += processVarOrViewItemNode(child);
      * but do not process: addChild, `new` expression, declaring var field.
      * @return code */
    function processModeFor(child: Xml, varName: String): String {
        var itemNode = xml.elements().find(
            function (node) return varName == node.get("var") || varName == node.get("var.field")
        );
        if (itemNode == null) {
            throw 'View Item for variable name "$varName" not found. ' +
                'TinyUI can not parse ui mode <${child.parent.nodeName}>';
        }
        if (itemNode.exists("var.field")) {
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
        buildingFields.push({
            pos : xmlPos,
            name : "uiMode",
            access : [APublic],
            kind : FProp("default", "set", macro: Int, {
                expr: EConst(CInt("-1")),
                pos: xmlPos
            })
        });
        
        //var _set_uiMode: Int -> Void;
        buildingFields.push({
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
        
        buildingFields.push({
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
    
    function genInitCode(code: String): Field {
        //get initUI arguments, ex: <UI function="w: Int, h: Int" ..>
        var args: String = xml.get("function");
        if (args == null) args = "";

        var isOverride = Context.getLocalClass().get().findField("initUI") != null;
            
        if (isOverride) {
            var argNames: String = args.split(",")
                .map(function(s) return s.substr(0, s.indexOf(":")))
                .join(",");
            code = 'super.initUI($argNames);' + code;
        }
        
        //generate dummy function to extract expressions
        var dummy : Expr = try {
            Context.parse('function ($args) { $code }', xmlPos);
        } catch (e: Dynamic) {
            Context.error('There are some error when parse the code generated from xml.\nError: $e\nCode:\n$code', xmlPos);
        }

        //extract function
        var fun : Function = switch(dummy.expr){
            case EFunction(_,f) : f;
            default: null;
        }
        
        return {
            pos    : xmlPos,
            name   : "initUI",
            access : isOverride? [AOverride, APublic] : [APublic],
            kind   : FFun({
                ret    : null,
                expr   : fun.expr,
                args   : fun.args
            })
        };
    }
    
    /** Note: current impl is not correct if there are >1 building classes in one module (file)
     * (in haxe, a .hx file is corresponds to a module) */
    function saveCode(fields: Array<Field>) {
        if (genCodeDir == null) {
            return;
        }
        //1. calculate the path of the file we need to save, and create its parent directory if not exists
        var module = Context.getLocalModule().replace(".", "/");
        var saveFile = genCodeDir + module;
        var saveDir = saveFile.substr(0, saveFile.lastIndexOf("/"));
        if (!FileSystem.exists(saveDir)) {
            FileSystem.createDirectory(saveDir);
        }

        //2. Get content of building file. We will save this content and the generated fields to the saveFile
        var pos = Context.getPosInfos(Context.currentPos());
        var content = File.getContent(pos.file);
        
        //3. find index in content that we will insert the generated code
        var className = Context.getLocalClass().get().name;
        var reg = new EReg(".*class\\s+" + className + "[^{]*{", "g");
        var subLenToMatch = Math.min(content.length - pos.max, 200);
        reg.matchSub(content, pos.max, Std.int(subLenToMatch));
        var matchedPos = reg.matchedPos();
        var codeGenIdx = matchedPos.len + matchedPos.pos;
        
        //4. Generate code
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
        buf.add(code.split("\n").join("\n\t"));
        buf.add(CodeGenEnd);
        buf.addSub(content, codeGenIdx);
        
        //6. Save file
        File.saveContent(saveFile + ".hx", buf.toString());
    }
}

class Tools {
    public static function tpeEquals(t1: Type, t2: Type): Bool {
        var b1 = t1.baseType(), b2 = t2.baseType();
        if(b1 == null || b2 == null) return false;
        return b1.name == b2.name && b1.module == b2.module && b1.pack.join('') == b2.pack.join('');
    }
    public static function baseType(tpe: Type): Null<BaseType> {
        return switch(tpe) {
            case TEnum(t, _): t.get();
            case TInst(t, _): t.get();
            case TType(t, _): t.get();
            case TAbstract(t, _): t.get();
            case _: null;
        }
    }

    public static inline function isVar(field: ClassField): Bool
        return field == null? false : switch(field.kind) {
            case FVar(_): true;
            default: false;
        }

    /**return the full pack + name of the Class `tpe`
     * tpe must represent a class. see haxe.macro.TypeTools.getClass */
    public static function clsFqdn(tpe: Type): String {
        var cls: ClassType = tpe.getClass();
        return cls.pack.toDotPath(cls.name);
    }

    public static function cloneXml(node: Xml, newName: String = null, excludeAttr: String = null): Xml {
        var ret = Xml.createElement(newName == null? node.nodeName : newName);
        for (a in node.attributes())
            if (a != excludeAttr)
                ret.set(a, node.get(a));
        node.iter(function(child) ret.addChild(cloneXml(child)));
        return ret;
    }

    public static function parseXml(xmlFile: String): Xml {
        return try {
             Xml.parse(File.getContent(xmlFile)).firstElement();
        } catch(e: Dynamic) {
            Context.fatalError('Can NOT parse $xmlFile, $e', Context.currentPos());
        }
    }

    public static inline function hasElemNamed(xml: Xml, n: String): Bool {
        return xml.elementsNamed(n).hasNext();
    }
    public static function namedElemIterable(x: Xml, n: String) return
        [for (child in x) if (child.nodeType == Element && child.nodeName == n) child];
}

private typedef MyClassField = {
    var type : Type;
    var isVar: Bool;
}

/** map from className to an auto-inc value
 * this is used to declare local variable names */
private class LocalVarNameGen {
    var localVarNum = new StringMap<Int>();
    
    public function new() { }
    
    public function next(className: String): String {
        var i = className.lastIndexOf(".");
        //take only real class name, not fqdn
        className = i == -1? className : className.substr(i + 1);

        var i = localVarNum.get(className);
        if (i == null) {
            i = 0;
        }
        localVarNum.set(className, ++i);
        return '__ui$className$i';
    }
}

private class Styles {
    static function resolveStyleNode(xml: Xml, styleId: String, isExtStyleFile: Bool = false): Xml {
        function fromNode(x: Xml) return x.namedElemIterable(styleId);

        function fromImported(classNode: Xml): Xml {
            var extStyleFile = classNode.get("import");
            return extStyleFile == null?
                null : resolveStyleNode(Tools.parseXml(extStyleFile), styleId, true);
        }

        var classNodes = isExtStyleFile? [xml] : xml.namedElemIterable("class");

        var matchedStyles = classNodes.flatMap(fromNode);
        if (matchedStyles.isEmpty()) {
            matchedStyles = classNodes.list().map(fromImported)
                .filter(function(x) return x != null);
        }
        if (matchedStyles.isEmpty()) {
            throw 'Not found style $styleId';
        }
        if (matchedStyles.length > 1) {
            throw 'found multiple style $styleId';
        }
        return matchedStyles.first();
    }

    static function mergeStyle(xml: Xml, styleId: String, ret: Xml, instanceNode: Xml, mergeToStyle: String = null) {
        var styleNode = resolveStyleNode(xml, styleId);

        //clone attributes except "extends"
        //also check to not re-set the existed attr
        for(a in styleNode.attributes())
            if (a != "extends")
                if (ret.get(a) == null && instanceNode.get(a) == null) {
                    ret.set(a, styleNode.get(a));
                } else {
                    var msg = 'att $a in style $styleId is overrided when merging style $mergeToStyle!';
                    if (instanceNode.get(a) != null) {
                        msg += " (the instance node redefine this attribute)";
                    }
                    Context.warning(msg, Context.currentPos());
                }

        //clone children
        //also check to not re-add the existed child with same nodeName
        for(c in styleNode.elements())
            if (ret.hasElemNamed(c.nodeName) || instanceNode.hasElemNamed(c.nodeName)) {
                var msg = 'child ${c.nodeName} in style $styleId is overrided when merging style $mergeToStyle!';
                if (instanceNode.hasElemNamed(c.nodeName)) {
                    msg += " (the instance node redefine this child node)";
                }
                Context.warning(msg, Context.currentPos());
            } else {
                ret.addChild(c.cloneXml());
            }

        var baseStyleIds = styleNode.get("extends");
        if (baseStyleIds != null)
            for(baseStyleId in baseStyleIds.split(","))
                mergeStyle(xml, baseStyleId, ret, instanceNode, styleId);
    }

    public static function getStyleXml(xml: Xml, node: Xml): Xml {
        var styleId = node.get("class");
        if(styleId == null) {
            throw 'node do not have `class` attribute! $node';
        }
        var ret = Xml.createElement("style");
        mergeStyle(xml, styleId, ret, node);
        return ret;
    }
}
#end
