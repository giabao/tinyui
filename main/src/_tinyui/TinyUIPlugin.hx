package _tinyui;

import haxe.CallStack;
import neko.Lib.println;
import sys.io.File;
import sys.FileSystem;
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;

using _tinyui.Tools;
using tink.MacroApi;
using StringTools;
using com.sandinh.core.LambdaEx;

/** This class is similar to tink.syntaxhub.FrontendContext, used to on-demand create a haxe type from xml ui file.
  * We cannot directly use FrontendPlugin. see comment in `onTypeNotFound` method. */
class TinyUIPlugin {
    /** When a type not found and there is a .xml file with exactly name & path as the not found type
      * then we will do the following steps:
      * 1. save a .hx impl class file with `@:tinyui("<xml-file>")` meta to this dir.
      *     the .hx impl class (and file) has diferrent name than the not-found-type (= name of the type + `GenSuffix`)
      * 2. return an alias to the impl class. */
    static inline var prebuildCodeDir = "bin/tinyui/";
    static inline var GenSuffix = "_ui_gen";
    static var genTypePrefix: String;

    public static inline function isGenSuffix(s: String) return s.endsWith(GenSuffix);
    public static function removeGenSuffix(s: String) {
        return isGenSuffix(s)? s.substr(0, s.length - GenSuffix.length) : s;
    }

    /* delete the prebuildCodeDir dir and register Context.onTypeNotFound */
    public static function init(genTypePrefix: String) {
        Compiler.addClassPath(prebuildCodeDir);
        prebuildCodeDir.delDirRecursive();
        Context.onTypeNotFound(onTypeNotFound);
        TinyUIPlugin.genTypePrefix = genTypePrefix;
    }

    /** @param name the not-found-type, ex "foo.Bar" */
    static function onTypeNotFound(name: String): TypeDefinition try {
        if (! name.startsWith(genTypePrefix)) return null;

        var ctx = name.asTypePath();
        //Note: if we define the impl class named "foo.__impl.Bar" as in tink.syntaxhub.FrontendContext:
        //var actual = {name: ctx.name, pack: ctx.pack.concat(['__impl'])};
        //Then compiling will fail.
        //But define the impl class named "foo.Bar__impl" is fine!
        //Don't know why :D
        var actual: TypePath = {name: ctx.name + GenSuffix, pack: ctx.pack};

        for (cp in Context.getClassPath()) {
            var xmlFile = cp + ctx.filePath() + ".xml";
            if (FileSystem.exists(xmlFile)) {
                genPrebuildCode(xmlFile, actual);
                return {
                    pack: ctx.pack,
                    name: ctx.name,
                    pos: Context.currentPos(),
                    fields: [],
                    kind: TDAlias(actual.fqdn().asComplexType())
                }
            }
        }

        return null;
    } catch(e: Dynamic) {
        println('ERROR! tinyui build failed: $e\n' + CallStack.toString(CallStack.exceptionStack()));
        return null;
    }

    static function genPrebuildCode(xmlFile: String, ctx: TypePath): Void {
        function hxFile(): String {
            var saveDir = prebuildCodeDir + ctx.dirPath();
            if (!FileSystem.exists(saveDir)) {
                FileSystem.createDirectory(saveDir);
            }
            return saveDir + "/" + ctx.name + ".hx";
        }

        var code = "package " + ctx.pack.join(".") + ";\n\n";

        function addImport(node: Xml) {
            var mode = node.nodeName;
            for(a in node.attributes()) {
                for(name in node.get(a).split(",")) {
                    name = name.trim();
                    code += '$mode $a.$name;\n';
                }
            }
        }

        var xml = xmlFile.parseXml();
        xml.elementsNamed("import").iter(addImport);
        code += "\n";
        xml.elementsNamed("using").iter(addImport);

        code += "\n@:build(TinyUI.build('" + xmlFile + "'))\n";
        code += "class " + ctx.name + " extends " + xml.nodeName + " {\n}\n";

        File.saveContent(hxFile(), code);
    }
}
