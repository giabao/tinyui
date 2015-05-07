import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

@:build(TinyUI.build('ui/view9.xml'))
class View9 extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function initUI() {
		var __uiTextField1 = new flash.text.TextField();
		__uiTextField1.text = "Hi TinyUI!";
		var largeFmt = new TextFormat("Tahoma", 22, 0xFF0000);
		__uiTextField1.setTextFormat(largeFmt, 0, 3);
		var __uiTextFormat1 = new flash.text.TextFormat();
		__uiTextFormat1.bold = true;
		__uiTextFormat1.size = 13;
		__uiTextFormat1.color = 0xFF0000;
		__uiTextFormat1.font = "Tahoma";
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
