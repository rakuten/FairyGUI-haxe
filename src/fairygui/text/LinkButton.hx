package fairygui.text;


import openfl.display.Sprite;

class LinkButton extends Sprite
{
    public var owner : HtmlNode;
    
    @:allow(fairygui.text)
    private function new()
    {
        super();
        buttonMode = true;
        graphics.beginFill(0, 0);
        graphics.drawRect(0, 0, 10, 10);
        graphics.endFill();
    }
}
