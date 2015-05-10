package com.sandinh.ui;

import openfl.display.Bitmap;
import openfl.Assets;

/** convenient extension method.
 * @see example `using-extension-method.xml` */
class BitmapTools {
    public static inline function src(bmp: Bitmap, path: String) {
        bmp.bitmapData = Assets.getBitmapData(path);
    }
}
