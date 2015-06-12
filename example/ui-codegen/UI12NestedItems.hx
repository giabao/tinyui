import openfl.text.TextField;
import openfl.display.Sprite;

@:build(TinyUI.build('ui/12-nested-items.xml'))
class UI12NestedItems extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function initUI() {
		var __uiUI06ViewInstanceVar1 = new UI06ViewInstanceVar();
		__uiUI06ViewInstanceVar1.txt.selectable = false;
		this.addChild(__uiUI06ViewInstanceVar1);
		var spr1 = new flash.display.Sprite();
		spr1.x = 5;
		var txt1 = new flash.text.TextField();
		txt1.text = "nested item";
		spr1.addChild(txt1);
		var __uiTextField1 = new flash.text.TextField();
		__uiTextField1.text = txt1.text;
		__uiTextField1.y = 40;
		spr1.addChild(__uiTextField1);
		this.addChild(spr1);
	}
	//---------- code gen by tinyui ----------//

    static inline var PADDING = 4;
}
