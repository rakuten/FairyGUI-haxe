package fairygui.text;


import openfl.display.DisplayObject;

interface IRichTextObjectFactory
{

    function createObject(src : String, width : Int, height : Int) : DisplayObject;
    function freeObject(obj : DisplayObject) : Void;
}
