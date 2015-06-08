import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

@:tinyui('ui/07-initUI-local-var.xml')
class UI07InitUILocalVar extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public var txt2 : openfl.text.TextField;
	public function initUI() {
		var myFmt = new flash.text.TextFormat();
		myFmt.font = "Tahoma";
		myFmt.size = 16;
		myFmt.bold = true;
		var txt1 = new flash.text.TextField();
		txt1.defaultTextFormat = myFmt;
		txt1.x = 100;
		txt1.text = "Hi TinyUI!";
		this.addChild(txt1);
		this.txt2 = new flash.text.TextField();
		this.txt2.x = txt1.x;
		this.txt2.text = "Hi TinyUI!";
		this.addChild(this.txt2);
	}
	//---------- code gen by tinyui ----------//

}
