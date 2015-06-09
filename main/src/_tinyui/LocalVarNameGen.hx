package _tinyui;

import haxe.ds.StringMap;

/** map from className to an auto-inc value
 * this is used to declare local variable names */
class LocalVarNameGen {
    var localVarNum = new StringMap<Int>();

    public function new() { }

    public function next(className: String): String {
        var i = className.lastIndexOf(".");
        //take only real class name, not fqdn
        className = i == -1? className : className.substr(i + 1);

        var i = localVarNum.get(className);
        if (i == null) {
            i = 0;
        }
        localVarNum.set(className, ++i);
        return '__ui$className$i';
    }
}
