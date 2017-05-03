package fairygui.utils;

import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.display.Shape;

class PixelHitTest {
    private var _data:PixelHitTestData;

    public var offsetX:Int;
    public var offsetY:Int;

    private var _shape:Shape;

    public function PixelHitTest(data:PixelHitTestData, offsetX:Int=0, offsetY:Int=0)
    {
        _data = data;
        this.offsetX = offsetX;
        this.offsetY = offsetY;
    }

    public function createHitAreaSprite():Sprite
    {
        if(_shape==null)
        {
            _shape = new Shape();
            var g:Graphics = _shape.graphics;
            g.beginFill(0,0);
            g.lineStyle(0,0,0);

            var arr:Array<Int> = _data.pixels;
            var cnt:Int = arr.length;
            var pw:Int = _data.pixelWidth;
            for(i in 0...cnt)
            {
                var pixel:Int = arr[i];
                for(j in 0...8)
                {
                    if(((pixel>>j)&0x01)==1)
                    {
                        var pos:Int = i*8+j;
                        g.drawRect(pos%pw, Std.int(pos/pw), 1, 1);
                    }
                }
            }
            g.endFill();
        }

        var sprite:Sprite = new Sprite();
        sprite.mouseEnabled = false;
        sprite.x = offsetX;
        sprite.y = offsetY;
        sprite.graphics.copyFrom(_shape.graphics);
        sprite.scaleX = sprite.scaleY = _data.scale;

        return sprite;
    }
}
