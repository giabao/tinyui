import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.display.Shape;

@:build(TinyUI.build('ui/09-call-method.xml'))
class UI09CallMethod extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function initUI() {
		var __uiShape1 = new flash.display.Shape();
		__uiShape1.x = 1;
		__uiShape1.graphics.drawCircle(100, 100, 50);
		this.addChild(__uiShape1);
		var largeFmt = new flash.text.TextFormat();
		largeFmt.font = "Tahoma";
		largeFmt.size = 22;
		largeFmt.color = 0xFF0000;
		var __uiTextField1 = new flash.text.TextField();
		__uiTextField1.text = "Hi TinyUI!";
		__uiTextField1.setTextFormat(largeFmt, 0, 3);
		var __uiTextFormat1 = new flash.text.TextFormat();
		__uiTextFormat1.font = "Tahoma";
		__uiTextFormat1.size = 13;
		__uiTextFormat1.color = 0xFF0000;
		__uiTextFormat1.bold = true;
		__uiTextField1.setTextFormat(__uiTextFormat1, 3, 7);
		__uiTextField1.setTextFormat(largeFmt, 7, 10);
		this.addChild(__uiTextField1);
	}
	//---------- code gen by tinyui ----------//

    public function new() {
        super();
        initUI();
    }
}
