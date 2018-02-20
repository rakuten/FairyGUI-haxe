package fairygui.text;


import openfl.display.Sprite;

class LinkButton extends Sprite
{
    public var owner : HtmlNode;
    
    @:allow(fairygui.text)
    private function new()
    {
        super();
    }

    public function setSize(w:Float, h:Float):Void
    {
        buttonMode = true;
        graphics.beginFill(0, 0);
        graphics.drawRect(0, 0, w, h);
        graphics.endFill();
    }
}
