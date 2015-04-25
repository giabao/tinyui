package com.sandinh.tinyui.example;

import openfl.display.Sprite;
import openfl.Lib;

/**
 * ...
 * @author sandinh
 */

class Main extends Sprite {
	public function new() 	{
		super();
        var view = new SomeView();
		addChild(view);
	}
}
