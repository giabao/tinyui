import openfl.text.TextField;
import openfl.display.Shape;
import openfl.display.Bitmap;
import openfl.text.TextFormat;
import openfl.display.Sprite;

using com.sandinh.ui.BitmapTools;
using com.sandinh.TipTools;
using layout.LayoutUtils;

@:build(TinyUI.build('ui/18-all.xml'))
class UI18All extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public var myFmt : openfl.text.TextFormat;
	public var myTxt : openfl.text.TextField;
	public static inline var UI_m1 : Int = 0;
	public static inline var UI_m2 : Int = 1;
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
	public function initUI(foo:Int, baz:Int) {
		this.x = foo + baz;
		this.simpleMethod("message 1");
		var tmpFmt = new flash.text.TextFormat();
		tmpFmt.bold = true;
		this.myFmt = new flash.text.TextFormat();
		this.myFmt.bold = false;
		this.y = 3;
		this.simpleMethod("message 2");
		this.myMethod(1, "msg1");
		var __uiTextFormat1 = new flash.text.TextFormat();
		__uiTextFormat1.color = 0xFF0000;
		__uiTextFormat1.align = CENTER;
		this.myFmt = __uiTextFormat1;
		this.myMethod(2, "msg2");
		var __uiTextFormat2 = new flash.text.TextFormat();
		__uiTextFormat2.size = 22;
		__uiTextFormat2.align = RIGHT;
		this.complexMethod(1, __uiTextFormat2, 2);
		var myBmp = new flash.display.Bitmap();
		myBmp.x = 5;
		myBmp.src("img/sd.jpg");
		var __uiShape1 = new flash.display.Shape();
		__uiShape1.graphics.lineStyle(2, 0xFF0000);
		__uiShape1.graphics.drawCircle(10, 10, 5);
		this.addChild(__uiShape1);
		this.myTxt = new flash.text.TextField();
		this.myTxt.x = 100;
		this.myTxt.defaultTextFormat = tmpFmt;
		this.myTxt.text = "my text";
		var __uiTextFormat3 = new flash.text.TextFormat();
		__uiTextFormat3.font = "Tahoma";
		__uiTextFormat3.size = 13;
		this.myTxt.setTextFormat(__uiTextFormat3, 3, 5);
		this.myTxt.appendText(" appended");
		this.addChild(this.myTxt);
		var mySpr = new flash.display.Sprite();
		mySpr.x = 200;
		var __uiTextField1 = new flash.text.TextField();
		__uiTextField1.text = "nested text";
		mySpr.addChild(__uiTextField1);
		this.addChild(mySpr);
		var padding = 3 + 4;
		var __uiSprite1 = methodCreateSprite();
		__uiSprite1.x = padding;
		var __uiBitmap1 = myBmp;
		__uiSprite1.addChild(__uiBitmap1);
		this.addChild(__uiSprite1);
		var __uiTextField2 = new flash.text.TextField();
		__uiTextField2.backgroundColor = 0;
		var __uiTextFormat4 = new flash.text.TextFormat();
		__uiTextFormat4.color = 0xff0000;
		__uiTextField2.defaultTextFormat = __uiTextFormat4;
		__uiTextField2.text = "Text 1";
		this.addChild(__uiTextField2);
		var __uiTextField3 = new flash.text.TextField();
		__uiTextField3.text = "Text 2";
		__uiTextField3.selectable = false;
		var __uiTextFormat5 = new flash.text.TextFormat();
		__uiTextFormat5.color = 0x00ff00;
		__uiTextFormat5.bold = true;
		__uiTextField3.defaultTextFormat = __uiTextFormat5;
		this.addChild(__uiTextField3);
		var __uiTextField4 = new flash.text.TextField();
		__uiTextField4.selectable = false;
		var __uiTextFormat6 = new flash.text.TextFormat();
		__uiTextFormat6.color = 0xff0000;
		__uiTextField4.defaultTextFormat = __uiTextFormat6;
		__uiTextField4.text = "Text 3";
		__uiTextField4.backgroundColor = 0x0000FF;
		this.addChild(__uiTextField4);
		for (i in 1 ... 4) {
			var __uiTextField5 = new flash.text.TextField();
			__uiTextField5.y = i * 25;
			var __uiTextFormat7 = new flash.text.TextFormat();
			__uiTextFormat7.color = 0xFF0000;
			__uiTextField5.defaultTextFormat = __uiTextFormat7;
			__uiTextField5.text = "some text";
			this.addChild(__uiTextField5);
		};
		var __uiTextField6 = new flash.text.TextField();
		__uiTextField6.text = "the target";
		__uiTextField6.border = true;
		__uiTextField6.borderColor = 0xFF0000;
		__uiTextField6.tooltip("An floating tooltip");
		this.addChild(__uiTextField6);
		var bmp1 = new flash.display.Bitmap();
		bmp1.src("img/sd.jpg");
		this.addChild(bmp1);
		var __uiBitmap2 = new flash.display.Bitmap();
		__uiBitmap2.bitmapData = bmp1.bitmapData;
		__uiBitmap2.alignRight();
		__uiBitmap2.alignBottom(15);
		this.addChild(__uiBitmap2);
		var txt1 = new flash.text.TextField();
		txt1.defaultTextFormat = tmpFmt;
		txt1.text = "TinyUI & Layout!";
		txt1.width = 200;
		txt1.height = 33;
		txt1.rightOf(bmp1, padding);
		this.addChild(txt1);
		var __uiTextField7 = new flash.text.TextField();
		__uiTextField7.defaultTextFormat = tmpFmt;
		__uiTextField7.text = "Hi Layout2!";
		__uiTextField7.width = 200;
		__uiTextField7.below(txt1);
		__uiTextField7.alignWith(txt1, LEFT);
		this.addChild(__uiTextField7);
		this._set_uiMode = function(uiNewMode:Int) {
			switch (uiNewMode) {
				case UI_m1:{
					this.y = 100;
					this.myTxt.y = 20;
					this.myTxt.setTextFormat(tmpFmt, 6);
					this.myTxt.mouseEnabled = false;
					mySpr.mouseEnabled = false;
				};
				case UI_m2:{
					this.y = 200;
					this.myTxt.y = 40;
					this.myTxt.setTextFormat(myFmt, 6);
					this.myTxt.mouseEnabled = true;
					mySpr.mouseEnabled = true;
				};
				default:{
					throw new openfl.errors.ArgumentError("This TinyUI view do not have mode <" + uiNewMode + ">");
				};
			};
		};
		this.uiMode = UI_m1;
	}
	//---------- code gen by tinyui ----------//

    public function new() {
        super();
        initUI(10, 20);
    }
    function simpleMethod(msg: String){
        trace(msg);
    }
    function myMethod(i1: Int, msg: String){ }
    function complexMethod(i1: Int, tf: TextFormat, i2: Int){ }
    function methodCreateSprite(): Sprite {
        return new Sprite();
    }
}
