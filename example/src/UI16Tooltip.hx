import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

using com.sandinh.TipTools;

@:build(TinyUI.build('ui/16-tooltip.xml'))
class UI16Tooltip extends Sprite {
    
    public function new() {
        super();
        initUI();
    }
}
