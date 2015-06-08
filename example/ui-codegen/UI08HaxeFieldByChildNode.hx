import openfl.display.Sprite;
import openfl.text.TextField;

@:tinyui('ui/08-haxe-field-by-child-node.xml')
class UI08HaxeFieldByChildNode extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function initUI() {
		var __uiTextField1 = new flash.text.TextField();
		var __uiTextFormat1 = new flash.text.TextFormat();
		__uiTextFormat1.font = "Tahoma";
		__uiTextFormat1.size = 16;
		__uiTextFormat1.bold = true;
		__uiTextField1.defaultTextFormat = __uiTextFormat1;
		__uiTextField1.text = "Hi TinyUI!";
		this.addChild(__uiTextField1);
	}
	//---------- code gen by tinyui ----------//
 }
