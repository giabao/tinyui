import openfl.text.TextField;
import openfl.display.Sprite;

@:build(TinyUI.build('ui/13-nested-items.xml'))
class UI13NestedItems extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public var spr1 : openfl.display.Sprite;
	public function initUI() {
		var __uiUI06ViewItem1 = new UI06ViewItem();
		this.addChild(__uiUI06ViewItem1);
		this.spr1 = new flash.display.Sprite();
		this.spr1.x = 5;
		var txt1 = new flash.text.TextField();
		txt1.text = "nested item 1";
		this.spr1.addChild(txt1);
		var __uiTextField1 = new flash.text.TextField();
		__uiTextField1.text = txt1.text;
		__uiTextField1.y = 40;
		this.spr1.addChild(__uiTextField1);
		this.addChild(this.spr1);
		var __uiDisplayObjectContainer1 = new flash.display.DisplayObjectContainer();
		__uiDisplayObjectContainer1.x = spr1.x + 200;
		var __uiTextField2 = new flash.text.TextField();
		__uiTextField2.text = "nested item 2";
		__uiDisplayObjectContainer1.addChild(__uiTextField2);
		this.addChild(__uiDisplayObjectContainer1);
	}
	//---------- code gen by tinyui ----------//

    static inline var PADDING = 4;
}
