package fairygui;

import fairygui.display.UISprite;
import fairygui.IAnimationGear;
import openfl.display.DisplayObject;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.errors.Error;

class GSwfObject extends GObject implements IAnimationGear
{
    public var movieClip(get, never):MovieClip;
    public var playing(get, set):Bool;
    public var frame(get, set):Int;

    private var _container:Sprite;
    private var _content:DisplayObject;
    private var _playing:Bool = false;
    private var _frame:Int = 0;

    public function new()
    {
        super();
        _playing = true;
        _sizeImplType = 1;
    }

    override private function createDisplayObject():Void
    {
        _container = new UISprite(this);
        setDisplayObject(_container);
    }

    @:final private function get_movieClip():MovieClip
    {
        return cast((_content), MovieClip);
    }

    @:final private function get_playing():Bool
    {
        return _playing;
    }

    private function set_playing(value:Bool):Bool
    {
        if (_playing != value)
        {
            _playing = value;
            if (_content != null && (Std.is(_content, MovieClip)))
            {
                if (_playing)
                    cast(_content, MovieClip).gotoAndPlay(_frame + 1);
                else
                    cast(_content, MovieClip).gotoAndStop(_frame + 1);
            }
            updateGear(5);
        }
        return value;
    }

    @:final private function get_frame():Int
    {
        return _frame;
    }

    private function set_frame(value:Int):Int
    {
        if (_frame != value)
        {
            _frame = value;
            if (_content != null && (Std.is(_content, MovieClip)))
            {
                if (_playing)
                    cast(_content, MovieClip).gotoAndPlay(_frame + 1);
                else
                    cast(_content, MovieClip).gotoAndStop(_frame + 1);
            }
            updateGear(5);
        }
        return value;
    }

    override public function dispose():Void
    {
        packageItem.owner.removeItemCallback(packageItem, __swfLoaded);
        super.dispose();
    }

    override public function constructFromResource():Void
    {
        sourceWidth = packageItem.width;
        sourceHeight = packageItem.height;
        initWidth = sourceWidth;
        initHeight = sourceHeight;

        setSize(sourceWidth, sourceHeight);

        packageItem.owner.addItemCallback(packageItem, __swfLoaded);
    }

    private function __swfLoaded(content:Dynamic):Void
    {
        if (_content != null)
            _container.removeChild(_content);
        _content = cast(content, DisplayObject);
        if (_content != null)
        {
            try
            {
                _container.addChild(_content);
            }
            catch (e:Error)
            {
                trace("__swfLoaded:" + e);
                _content = null;
            }
        }

        if (_content != null && (Std.is(_content, MovieClip)))
        {
            if (_playing)
                cast(_content, MovieClip).gotoAndPlay(_frame + 1);
            else
                cast(_content, MovieClip).gotoAndStop(_frame + 1);
        }
    }

    override public function setup_beforeAdd(xml:FastXML):Void
    {
        super.setup_beforeAdd(xml);

        var str:String = xml.att.playing;
        _playing = str != "false";
    }
}
