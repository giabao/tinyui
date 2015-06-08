import openfl.text.TextField;
import openfl.display.Sprite;

@:tinyui('ui/17-styles.xml')
class UI17Styles extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function initUI() {
		var __uiTextField1 = new flash.text.TextField();
		__uiTextField1.backgroundColor = 0;
		var __uiTextFormat1 = new flash.text.TextFormat();
		__uiTextFormat1.color = 0xff0000;
		__uiTextField1.defaultTextFormat = __uiTextFormat1;
		__uiTextField1.text = "Text 1";
		this.addChild(__uiTextField1);
		var __uiTextField2 = new flash.text.TextField();
		__uiTextField2.selectable = false;
		var __uiTextFormat2 = new flash.text.TextFormat();
		__uiTextFormat2.color = 0x00ff00;
		__uiTextFormat2.bold = true;
		__uiTextField2.defaultTextFormat = __uiTextFormat2;
		__uiTextField2.text = "Text 2";
		this.addChild(__uiTextField2);
		var __uiTextField3 = new flash.text.TextField();
		__uiTextField3.selectable = false;
		var __uiTextFormat3 = new flash.text.TextFormat();
		__uiTextFormat3.color = 0xff0000;
		__uiTextField3.defaultTextFormat = __uiTextFormat3;
		__uiTextField3.text = "Text 3";
		__uiTextField3.backgroundColor = 0x0000FF;
		this.addChild(__uiTextField3);
	}
	//---------- code gen by tinyui ----------//

    public function new() {
        super();
        initUI();
    }
}
