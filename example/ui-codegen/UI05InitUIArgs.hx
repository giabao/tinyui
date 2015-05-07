import openfl.display.Sprite;

@:build(TinyUI.build('ui/05-initUI-args.xml'))
class UI05InitUIArgs extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function initUI(foo:Int, baz:Int) {
		this.x = foo + baz;
	}
	//---------- code gen by tinyui ----------//

}
