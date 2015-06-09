package _tinyui;

import haxe.macro.Context;

using _tinyui.Tools;
using Lambda;
using com.sandinh.core.LambdaEx;

class Styles {
    static function resolveStyleNode(xml: Xml, styleId: String, isExtStyleFile: Bool = false): Xml {
        function fromNode(x: Xml) return x.namedElemIterable(styleId);

        function fromImported(classNode: Xml): Xml {
            var extStyleFile = classNode.get("import");
            return extStyleFile == null?
                null : resolveStyleNode(extStyleFile.parseXml(), styleId, true);
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
                ret.addChild(c.clone());
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
