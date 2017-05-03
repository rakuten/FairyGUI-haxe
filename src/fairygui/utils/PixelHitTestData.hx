package fairygui.utils;

import openfl.utils.ByteArray;

class PixelHitTestData {
    public var pixelWidth:Int;
    public var scale:Float;
    public var pixels:Array<Int>;

    public function new()
    {
    }

    public function load(ba:ByteArray):Void
    {
        ba.readInt();
        pixelWidth = ba.readInt();
        scale = ba.readByte();
        var len:Int = ba.readInt();
        pixels = new Array<Int>();
        for(i in 0...len)
        {
            var j:Int = ba.readByte();
            if(j<0)
                j+=256;

            pixels[i] = j;
        }
    }
}
