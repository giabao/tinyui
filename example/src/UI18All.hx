import openfl.text.TextField;
import openfl.display.Shape;
import openfl.display.Bitmap;
import openfl.text.TextFormat;
import openfl.display.Sprite;

using com.sandinh.ui.BitmapTools;
using com.sandinh.TipTools;
using layout.LayoutUtils;

@:build(TinyUI.build('ui/18-all.xml'))
class UI18All extends Sprite {
    public function new() {
        super();
        initUI(10, 20);
    }
    function simpleMethod(msg: String){
        trace(msg);
    }
    function myMethod(i1: Int, msg: String){ }
    function complexMethod(i1: Int, tf: TextFormat, i2: Int){ }
    function methodCreateSprite(): Sprite {
        return new Sprite();
    }
}
