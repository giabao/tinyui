import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

using com.sandinh.TipTools;

@:tinyui('ui/15-tooltip.xml')
class UI15Tooltip extends Sprite {
	//++++++++++ code gen by tinyui ++++++++++//
	public function initUI() {
		var __uiTextField1 = new flash.text.TextField();
		__uiTextField1.text = "the target";
		__uiTextField1.border = true;
		__uiTextField1.borderColor = 0xFF0000;
		__uiTextField1.tooltip("An floating tooltip");
		var __uiTextFormat1 = new flash.text.TextFormat();
		__uiTextFormat1.color = 0xFFFFFF;
		__uiTextField1.setTextFormat(__uiTextFormat1);
		this.addChild(__uiTextField1);
	}
	//---------- code gen by tinyui ----------//

    
    public function new() {
        super();
        initUI();
    }
}
