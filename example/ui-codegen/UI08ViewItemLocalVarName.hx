import openfl.display.Sprite;
import openfl.text.TextField;

@:build(TinyUI.build('ui/08-view-item-local-var-name.xml'))
class UI08ViewItemLocalVarName extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function initUI() {
		var txt1 = new flash.text.TextField();
		txt1.text = "Hi TinyUI!";
		this.addChild(txt1);
		var __uiTextField1 = new flash.text.TextField();
		__uiTextField1.x = txt1.width;
		__uiTextField1.text = "Hi TinyUI!";
		this.addChild(__uiTextField1);
	}
	//---------- code gen by tinyui ----------//
 }
