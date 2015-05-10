import openfl.display.Sprite;
import openfl.text.TextField;

@:build(TinyUI.build('ui/09-item-field-node.xml'))
class UI09ItemFieldNode extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function initUI() {
		var __uiTextField1 = new flash.text.TextField();
		var __uiTextFormat1 = new flash.text.TextFormat();
		__uiTextFormat1.bold = true;
		__uiTextFormat1.size = 16;
		__uiTextFormat1.font = "Tahoma";
		__uiTextField1.defaultTextFormat = __uiTextFormat1;
		__uiTextField1.text = "Hi TinyUI!";
		this.addChild(__uiTextField1);
	}
	//---------- code gen by tinyui ----------//
 }
