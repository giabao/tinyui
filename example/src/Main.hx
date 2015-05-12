import openfl.display.Sprite;

import UI01Empty; //import for compiling
import UI02FieldAttr;
import UI03ThisNode;
import UI04LocalVar;
import UI05InitUIArgs;
import UI06ViewItem;
import UI07DeclareVar;
import UI08ViewItemLocalVarName;
import UI09ItemFieldNode;
import UI10FunctionNode;
import UI11NewExpression;
import UI12ExtMethod;
import UI13NestedItems;
import UI14ForLoop;
import UI15Layout;
import UI16Tooltip;
import UI17Modes;

class Main extends Sprite {
    public function new() {
        super();
//        ex1();

//        addChild(new UI15Layout());
//        addChild(new UI16Tooltip());
//        addChild(new UI12ExtMethod());
        addChild(new UI17Modes());
    }

    function ex1() {
        addChild(new UI10FunctionNode());

        var v10 = new UI11NewExpression();
        addChildAt(v10, 0);
        v10.initUI();

        addChild(new UI14ForLoop());
    }
}
