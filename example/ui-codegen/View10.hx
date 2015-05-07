import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.Assets;

@:build(TinyUI.build('ui/view10.xml'))
class View10 extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public var img1 : openfl.display.Bitmap;
	public function initUI() {
		this.img1 = new Bitmap(Assets.getBitmapData("img/sd.jpg"));
		this.addChild(this.img1);
		var __uiBitmap1 = new flash.display.Bitmap(Assets.getBitmapData("img/sd.jpg"));
		__uiBitmap1.y = img1.height + PADDING;
		this.addChild(__uiBitmap1);
		var __uiBitmap2 = new flash.display.Bitmap();
		__uiBitmap2.x = img1.width + PADDING;
		var __uiBitmapData1 = Assets.getBitmapData("img/sd.jpg");
		__uiBitmap2.bitmapData = __uiBitmapData1;
		this.addChild(__uiBitmap2);
	}
	//---------- code gen by tinyui ----------//

    static inline var PADDING = 4;
}
