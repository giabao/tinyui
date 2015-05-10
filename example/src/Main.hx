import openfl.display.Sprite;

import UI01Empty; //import for compiling
import UI02FieldAttr;
import UI03ThisNode;
import UI04LocalVar;
import UI05InitUIArgs;
import UI06ViewItem;
import UI07DeclareVar;
import UI071ViewItemLocalVarName;
import UI08ItemFieldNode;
import UI11NestedItems;

class Main extends Sprite {
    public function new() {
        super();
//        ex1();
//        ex2();
        addChild(new UI14Tooltip());
    }

    function ex1() {
        addChild(new UI09FunctionNode());

        var v10 = new UI10NewExpression();
        addChildAt(v10, 0);
        v10.initUI();

        addChild(new UI12ForLoop());
    }

    function ex2() {
        addChild(new UI13Layout());
    }
}
