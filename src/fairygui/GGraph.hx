package fairygui;

import fairygui.GObject;
import fairygui.IColorGear;
import openfl.errors.Error;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Graphics;
import openfl.display.LineScaleMode;
import openfl.display.Sprite;

import fairygui.display.UISprite;
import fairygui.utils.ToolSet;

class GGraph extends GObject implements IColorGear
{
    public var graphics(get, never) : Graphics;
    public var color(get, set) : UInt;

    private var _graphics : Graphics;
    
    private var _type : Int = 0;
    private var _lineSize : Int = 0;
    private var _lineColor : Int = 0;
    private var _lineAlpha : Float = 0;
    private var _fillColor : Int = 0;
    private var _fillAlpha : Float = 0;
    private var _fillBitmapData:BitmapData;
    private var _corner : Array<Dynamic>;
    
    public function new()
    {
        super();
        _lineSize = 1;
        _lineAlpha = 1;
        _fillAlpha = 1;
        _fillColor = 0xFFFFFF;
    }
    
    private function get_graphics() : Graphics
    {
        if (_graphics != null) 
            return _graphics;
        
        delayCreateDisplayObject();
        _graphics = cast((displayObject), Sprite).graphics;
        return _graphics;
    }
    
    private function get_color() : UInt
    {
        return _fillColor;
    }
    
    private function set_color(value : UInt) : UInt
    {
        if (_fillColor != value) 
        {
            _fillColor = value;
            updateGear(4);
            if (_type != 0) 
                drawCommon();
        }
        return value;
    }
    
    public function drawRect(lineSize : Int, lineColor : Int, lineAlpha : Float,
            fillColor : Int, fillAlpha : Float, corner : Array<Dynamic> = null) : Void
    {
        _type = 1;
        _lineSize = lineSize;
        _lineColor = lineColor;
        _lineAlpha = lineAlpha;
        _fillColor = fillColor;
        _fillAlpha = fillAlpha;
        _fillBitmapData = null;
        _corner = corner;
        drawCommon();
    }

    public function drawRectWithBitmap(lineSize:Int, lineColor:Int, lineAlpha:Float, bitmapData:BitmapData):Void
    {
        _type = 1;
        _lineSize = lineSize;
        _lineColor = lineColor;
        _lineAlpha = lineAlpha;
        _fillBitmapData = bitmapData;
        drawCommon();
    }
    
    public function drawEllipse(lineSize : Int, lineColor : Int, lineAlpha : Float,
            fillColor : Int, fillAlpha : Float) : Void
    {
        _type = 2;
        _lineSize = lineSize;
        _lineColor = lineColor;
        _lineAlpha = lineAlpha;
        _fillColor = fillColor;
        _fillAlpha = fillAlpha;
        _corner = null;
        drawCommon();
    }
    
    public function clearGraphics() : Void
    {
        if (_graphics != null) 
        {
            _type = 0;
            _graphics.clear();
        }
    }
    
    private function drawCommon() : Void
    {
        this.graphics;  //force create  
        
        _graphics.clear();
        
        var w : Int = Math.ceil(this.width);
        var h : Int = Math.ceil(this.height);
        if (w == 0 || h == 0) 
            return;
        
        if (_lineSize == 0) 
            _graphics.lineStyle(0, 0, 0, true, LineScaleMode.NONE);
        else 
            _graphics.lineStyle(_lineSize, _lineColor, _lineAlpha, true, LineScaleMode.NONE);
        
        //flash 画线的方法有点特殊，这里的处理保证了当lineSize是1时，图形的大小是正确的。
        //如果lineSize大于1，则无法保证，线条会在元件区域外显示
        if (_lineSize == 1) 
        {
            if (w > 0) 
                w -= _lineSize;
            if (h > 0) 
                h -= _lineSize;
        }

        if(_fillBitmapData!=null)
            _graphics.beginBitmapFill(_fillBitmapData);
        else
            _graphics.beginFill(_fillColor, _fillAlpha);

        if (_type == 1) 
        {
            if (_corner != null) 
            {
                if (_corner.length == 1) 
                    _graphics.drawRoundRect(0, 0, w, h, Std.parseInt(_corner[0]), Std.parseInt(_corner[0]));
                else 
                _graphics.drawRoundRectComplex(0, 0, w, h,
                        Std.parseInt(_corner[0]), Std.parseInt(_corner[1]), Std.parseInt(_corner[2]), Std.parseInt(_corner[3]));
            }
            else 
            _graphics.drawRect(0, 0, w, h);
        }
        else 
        _graphics.drawEllipse(0, 0, w, h);
        _graphics.endFill();
    }
    
