package com.sandinh.tinyui.example;

import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign.CENTER;

using StringTools;

@:build(com.sandinh.tinyui.UIMacro.build('ui/some-view.xml'))
class SomeView extends Sprite {
    private static inline var PADDING = 10;

    private function shouldEnableTxt(): Bool return true;
    
    public function new() {
        super();
        this.bmp
    }
}
