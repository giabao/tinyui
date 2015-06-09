package _tinyui;

import haxe.macro.Context;
import haxe.macro.Type;
import sys.io.File;
import haxe.macro.Type.BaseType;
import sys.FileSystem;

using _tinyui.Tools;
using haxe.macro.Tools;
using Lambda;
using com.sandinh.core.LambdaEx;

class FileSystemEx {
    public static function delDirRecursive(path: String) {
        if (FileSystem.exists(path))
            _delDirRecursive(path);
    }

    /** this method not check path exists & isDirectory */
    static function _delDirRecursive(path: String) {
        for (item in FileSystem.readDirectory(path)) {
            var child = path + '/' + item;
            if (FileSystem.isDirectory(child)) {
                delDirRecursive(child);
            } else {
                FileSystem.deleteFile(child);
            }
        }
        FileSystem.deleteDirectory(path);
    }
}

class TypePathEx {
    public inline static function fqdn(p: {pack : Array<String>, name : String}): String
        return p.pack.concat([p.name]).join(".");

    public inline static function filePath(p: {pack : Array<String>, name : String}): String
        return p.pack.concat([p.name]).join("/");

    public inline static function dirPath(p: {pack : Array<String>, name : String}): String
        return p.pack.join("/");
}

class TypeEx {
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

    /**return the full pack + name of the Class `tpe`
     * tpe must represent a class. see haxe.macro.TypeTools.getClass */
    public static function fqdn(tpe: Type): String {
        var cls: ClassType = tpe.getClass();
        return cls.pack.toDotPath(cls.name);
    }
}

class XmlEx {
    public static function clone(node: Xml, newName: String = null, excludeAttr: String = null): Xml {
        var ret = Xml.createElement(newName == null? node.nodeName : newName);
        for (a in node.attributes())
            if (a != excludeAttr)
                ret.set(a, node.get(a));
        node.iter(function(child) ret.addChild(clone(child)));
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