import openfl.display.Sprite;

class Main extends Sprite {
    public function new() {
        super();
        new UI01Empty();
        new UI02FieldAttr();
        new UI03ThisNode();
        new UI04LocalVar();
        new UI05InitUIArgs();
        new UI06ViewItem();
        new UI07DeclareVar();
        new UI08ItemFieldNode();
        addChild(new UI09FunctionNode());

        var v10 = new UI10NewExpression();
        addChildAt(v10, 0);
        v10.initUI();

        new UI11NestedItems();

        addChild(new UI12ForLoop());
    }
}
