import openfl.display.Sprite;
import openfl.text.TextField;

@:build(TinyUI.build('ui/07-declare-var.xml'))
class UI07DeclareVar extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public var txt : openfl.text.TextField;
	public function initUI() {
		this.txt = new flash.text.TextField();
		this.txt.text = "Hi TinyUI!";
		this.addChild(this.txt);
	}
	//---------- code gen by tinyui ----------//
 }
