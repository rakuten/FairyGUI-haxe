package fairygui.text;


import openfl.display.DisplayObject;

class HtmlNode
{
    public var charStart : Int;
    public var charEnd : Int;
    public var lineIndex : Int;
    public var nodeIndex : Int;
    
    public var element : HtmlElement;
    
    public var displayObject : DisplayObject;
    public var topY : Float;
    public var posUpdated : Bool;
    
    @:allow(fairygui.text)
    private function new()
    {
    }
    
    public function reset() : Void
    {
        charStart = -1;
        charEnd = -1;
        lineIndex = -1;
        nodeIndex = -1;
        
        displayObject = null;
        posUpdated = false;
    }
}
