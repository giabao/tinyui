import openfl.display.Sprite;
import openfl.text.TextField;

@:tinyui('ui/13-for-loop.xml')
class UI13ForLoop extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function initUI() {
		for (i in 1 ... 4) {
			var __uiTextField1 = new flash.text.TextField();
			__uiTextField1.y = i * 25;
			var __uiTextFormat1 = new flash.text.TextFormat();
			__uiTextFormat1.color = 0xFF0000;
			__uiTextField1.defaultTextFormat = __uiTextFormat1;
			__uiTextField1.text = "some text";
			this.addChild(__uiTextField1);
		};
	}
	//---------- code gen by tinyui ----------//

    public function new() {
        super();
        initUI();
    }
}
