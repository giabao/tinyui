import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.events.MouseEvent;

using com.sandinh.ui.BitmapTools;

@:build(TinyUI.build('ui/17-modes.xml'))
class UI17Modes extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public var txt : openfl.text.TextField;
	public var uiMode(default, set) : String
	var _set_uiMode : String -> Void;
	function set_uiMode(mode:String):String {
		if (_set_uiMode == null) {
			throw new openfl.errors.Error("Warning: Can not set `uiMode = \"" + mode + "\"` before calling `initUI`");
		};
		if (mode != uiMode) {
			_set_uiMode(mode);
			uiMode = mode;
		};
		return mode;
	}
	public function initUI() {
		var fmt2 = new TextFormat("Tahoma", 12, 0xFF0000);
		var fmt1 = new TextFormat("Tahoma", 22, 0xFFFF00);
		var bmp1 = new flash.display.Bitmap();
		bmp1.src("img/sd.jpg");
		this.addChild(bmp1);
		this.txt = new flash.text.TextField();
		this.txt.border = true;
		this.txt.borderColor = 0xFF0000;
		this.txt.y = bmp1.y + 10;
		this.addChild(this.txt);
		this._set_uiMode = function(uiNewMode:String) {
			switch (uiNewMode) {
				case "m1":{
					this.txt.text = "mode 1";
					this.txt.type = DYNAMIC;
					this.txt.x = 100;
					this.txt.setTextFormat(fmt1);
					bmp1.scaleX = 0.5;
					bmp1.scaleY = 0.5;
				};
				case "m2":{
					this.txt.text = "mode 2";
					this.txt.defaultTextFormat = fmt2;
					this.txt.type = INPUT;
					this.txt.x = 100;
					this.txt.setTextFormat(fmt2);
					bmp1.scaleX = 1;
					bmp1.scaleY = 1;
				};
				default:{
					throw new openfl.errors.ArgumentError("This TinyUI view do not have mode \"" + uiNewMode + "\"");
				};
			};
		};
		this.uiMode = "m1";
	}
	//---------- code gen by tinyui ----------//

    public function new() {
        super();
        initUI();
        this.addEventListener(MouseEvent.CLICK, onClick);
    }
    function onClick(e: MouseEvent) {
        this.uiMode = this.uiMode == "m1"? "m2" : "m1";
    }
}
