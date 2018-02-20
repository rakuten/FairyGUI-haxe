package fairygui;

import fairygui.display.UIMovieClip;
import fairygui.IAnimationGear;
import fairygui.IColorGear;
import fairygui.PackageItem;
import fairygui.utils.ToolSet;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;

class GMovieClip extends GObject implements IAnimationGear implements IColorGear
{
    public var playing(get, set):Bool;
    public var frame(get, set):Int;
    public var color(get, set):UInt;

    private var _movieClip:UIMovieClip;
    private var _color:UInt;

    public function new()
    {
        super();
        _sizeImplType = 1;
        _color = 0xFFFFFF;
    }

    override private function createDisplayObject():Void
    {
        _movieClip = new UIMovieClip(this);
        _movieClip.mouseEnabled = false;
        _movieClip.mouseChildren = false;
        setDisplayObject(_movieClip);
    }

    @:final private function get_playing():Bool
    {
        return _movieClip.playing;
    }

    @:final private function set_playing(value:Bool):Bool
    {
        if (_movieClip.playing != value)
        {
            _movieClip.playing = value;
            updateGear(5);
        }
        return value;
    }

    @:final private function get_frame():Int
    {
        return _movieClip.currentFrame;
    }

    private function set_frame(value:Int):Int
    {
        if (_movieClip.currentFrame != value)
        {
            _movieClip.currentFrame = value;
            updateGear(5);
        }
        return value;
    }

    //从start帧开始，播放到end帧（-1表示结尾），重复times次（0表示无限循环），循环结束后，停止在endAt帧（-1表示参数end）
    public function setPlaySettings(start:Int = 0, end:Int = -1,
                                    times:Int = 0, endAt:Int = -1,
                                    endCallback:Dynamic = null):Void
    {
        _movieClip.setPlaySettings(start, end, times, endAt, endCallback);
    }

    private function get_color():UInt
    {
        return _color;
    }

    private function set_color(value:UInt):UInt
    {
        if (_color != value)
        {
            _color = value;
            updateGear(4);
            applyColor();
        }
        return value;
    }

    private function applyColor():Void
    {
        var ct:ColorTransform = _movieClip.transform.colorTransform;
        ct.redMultiplier = ((_color >> 16) & 0xFF) / 255;
        ct.greenMultiplier = ((_color >> 8) & 0xFF) / 255;
        ct.blueMultiplier = (_color & 0xFF) / 255;
        _movieClip.transform.colorTransform = ct;
    }

    override public function dispose():Void
    {
        super.dispose();
    }

    override public function constructFromResource():Void
    {
        sourceWidth = packageItem.width;
        sourceHeight = packageItem.height;
        initWidth = sourceWidth;
        initHeight = sourceHeight;

        setSize(sourceWidth, sourceHeight);

        if (packageItem.loaded)
            __movieClipLoaded(packageItem);
        else
            packageItem.owner.addItemCallback(packageItem, __movieClipLoaded);
    }

    private function __movieClipLoaded(pi:PackageItem):Void
    {
        _movieClip.interval = Std.int(packageItem.interval);
        _movieClip.swing = packageItem.swing;
        _movieClip.repeatDelay = Std.int(packageItem.repeatDelay);
        _movieClip.frames = packageItem.frames;
        _movieClip.boundsRect = new Rectangle(0, 0, sourceWidth, sourceHeight);
        _movieClip.smoothing = packageItem.smoothing;
    }

    override public function setup_beforeAdd(xml:FastXML):Void
    {
        super.setup_beforeAdd(xml);

        var str:String;
        str = xml.att.frame;
        if (str != null)
            _movieClip.currentFrame = Std.parseInt(str);
        str = xml.att.playing;
        _movieClip.playing = str != "false";
        str = xml.att.color;
        if (str != null)
            this.color = ToolSet.convertFromHtmlColor(str);
    }
}
