package fairygui.display;


import openfl.display.BitmapData;
import openfl.geom.Rectangle;

class Frame
{
    public var rect : Rectangle;
    public var addDelay : Int = 0;
    public var image : BitmapData;
    
    public function new()
    {
        rect = new Rectangle();
    }
}
