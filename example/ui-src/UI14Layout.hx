import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.display.Bitmap;
import openfl.Assets;
import layout.Direction;

using layout.LayoutUtils;
using com.sandinh.ui.BitmapTools;

@:tinyui('ui/14-layout.xml')
class UI14Layout extends Sprite {
    static inline var PADDING = 5;
    
    public function new() {
        super();
        initUI();
    }
}
