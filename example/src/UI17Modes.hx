import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import openfl.events.MouseEvent;

using com.sandinh.ui.BitmapTools;

@:build(TinyUI.build('ui/17-modes.xml'))
class UI17Modes extends Sprite {
    public function new() {
        super();
        initUI();
        this.addEventListener(MouseEvent.CLICK, onClick);
    }
    function onClick(e: MouseEvent) {
        this.uiMode = this.uiMode == "m1"? "m2" : "m1";
    }
}
