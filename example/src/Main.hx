import openfl.display.Sprite;

import UI01Empty; //import for compiling
import UI02HaxeFieldByXmlAttr;
import UI03ThisNode;
import UI07InitUILocalVar;
import UI04InitUIArgs;
import UI05ViewItem;
import UI06ViewInstanceVar;
import UI08HaxeFieldByChildNode;
import UI09CallMethod;
import UI10NewExpression;
import UI11ExtensionMethod;
import UI12NestedItems;
import UI13ForLoop;
import UI14Layout;
import UI15Tooltip;
import UI16Modes;
import UI17Styles;
import UI18All;
import com.sandinh.XmlOnlyView;

class Main extends Sprite {
    public function new() {
        super();
//        ex1();

//        addChild(new UI15Layout());
//        addChild(new UI16Tooltip());
//        addChild(new UI16Modes());
//        addChild(new UI12UsingExtensionMethod());
        var xml = _tinyui.Xml.parse('<UI fun.=""><addchild foo:=""/></UI>');
        trace(xml);
//        addChild(new UI17Styles());
        var view = new XmlOnlyView();
        addChild(view);
        trace(view.txt.x);
    }

    function ex1() {
        addChild(new UI09CallMethod());

        var v10 = new UI10NewExpression();
        addChildAt(v10, 0);
        v10.initUI();

        addChild(new UI13ForLoop());
    }
}
