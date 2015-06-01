import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import openfl.events.MouseEvent;

using com.sandinh.ui.BitmapTools;

@:build(TinyUI.build('ui/16-modes.xml'))
class UI16Modes extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public static inline var UI_M1 : Int = 0;
	public static inline var UI_M2 : Int = 1;
	public var uiMode(default, set) : Int = -1;
	var _set_uiMode : Int -> Void;
	function set_uiMode(mode:Int):Int {
		if (_set_uiMode == null) {
			throw new openfl.errors.Error("Warning: Can not set `uiMode = " + mode + "` before calling `initUI`");
		};
		if (mode != uiMode) {
			_set_uiMode(mode);
			uiMode = mode;
		};
		return mode;
	}
	public function initUI() {
		var fmt1 = new flash.text.TextFormat();
		fmt1.font = "Tahoma";
		fmt1.size = 22;
		fmt1.color = 0xFFFF00;
		var fmt2 = new flash.text.TextFormat();
		fmt2.font = "Tahoma";
		fmt2.size = 12;
		fmt2.color = 0xFF0000;
		var bmp1 = new flash.display.Bitmap();
		bmp1.src("img/sd.jpg");
		this.addChild(bmp1);
		var txt1 = new flash.text.TextField();
		txt1.border = true;
		txt1.borderColor = 0xFF0000;
		txt1.x = bmp1.width;
		txt1.autoSize = TextFieldAutoSize.LEFT;
		this.addChild(txt1);
		var txt2 = new flash.text.TextField();
		txt2.border = true;
		txt2.borderColor = 0xFF0000;
		txt2.x = bmp1.width + 200;
		this.addChild(txt2);
		this._set_uiMode = function(uiNewMode:Int) {
			switch (uiNewMode) {
				case UI_M1:{
					txt1.y = 100;
					txt1.type = DYNAMIC;
					txt1.setTextFormat(fmt1);
					txt2.y = 100;
					txt2.type = DYNAMIC;
					txt2.setTextFormat(fmt1);
					txt1.text = "txt1 in mode 1";
					txt2.text = "txt2 in mode 1";
					bmp1.scaleX = 0.5;
					bmp1.scaleY = 0.5;
				};
				case UI_M2:{
					txt1.y = 0;
					txt1.type = INPUT;
					txt1.defaultTextFormat = fmt2;
					txt1.setTextFormat(fmt2);
					txt2.y = 0;
					txt2.type = INPUT;
					txt2.defaultTextFormat = fmt2;
					txt2.setTextFormat(fmt2);
					txt1.text = "txt1 in mode 2";
					txt2.text = "txt2 in mode 2";
					bmp1.scaleX = 1;
					bmp1.scaleY = 1;
				};
				default:{
					throw new openfl.errors.ArgumentError("This TinyUI view do not have mode <" + uiNewMode + ">");
				};
			};
		};
		this.uiMode = UI_M1;
	}
	//---------- code gen by tinyui ----------//

    public function new() {
        super();
        initUI();
        this.addEventListener(MouseEvent.CLICK, onClick);
    }
    function onClick(e: MouseEvent) {
        this.uiMode = this.uiMode == UI_M1? UI_M2 : UI_M1;
    }
}
