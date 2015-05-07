import openfl.display.Sprite;

@:build(TinyUI.build('ui/04-local-var.xml'))
class UI04LocalVar extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function initUI() {
		var baz:Int = 3;
		var foo = 1 + 2;
		this.x = foo + baz;
	}
	//---------- code gen by tinyui ----------//

}
