package fairygui.text;


import openfl.display.DisplayObject;

class HtmlNode
{
    public var charStart : Int = 0;
    public var charEnd : Int = 0;
    public var lineIndex : Int = 0;
    public var nodeIndex : Int = 0;
    
    public var element : HtmlElement;
    
    public var displayObject : DisplayObject;
    public var topY : Float = 0;
    public var posUpdated : Bool = false;
    
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
