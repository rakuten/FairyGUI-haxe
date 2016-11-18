package fairygui.text;


import openfl.text.TextFormat;

class HtmlElement
{
    public var type : Int;  //0-none, 1-link, 2-image  
    
    public var start : Int;
    public var end : Int;
    public var textformat : TextFormat;
    public var id : String;
    public var width : Int;
    public var height : Int;
    
    //link
    public var href : String;
    public var target : String;
    
    //image
    public var src : String;
    public var realWidth : Int;
    public var realHeight : Int;
    
    public static inline var LINK : Int = 1;
    public static inline var IMAGE : Int = 2;
    
    @:allow(fairygui.text)
    private function new()
    {
    }
}
