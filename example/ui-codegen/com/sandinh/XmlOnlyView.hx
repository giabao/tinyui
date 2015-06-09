package com.sandinh;

import openfl.display.Sprite;
import openfl.display.Bitmap as Bmp;
import openfl.text.TextField;
import openfl.text.TextFormatAlign.*;

using com.sandinh.ui.BitmapTools;

@:tinyui("ui-src/com/sandinh/XmlOnlyView.xml")
class XmlOnlyView extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function new():Void {
		super();
		var __uiBmp1 = new flash.display.Bitmap();
		__uiBmp1.src("img/sd.jpg");
		this.addChild(__uiBmp1);
		this.txt = new flash.text.TextField();
		var __uiTextFormat1 = new flash.text.TextFormat();
		__uiTextFormat1.size = 20;
		__uiTextFormat1.align = CENTER;
		this.txt.defaultTextFormat = __uiTextFormat1;
		this.txt.text = "Hi TinyUI!";
		this.addChild(this.txt);
	}
	public var txt : openfl.text.TextField;
	//---------- code gen by tinyui ----------//

}
