import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.Assets;

@:build(TinyUI.build('ui/10-new-expression.xml'))
class UI10NewExpression extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function initUI() {
		var foo = 100;
		var img1 = new Bitmap(Assets.getBitmapData("img/sd.jpg"));
		this.addChild(img1);
		var __uiBitmap1 = new flash.display.Bitmap(Assets.getBitmapData("img/sd.jpg"));
		__uiBitmap1.x = 5;
		var __uiFloat1 = img1.height + PADDING;
		__uiBitmap1.y = __uiFloat1;
		this.addChild(__uiBitmap1);
	}
	//---------- code gen by tinyui ----------//

    static inline var PADDING = 4;
}
