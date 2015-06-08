import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

@:tinyui('ui/06-view-instance-var.xml')
class UI06ViewInstanceVar extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public var myFmt : openfl.text.TextFormat;
	public var txt : openfl.text.TextField;
	public function initUI() {
		this.myFmt = new flash.text.TextFormat();
		this.myFmt.font = "Tahoma";
		this.myFmt.size = 16;
		this.myFmt.bold = true;
		this.txt = new flash.text.TextField();
		this.txt.defaultTextFormat = myFmt;
		this.txt.text = "Hi TinyUI!";
		this.addChild(this.txt);
	}
	//---------- code gen by tinyui ----------//
 }
