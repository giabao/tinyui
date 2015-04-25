package com.sandinh.tinyui;
#if macro
import haxe.macro.Type;
import haxe.macro.Type.TVar;
import haxe.macro.Type.TType;
import haxe.macro.Printer;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.File;
import sys.FileSystem;

using Lambda;
using StringTools;

//TODO suport debuging in generated code with Position info
class UIMacro {
    private static var genCodeDir: String = null;
    
    /** Set directory to save generated code to. Should be called in */
    macro public static function saveCodeTo(dir: String): Void {
        if (! dir.endsWith("/")) dir = dir + "/";
        genCodeDir = dir;
    }

    /** Inject fields declared in `xmlFile` and generate `initUI()` function for the macro building class.
      * See test/some-view.xml & test/SomeView.hx for usage. */
    macro public static function build(xmlFile: String): Array<Field> {
        try {
            return new UIMacro(xmlFile).doBuild();
        } catch(e: Dynamic) {
            Sys.println(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
            Context.error(Std.string(e), Context.currentPos());
            return null;
        }
    }

    private var xmlPos: Position;
    private var xml: Xml;

    function new(xmlFile: String) {
        xmlPos = Context.makePosition({min:0, max:0, file:xmlFile});
        try {
            xml = Xml.parse(File.getContent(xmlFile)).firstElement();
        } catch(e: Dynamic) {
            Context.error(e, xmlPos);
        }
    }

    /** See build(String) */
    private function doBuild(): Array<Field> {
        var fields: Array<Field> = [];
        //code for initUI() method
        //generate other fields by parsing xml file
        var code = pushFieldsAndGetInitCode(fields);

        fields.push(genInitCode(code));
        
        saveCode(fields);

        return Context.getBuildFields().concat(fields);
    }

    /**generate haxa fields by parsing xml file then push into `fields` array.
     * Each 1-level xml node has `var` attribute will be generated to a haxa field.
     * This method also generate code for initUI() method.
     * @param fields MUST be prepared before call this function. */
    private function pushFieldsAndGetInitCode(fields: Array<Field>): String {
        var code = "";
        //map from className to an auto-inc value
        //this is used to declare local variable name when xml node has no `var` attribute
        var localVarNum = new Map<String, Int>();
        for (node in xml.elements()) {
            var className: String = node.nodeName;
            var varName: String = node.get("var");
            //should we declare an class instance var field for this xml node
            var hasVar = varName != null;
            if (! hasVar) {
                var i = localVarNum.get(className);
                if (i == null) {
                    i = 0;
                }
                localVarNum.set(className, ++i);
                varName = '__ui$className$i';
            }
            
            if (hasVar) {
                var tpe: BaseType = switch(Context.getType(className)) {
                    case TType(t, _): t.get();
                    case TInst(t, _): t.get();
                    case _: Context.error('Can not find type ${node.nodeName}', xmlPos);
                }
                
                fields.push({
                    pos    : xmlPos,
                    name   : varName,
                    access : [APublic], //TODO support asses, doc, meta?
                    kind   : FVar(TPath({ //TODO support params?
                        name   : tpe.name,
                        pack   : tpe.pack
                    }))
                });
                
                varName = 'this.$varName';
            }
            
            var newExpr: String = node.get("new");
            if (newExpr == null) {
                newExpr = 'new $className()';
            }
            
            code += hasVar?
                '$varName = $newExpr;' :
                'var $varName: $className = $newExpr;';
                
            code += node2Haxe(node, varName);
            code += 'this.addChild($varName);';
        }

        return code;
    }
    
    /** Generate haxe code that set properties for `varName` based on `node` */
    private function node2Haxe(node: Xml, varName: String): String {
        var code = "";
        
        for (attr in node.attributes()) {
            if (attr == "var" || attr == "function" || attr == "new") {
                continue;
            }
            var value = node.get(attr);
            code += '$varName.$attr = $value;';
        }
        
        //map from className to an auto-inc value
        //this is used to declare local variable name when xml node has no `var` attribute
        var localVarNum = new Map<String, Int>();
        for (child in node.elements()) {
            var className: String = child.nodeName;
            
            var parentVar: String = child.get("var");
            var parentFun: String = child.get("function");
            if (parentVar == null && parentFun == null) {
                Context.warning('child node of type $className in node ${node.nodeName} has NO `var` or `function` attribute', xmlPos);
                continue;
            }
            
            var newExpr: String = child.get("new");
            if (newExpr == null) {
                newExpr = 'new $className()';
            }
            
            var i = localVarNum.get(className);
            if (i == null) {
                i = 0;
            }
            localVarNum.set(className, ++i);
            var childVarName = '__ui$className$i';
            //init a new className in a new haxe scope
            code +=
            "{" +
            '   var $childVarName: $className = $newExpr;' +
            node2Haxe(child, childVarName) +
                (parentVar != null?
            '   $varName.$parentVar = $childVarName;' :
            '   $varName.$parentFun($childVarName);') +
            "}";
        }
        
        return code;
    }

    private function genInitCode(code: String): Field {
        //generate dummy function to extract expressions
        var dummy : Expr = Context.parse('function () { $code }', xmlPos);

        //extract expressions
        var eblock : Expr = switch(dummy.expr){
            case EFunction(_,f) : f.expr;
            default: null;
        }
        
        return {
            pos    : xmlPos,
            name   : "initUI",
            access : [APublic], //TODO support asses, doc, meta?
            kind   : FFun({
                ret    : null,
                params : [],
                expr   : eblock,
                args   : [],
            })
        };
    }
    
    /** Note: current impl is not correct if there are >1 building classes in one module (file)
     * (in haxe, a .hx file is corresponds to a module) */
    private function saveCode(fields: Array<Field>) {
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
        var reg = new EReg(".*class\\s+" + className + "[^{]*{.+",  "g");
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
        buf.add(code);
        buf.add(CodeGenEnd);
        buf.addSub(content, codeGenIdx);
        
        //6. Save file
        File.saveContent(saveFile + ".hx", buf.toString());
    }
    
    private static inline var CodeGenBegin = "\n//++++++++++ code gen by tinyui ++++++++++//\n";
    private static inline var CodeGenEnd = "\n//---------- code gen by tinyui ----------//\n";
}

#end