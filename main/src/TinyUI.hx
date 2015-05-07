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

using Lambda;
using StringTools;
using TinyUI.Tools;
using haxe.macro.TypeTools;
using haxe.macro.MacroStringTools;

//TODO suport debuging in generated code with Position info
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
        } catch(e: Dynamic) {
            Sys.println(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
            Context.error(Std.string(e), Context.currentPos());
            return null;
        }
    }

    /** Position point to the xml file. we store this in a class var for convenient */
    var xmlPos: Position;
    /** Used to store the buiding fields */
	var buildingFields: Array<Field> = [];

    function new(xmlPos: Position) {
        this.xmlPos = xmlPos;
    }

    /** See build(String) */
    function doBuild(xml: Xml): Array<Field> {        
        //code for initUI() method
        var code = classNode2Haxe(xml, "this", NodeCtx.ViewItem);

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
        function className(): String {
            var cls: ClassType = tpe.getClass();
            return cls.pack.toDotPath(cls.name);
        }

		var newExpr: String = node.get("new");
		if (newExpr == null) {
			return "new " + className() + "()";
		} 
		newExpr = newExpr.trim();
		if (newExpr.charAt(0) == ':') {
            return "new " + className() + "(" + newExpr.substr(1) + ")";
		}
		return newExpr;
	}
    
	/** extract variables from xml node then convert to haxe code:
	  * 1. attributes "new", "var", "function" is ignore.
	  * 2. attribute: var.name[:Type]="expresion"
	  *   convert to: var name[:Type]= expresion;
	  * 3. other attributes: foo.baz="expr"
	  *   convert to: $varName.foo.baz = expr; */
    function attr2Haxe(node: Xml, varName: String): String {
        var code = "";
        for (attr in node.attributes()) {
            if (attr == "new" || attr == "var" || attr == "function") {
                continue;
            }
            var value = node.get(attr);
            if (attr.startsWith("var.")) {
                var localVarName = attr.substr(4); //"var.".length == 4
                //ex: <Item var.someVar:Float="Math.max(1+2, 4)"..>
                //or: <Item var.someVar="1+2"..>
                code += 'var $localVarName = $value;';
            } else {
				//ex: <Button label.text="'OK'" />
                code += '$varName.$attr = $value;';
            }
        }
        return code;
    }
	
    /** We pass arguments to the function by adding attributes and/or child nodes to the function.fnName node.
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
                    Context.error('argument $a in a function.fnName node - which have >1 attributes - is not in format argName.order', xmlPos);
                }
            }
            args.sort(function(a, b) return dotOrder(a) - dotOrder(b));
        }
        return args.map(node.get);
    }
	
    /** loop throught xml node recursively and generate haxe code for initUI function.
     * This method also push Fields to `buildingFields` if ctx is ViewItem and the ViewItem node has `var` attribute.
     * @param node - the current xml node we are processing when looping.
     * @param varName - the variable name corresponding to the current node.
     *        for root node, varName is "this".
     *        for other nodes, varName maybe a field name or an initUI local variable generated by `LocalVarNameGen`
     * @param ctx - see doc of NodeCtx enum */
	function classNode2Haxe(node: Xml, varName: String, ctx: NodeCtx): String {
		//1. process node's attributes
		var code = attr2Haxe(node, varName);
        var localVarNameGen = new LocalVarNameGen();
		
		//2. process node's elements
		for (child in node.elements()) {
            switch [child.nodeName, ctx] {
				//ex: <Sprite><this x="1+2" y="3" /></Sprite>
                //children nodes are ignored
                case ["this", _]:
                    code += attr2Haxe(child, varName);
					
				//each attribute will be a function name, with only one argument - that is the value of attribute.
				//ex: <Button><function setStyle="'icon', myIcon" /></Button>
                //children nodes are ignored
				case ["function", _]:
					for (attr in child.attributes()) {
						var value = child.get(attr);
						code += '$varName.$attr($value);';
					}
                    
				//ex: see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/fl/core/UIComponent.html#setStyle%28%29
				//<Label><function.setStyle style.1="'textFormat'" value.2="new TextFormat('Tahoma', 16)" /></Label>
				
				//ex2:
				//<Label><function.setStyle style="'textFormat'">
				//  <TextFormat font="'Tahoma'" size="16" bold="true" />
				//</function.setStyle></Label>
                case [fnName, _] if (fnName.startsWith("function.")):
                    fnName = fnName.substr(9); //"function.".length == 9
					var args: Array<String> = getFnNodeArgs(child);
					
					for (child2 in child.elements()) {
                        switch(child2.nodeName) {
                            case "this":
                                getFnNodeArgs(child2).iter(args.push);
                                
                            case s if(s == "function" || s.startsWith("function.")):
                                Context.error('Invalid node [$s] of function.$fnName node!', xmlPos);

                            //if `node` is `function.$fnName` node then `child` is className of a fnName's argument
                            case childClassName:
						        var childVarName = localVarNameGen.next(childClassName);
                                var tpe = Context.getType(childClassName);
                                var newExpr = getNewExpr(child2, tpe);
                                code += 'var $childVarName = $newExpr;';
                                code += classNode2Haxe(child2, childVarName, NodeCtx.Field(tpe));
                                args.push(childVarName);
                        }
					}
					
					code += '$varName.$fnName(' + args.join(",") + ");";
				
				//if `node` is root node (map to View class) then `child` is className of a View Item
                //each View Item node has `var` attribute will be generated to a haxa field.
				case [className, NodeCtx.ViewItem]:
                    //child variable name or field name of view class
                    var childVarName: String = child.get("var");
                    var tpe = Context.getType(className);
                    var newExpr = getNewExpr(child, tpe);
                    //should we declare an class instance var field for this xml node
                    if (childVarName != null) {
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
                        childVarName = localVarNameGen.next(className);
                        code += 'var $childVarName = $newExpr;';
                    }

                    code += classNode2Haxe(child, childVarName, NodeCtx.Field(tpe));

                    code += 'this.addChild($childVarName);';

                case [fieldName, NodeCtx.Field(tpe)]:
                    //FIXME if tpe is not a ClassType?
                    tpe = tpe.getClass().findField(fieldName).type;
                    
                    var baseType = tpe.baseType();
                    var childVarName = localVarNameGen.next(baseType.name);
                    var newExpr = getNewExpr(child, tpe);
                    code += 'var $childVarName = $newExpr;';

                    code += classNode2Haxe(child, childVarName, NodeCtx.Field(tpe));
                    code += '$varName.$fieldName = $childVarName;';
			}
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
        var dummy : Expr = Context.parse('function ($args) { $code }', xmlPos);

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
                params : [],
                expr   : fun.expr,
                args   : fun.args,
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
                case FVar(_): s + ";";
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
    public static function array<A>( it : Iterator<A> ) : Array<A> {
		var a = new Array<A>();
		while(it.hasNext())
			a.push(it.next());
		return a;
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
}

/** map from className to an auto-inc value
 * this is used to declare local variable names */
private class LocalVarNameGen {
	var localVarNum = new StringMap<Int>();
	
	public function new() { }
	
	public function next(className: String): String {
		var i = localVarNum.get(className);
		if (i == null) {
			i = 0;
		}
		localVarNum.set(className, ++i);
		return '__ui$className$i';
	}
}

/**
 * Context of xml node in the ui (.xml) file.
 * + ViewItem: is for direct child nodes of root UI node.
 *   ex: the Bitmap node in: <UI><Bitmap ../></UI>
 *   Here, nodeName is the class name.
 * + Field(tpe): is for field node that declare a field in Type `tpe`.
 *   ex: the defaultTextFormat node in: <UI><TextField><defaultTextFormat .. /></TextField></UI>
 *   Here, tpe is openfl.text.TextField
 */
private enum NodeCtx {
    ViewItem;
    Field(tpe: Type);
}

#end
