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
using StringTools;
using TinyUI.Tools;
using haxe.macro.TypeTools;
using haxe.macro.MacroStringTools;

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
        var xml: Xml;
        try {
            xml = Xml.parse(File.getContent(xmlFile)).firstElement();
        } catch(e: Dynamic) {
            Context.fatalError('Can NOT parse $xmlFile, $e', Context.currentPos());
        }

        try {
            var tinyUI = new TinyUI(Context.makePosition( { min:0, max:0, file:xmlFile } ));
            return tinyUI.doBuild(xml);
        } catch (e: Dynamic) {
            var msg = 'Error when TinyUI is building xml file $xmlFile\nError: $e\nCallStack:' +
                haxe.CallStack.toString(haxe.CallStack.exceptionStack());
            Context.fatalError(msg, Context.currentPos());
            return null;
        }
    }

    /** Position point to the xml file. we store this in a class var for convenient */
    var xmlPos: Position;
    /** store the buiding fields */
    var buildingFields: Array<Field> = [];
    var localVarNameGen = new LocalVarNameGen();

    function new(xmlPos: Position) {
        this.xmlPos = xmlPos;
    }

    /** See build(String) */
    function doBuild(xml: Xml): Array<Field> {        
        //code for initUI() method
        var code = processNode(xml, "this", NodeCtx.ViewItem);
        
        code += genUIModes(xml);

        buildingFields.push(genInitCode(xml, code));
        
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

    /** extract variables from xml node then convert to haxe code:
      * 1. attributes "new", "var", "function" is ignore.
      * 2. attribute: var.name[:Type]="expresion"
      *   convert to: var name[:Type]= expresion;
      * 3. other attributes: foo.baz="expr"
      *   convert to: $varName.foo.baz = expr; */
    function attr2Haxe(node: Xml, varName: String): String {
        //`for` node's attributes is already processed in method `processNode`
        if (node.nodeName == "for") {
            return "";
        }
        var code = "";
        var fnCallCount = 0;
        for (attr in node.attributes()) {
            switch(attr) {
                //"new" attribute is processed in `processNode` method.
                //"var" attribute of ViewItems is processed in `processNode` method.
                //"function" attribute of root node is processed in `genInitCode` method.
                case "new" | "var" | "function":
                    continue;
                    
                case fnName if (fnName.startsWith("this.")):
                    fnName = fnName.substr(5); //"this.".length == 5
                    if (fnName == "") {
                        Context.error('invalid "this." attribute in ${node.nodeName} node', xmlPos);
                    }
                    
                    fnCallCount++;
                    if (fnCallCount == 2) {
                        var msg = 'TinyUI found multi function calls (syntax: "this.fnName") in ${node.nodeName} node. ' +
                            "Note that the order of those callings is un-specified!";
                        Context.warning(msg, xmlPos);
                    }
                    
                    var value = node.get(attr);
                    code += '$varName.$fnName($value);';
                    
                //ex: <Item var.someVar:Float="Math.max(1+2, 4)"..>
                //or: <Item var.someVar="1+2"..>
                case localVarName if (localVarName.startsWith("var.")):
                    localVarName = attr.substr(4); //"var.".length == 4
                    var value = node.get(attr);
                    code += 'var $localVarName = $value;';
                    
                //ex: <Button label.text="'OK'" />    
                case fieldName:
                    var value = node.get(attr);
                    code += '$varName.$attr = $value;';
                    
            }
        }
        return code;
    }
    
    /** We pass arguments to the function by adding attributes and/or child nodes to the this.fnName node.
     * Note that, when declare >1 attributes, we need add `.number` to the attribute names to ordering the arguments.
     * This method extract the number (if any) from attribute name.
     * Also note: We can NOT use declared order of attributes because Xml.attributes() will not preserved the order. */
    static function dotOrder(s: String): Null<Int> {
        var i = s.indexOf(".");
        return i == -1? null : Std.parseInt(s.substr(i + 1));
    }
    function getFnNodeArgs(node: Xml): Array<String> {
        var args: Array<String> = node.attributes().array();
        if (args.length > 1) {
            for (a in args) {
                if (dotOrder(a) == null) {
                    Context.error('argument $a when calling function in `this.fnName` node - which have >1 attributes - is not in format argName.order', xmlPos);
                }
            }
            args.sort(function(a, b) return dotOrder(a) - dotOrder(b));
        }
        return args.map(node.get);
    }
    
    /**Process <this.> node
     * each attribute will be a function name, with only one argument - that is the value of attribute.
     * ex: <Button><this. setStyle="'icon', myIcon" /></Button>
     * children nodes are ignored.
     * 
     * @return code */
    static function processNodeAsMultiFnCall(node: Xml, varName: String): String {
        var code = "";
        for (attr in node.attributes()) {
            var value = node.get(attr);
            code += '$varName.$attr($value);';
        }
        return code;
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
                    
                case s if(s.startsWith("this.")):
                    Context.error('Invalid node [$s] of this.$fnName node!', xmlPos);

                //if `node` is `this.$fnName` node then `child` is className of a fnName's argument
                case childClassName:
                    var childVarName = localVarNameGen.next(childClassName);
                    var tpe = Context.getType(childClassName);
                    var newExpr = getNewExpr(child, tpe);
                    code += 'var $childVarName = $newExpr;';
                    code += processNode(child, childVarName, NodeCtx.Field(tpe));
                    args.push(childVarName);
            }
        }
        
        return code + '$varName.$fnName(' + args.join(",") + ");";
    }
    
    /**Process node that declare a view item.
     * each View Item node has `var` attribute will be generated to a haxe field.
     * @return code */
    function processViewItemNode(node: Xml, className: String, varName: String): String {
        var code = "";
        
        //child variable name or field name of view class
        var childVarName = node.get("var");
        var tpe = Context.getType(className);
        var newExpr = getNewExpr(node, tpe);
        //should we declare an class instance var field for this xml node
        if (varName == "this" && childVarName != null && !childVarName.startsWith("#")) {
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
            //ex: <Button var="#myLocalVar" />
            childVarName = childVarName != null? childVarName.substr(1) : localVarNameGen.next(className);
            code += 'var $childVarName = $newExpr;';
        }

        var nextCtx = node.nodeName.startsWith("in.")? NodeCtx.ViewItem : NodeCtx.Field(tpe);
        code += processNode(node, childVarName, nextCtx);

        return code + '$varName.addChild($childVarName);';
    }
    
    /** loop throught xml node recursively and generate haxe code for initUI function.
     * This method also push Fields to `buildingFields` if ctx is ViewItem and the ViewItem node has `var` attribute.
     * @param node - the current xml node we are processing when looping.
     * @param varName - the variable name corresponding to the current node.
     *        for root node, varName is "this".
     *        for other nodes, varName maybe a field name or an initUI local variable generated by `LocalVarNameGen`
     * @param ctx - see doc of NodeCtx enum */
    function processNode(node: Xml, varName: String, ctx: NodeCtx): String {
        //1. process node's attributes
        var code = attr2Haxe(node, varName);
        
        //2. process node's elements
        for (child in node.elements()) {
            switch [child.nodeName, ctx] {
                //ex: <Sprite><this x="1+2" y="3" /></Sprite>
                //children nodes are ignored
                case ["this", _]:
                    code += attr2Haxe(child, varName);
                    
                case ["this.", _]:
                    code += processNodeAsMultiFnCall(child, varName);
                
                case [fnName, _] if (fnName.startsWith("this.")):
                    code += processNodeAsOneFnCall(child, varName);

                case ["for", NodeCtx.ViewItem]:
                    var attrs = child.attributes();
                    var iterVar = attrs.next();
                    if (attrs.hasNext()) {
                        Context.warning("`for` node must has only one attribute", xmlPos);
                    }
                    var iter = child.get(iterVar);
                    code += 'for ($iterVar in $iter) {';
                    code += processNode(child, varName, NodeCtx.ViewItem);
                    code += '}';

                case [modeName, NodeCtx.ViewItem] if (modeName.startsWith("mode.")):
                    //will be process later in `genUIMode` method
                    
                case [group, NodeCtx.ViewItem] if (group.startsWith("in.")):
                    var className = group.substr(3); //"in.".length == 3
                    if (className == "") className = "openfl.display.DisplayObjectContainer";
                    code += processViewItemNode(child, className, varName);

                //if `node` is root node (map to View class) then `child` is className of a View Item
                case [className, NodeCtx.ViewItem]:
                    code += processViewItemNode(child, className, varName);
                    
                case [fieldName, NodeCtx.Field(tpe)]:
                    //FIXME if tpe is not a ClassType?
                    var field = tpe.getClass().findField(fieldName);
                    if (field == null) {
                        Context.fatalError('Can not find field `$fieldName` in class $tpe', xmlPos);
                    }
                    tpe = field.type;
                    var baseType = tpe.baseType();
                    var childVarName = localVarNameGen.next(baseType.name);
                    var newExpr = getNewExpr(child, tpe);
                    code += 'var $childVarName = $newExpr;';

                    code += processNode(child, childVarName, NodeCtx.Field(tpe));
                    code += '$varName.$fieldName = $childVarName;';
            }
        }
        
        return code;
    }

    /** return true if node has name startsWith "mode." */
    static inline function isModeNode(node: Xml) return node.nodeName.startsWith("mode.");

    /** extract mode name from node. This method NOT check `node` isModeNode */
    static inline function getModeName(node: Xml) return node.nodeName.substr(5); //"mode.".length == 5
    
    /**push `public static inline var UI_$modeName: Int = ${auto_inc value - start at 0}`
     * for all modeName found in `xml` into buildingField */
    function pushUIModeFields(xml: Xml) {
        function toField(mode: String, value: Int): Field {
            return {
                pos: xmlPos,
                name: 'UI_$mode',
                access: [APublic, AStatic, AInline],
                kind: FVar(macro: Int, Context.parse(Std.string(value), xmlPos))
            }
        }
        var v = 0;
        for (node in xml)
            if (node.nodeType == Element && isModeNode(node))
                buildingFields.push(toField(getModeName(node), v++));
    }
    
    /**Generate code for view mode feature:
     * @see example modes.xml & the generated code for more detail.
     * @param xml The view (root) node
     * @return code
     */
    function genUIModes(xml: Xml): String {
        //if xml don't have mode nodes then return ""
        if (! xml.elements().exists(isModeNode)) return "";
        
        //replace:
        //<mode.xx>
        //  <in var="var1,var2" attrs>..</in>
        //</mode.xx>
        //to:
        //<mode.xx>
        //  <var1 attrs>..</in>
        //  <var2 attrs>..</in>
        //</mode.xx>
        function replaceShortcutNode(node: Xml) {
            if (! isModeNode(node)) return;
            
            for (child in node.elements()) {
                if (child.nodeName == "in") {
                    node.removeChild(child);
                    for (varName in child.get("var").split(",")) {
                       node.addChild(child.cloneXml(varName, "var"));
                    }
                }
            }
        }
        
        //replaceShortcutNode for all mode nodes 
        for (node in xml.elements()) replaceShortcutNode(node);
        
        //find ViewItem node has name == varName or "#" + varName
        inline function viewItemByVar(varName: String): Null<Xml>
            return xml.elements().find(
                function(node) {
                    var v = node.get("var");
                    return v == varName || v == "#" + varName;
                }
            );
        
        pushUIModeFields(xml);

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
        for (node in xml.elements()) {
            if (! isModeNode(node)) {
                continue;
            }
            var modeName = getModeName(node);
            if (node.get("default") == "true") {
                defaultMode = modeName;
            }
            code += 'case UI_$modeName:';
            
            for (child in node.elements()) {
                switch(child.nodeName) {
                    case "this":
                        code += attr2Haxe(child, "this");
                    
                    case "this.":
                        code += processNodeAsMultiFnCall(child, "this");
                    
                    case fnName if (fnName.startsWith("this.")):
                        code += processNodeAsOneFnCall(child, "this");
                        
                    case varName:
                        //similar to: code += processViewItemNode(child, className);
                        //but do not process: addChild, `new` expression, declaring var field.
                        var itemNode = viewItemByVar(varName);
                        if (itemNode == null) {
                            Context.error('View Item for variable name "$varName" not found. TinyUI can not parse ui mode <mode.$modeName>', xmlPos);
                        }
                        if (itemNode.get("var").charAt(0) != "#") {
                            varName = 'this.$varName';
                        }
                        var tpe = Context.getType(itemNode.nodeName);
                        code += processNode(child, varName, NodeCtx.Field(tpe));
                }
            }
        }
        
        code += "default: throw new openfl.errors.ArgumentError('This TinyUI view do not have mode <' + uiNewMode + '>');}}";
        if (defaultMode != null) {
            code += 'this.uiMode = UI_$defaultMode;';
        }

        return code;
    }
    
    function genInitCode(xml: Xml, code: String): Field {
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
    /** Creates an Array from Iterator `it` */
    public static function array<A>( it : Iterator<A> ) : Array<A> {
        var a = new Array<A>();
        while(it.hasNext())
            a.push(it.next());
        return a;
    }
    
    /**
        Tells if `it` contains an element for which `f` is true.

        This function returns true as soon as an element is found for which a
        call to `f` returns true.

        If no such element is found, the result is false.

        If `f` is null, the result is unspecified.
    **/
    public static function exists<A>( it : Iterator<A>, f : A -> Bool ): Bool {
        while (it.hasNext())
            if (f(it.next()))
                return true;
        return false;
    }
    
    /**
        Returns the first element of `it` for which `f` is true.

        This function returns as soon as an element is found for which a call to
        `f` returns true.

        If no such element is found, the result is null.

        If `f` is null, the result is unspecified.
    **/
    public static function find<T>( it : Iterator<T>, f : T -> Bool ) : Null<T> {
        while (it.hasNext()) {
            var v = it.next();
            if(f(v)) return v;
        }
        return null;
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

/** Context of xml node in the ui (.xml) file */
private enum NodeCtx {
    /** ViewItem is for direct child nodes of View Container (root node) or View Group (<in.$groupClassName> node).
      * ex: the Bitmap node in: <UI><Bitmap ../></UI>. Here, nodeName is the class name.
      * or: <UI><in.Sprite><Bitmap ../></in.Sprite></UI> */
    ViewItem;
    
    /** Field(tpe): is for field node that declare a field of Type `tpe`.
      * ex: the defaultTextFormat node in: <UI><TextField><defaultTextFormat .. /></TextField></UI>
      * Here, nodeName is the property name and tpe is TextField */
    Field(tpe: Type);
}

#end
