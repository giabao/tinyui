import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

using com.sandinh.TipTools;

@:build(TinyUI.build('ui/14-tooltip.xml'))
class UI14Tooltip extends Sprite {
    
    public function new() {
        super();
        initUI();
    }
}
