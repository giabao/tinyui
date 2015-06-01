import openfl.display.Sprite;
import openfl.display.Bitmap;

using com.sandinh.ui.BitmapTools;

@:build(TinyUI.build('ui/11-extension-method.xml'))
class UI11ExtensionMethod extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function initUI() {
		var __uiBitmap1 = new flash.display.Bitmap();
		__uiBitmap1.src("img/sd.jpg");
		this.addChild(__uiBitmap1);
	}
	//---------- code gen by tinyui ----------//

    public function new() {
        super();
        initUI();
    }
}
