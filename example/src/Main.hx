import openfl.display.Sprite;
import openfl.Lib;

class Main extends Sprite {
	public function new() 	{
		super();
        new View1();
        new View2();
        new View3();
        new View4();
        new View5();
        new View6();
        new View7();
        new View8();
        addChild(new View9());
        
        var v10 = new View10();
        addChildAt(v10, 0);
        v10.initUI();

        new View11();
    }
}
