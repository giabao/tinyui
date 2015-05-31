import openfl.display.Sprite;

@:build(TinyUI.build('ui/04-local-var.xml'))
class UI04LocalVar extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function initUI() {
		var foo = 1 + 2;
		var baz:Int = 3;
		this.x = foo + baz;
	}
	//---------- code gen by tinyui ----------//

}
