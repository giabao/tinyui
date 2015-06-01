import openfl.display.Sprite;

@:build(TinyUI.build('ui/04-initUI-args.xml'))
class UI04InitUIArgs extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function initUI(foo:Int, baz:Int) {
		this.x = foo + baz;
	}
	//---------- code gen by tinyui ----------//

}