    public function replaceMe(target : GObject) : Void
    {
        if (_parent == null) 
            throw new Error("parent not set");
        
        target.name = this.name;
        target.alpha = this.alpha;
        target.rotation = this.rotation;
        target.visible = this.visible;
        target.touchable = this.touchable;
        target.grayed = this.grayed;
        target.setXY(this.x, this.y);
        target.setSize(this.width, this.height);
        
        var index : Int = _parent.getChildIndex(this);
        _parent.addChildAt(target, index);
        target.relations.copyFrom(this.relations);
        
        _parent.removeChild(this, true);
    }
    
    public function addBeforeMe(target : GObject) : Void
    {
        if (_parent == null) 
            throw new Error("parent not set");
        
        var index : Int = _parent.getChildIndex(this);
        _parent.addChildAt(target, index);
    }
    
    public function addAfterMe(target : GObject) : Void
    {
        if (_parent == null) 
            throw new Error("parent not set");
        
        var index : Int = _parent.getChildIndex(this);
        index++;
        _parent.addChildAt(target, index);
    }
    
    public function setNativeObject(obj : DisplayObject) : Void
    {
        delayCreateDisplayObject();
        cast(displayObject, Sprite).addChild(obj);
    }
    
    private function delayCreateDisplayObject() : Void
    {
        if (displayObject == null)
        {
            setDisplayObject(new UISprite(this));
            if (_parent != null) 
                _parent.childStateChanged(this);
            handlePositionChanged();
            displayObject.alpha = this.alpha;
            displayObject.rotation = this.normalizeRotation;
            displayObject.visible = this.visible;
            cast(displayObject, Sprite).mouseEnabled = this.touchable;
            cast(displayObject, Sprite).mouseChildren = this.touchable;
        }
        else 
        {
            cast(displayObject, Sprite).graphics.clear();
            cast(displayObject, Sprite).removeChildren();
            _graphics = null;
        }
    }
    
    override private function handleSizeChanged() : Void
    {
        if (_graphics != null) 
        {
            if (_type != 0) 
                drawCommon();
        }
    }
    
    override public function setup_beforeAdd(xml : FastXML) : Void
    {
        var str : String;
        var type : String = xml.att.type;
        if (type != null && type != "empty") 
        {
            setDisplayObject(new UISprite(this));
        }
        
        super.setup_beforeAdd(xml);
        
        if (displayObject != null) 
        {
            _graphics = cast(this.displayObject, Sprite).graphics;
            
            str = xml.att.lineSize;
            if (str != null) 
                _lineSize = Std.parseInt(str);
            
            str = xml.att.lineColor;
            var c : Int;
            if (str != null) 
            {
                c= ToolSet.convertFromHtmlColor(str, true);
                _lineColor = c & 0xFFFFFF;
                _lineAlpha = ((c >> 24) & 0xFF) / 0xFF;
            }
            
            str = xml.att.fillColor;
            if (str != null) 
            {
                c = ToolSet.convertFromHtmlColor(str, true);
                _fillColor = c & 0xFFFFFF;
                _fillAlpha = ((c >> 24) & 0xFF) / 0xFF;
            }
            
            str = xml.att.corner;
            if (str != null) 
                _corner = str.split(",");
            
            if (type == "rect") 
                _type = 1
            else 
            _type = 2;
            
            drawCommon();
        }
    }
}
