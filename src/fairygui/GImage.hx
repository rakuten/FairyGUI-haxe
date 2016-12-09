package fairygui;

import fairygui.GObject;
import fairygui.IColorGear;
import fairygui.PackageItem;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

import fairygui.display.UIImage;
import fairygui.utils.ToolSet;

class GImage extends GObject implements IColorGear
{
    public var color(get, set) : Int;
    public var flip(get, set) : Int;

    private var _content : Bitmap;
    private var _bmdAfterFlip : BitmapData;
    private var _color : Int = 0;
    private var _flip : Int = 0;
    
    public function new()
    {
        super();
        _color = 0xFFFFFF;
    }
    
    private function get_color() : Int
    {
        return _color;
    }
    
    private function set_color(value : Int) : Int
    {
        if (_color != value) 
        {
            _color = value;
            updateGear(4);
            applyColor();
        }
        return value;
    }
    
    private function applyColor() : Void
    {
        var ct : ColorTransform = _content.transform.colorTransform;
        ct.redMultiplier = ((_color >> 16) & 0xFF) / 255;
        ct.greenMultiplier = ((_color >> 8) & 0xFF) / 255;
        ct.blueMultiplier = (_color & 0xFF) / 255;
        _content.transform.colorTransform = ct;
    }
    
    private function get_flip() : Int
    {
        return _flip;
    }
    
    private function set_flip(value : Int) : Int
    {
        if (_flip != value) 
        {
            _flip = value;
            applyFlip();
        }
        return value;
    }
    
    private function applyFlip() : Void
    {
        var source : BitmapData = packageItem.image;
        if (source == null) 
            return;
        
        if (_flip != FlipType.None) 
        {
            var mat : Matrix = new Matrix();
            var a : Int = 1;
            var b : Int = 1;
            if (_flip == FlipType.Both) 
            {
                mat.scale(-1, -1);
                mat.translate(source.width, source.height);
            }
            else if (_flip == FlipType.Horizontal) 
            {
                mat.scale(-1, 1);
                mat.translate(source.width, 0);
            }
            else 
            {
                mat.scale(1, -1);
                mat.translate(0, source.height);
            }
            var tmp : BitmapData = new BitmapData(source.width, source.height, source.transparent, 0);
            tmp.draw(source, mat);
            if (_content.bitmapData != null && _content.bitmapData != source) 
                _content.bitmapData.dispose();
            _bmdAfterFlip = tmp;
        }
        else 
        {
            if (_content.bitmapData != null && _content.bitmapData != source) 
                _content.bitmapData.dispose();
            _bmdAfterFlip = source;
        }
        
        updateBitmap();
    }
    
    override private function createDisplayObject() : Void
    {
        _content = new UIImage(this);
        setDisplayObject(_content);
    }
    
    override public function dispose() : Void
    {
        if (!packageItem.loaded) 
            packageItem.owner.removeItemCallback(packageItem, __imageLoaded);
        
        if (_content.bitmapData != null && _content.bitmapData != _bmdAfterFlip && _content.bitmapData != packageItem.image) 
        {
            _content.bitmapData.dispose();
            _content.bitmapData = null;
        }
        if (_bmdAfterFlip != null && _bmdAfterFlip != packageItem.image) 
        {
            _bmdAfterFlip.dispose();
            _bmdAfterFlip = null;
        }
        
        super.dispose();
    }
    
    override public function constructFromResource() : Void
    {
        _sourceWidth = packageItem.width;
        _sourceHeight = packageItem.height;
        _initWidth = _sourceWidth;
        _initHeight = _sourceHeight;
        
        setSize(_sourceWidth, _sourceHeight);
        
        if (packageItem.loaded) 
            __imageLoaded(packageItem)
        else 
        packageItem.owner.addItemCallback(packageItem, __imageLoaded);
    }
    
    private function __imageLoaded(pi : PackageItem) : Void
    {
        _content.bitmapData = pi.image;
        _content.smoothing = packageItem.smoothing;
        applyFlip();
    }
    
    override private function handleSizeChanged() : Void
    {
        if (packageItem.scale9Grid == null && !packageItem.scaleByTile) 
            _sizeImplType = 1
        else 
        _sizeImplType = 0;
        handleScaleChanged();
        updateBitmap();
    }
    
    private function updateBitmap() : Void
    {
        if (_bmdAfterFlip == null) 
            return;
        
        var oldBmd : BitmapData = _content.bitmapData;
        var newBmd : BitmapData;
        var w : Float;
        var h : Float;
        if (packageItem.scale9Grid != null) 
        {
            w = this.width;
            h = this.height;
            
            if (_bmdAfterFlip.width == w && _bmdAfterFlip.height == h) 
                newBmd = _bmdAfterFlip
            else if (w <= 0 || h <= 0) 
                newBmd = null
            else 
            {
                var rect : Rectangle;
                if (_flip != FlipType.None) 
                {
                    rect = packageItem.scale9Grid.clone();
                    if (_flip == FlipType.Horizontal || _flip == FlipType.Both) 
                    {
                        rect.x = _bmdAfterFlip.width - rect.right;
                        rect.right = rect.x + rect.width;
                    }
                    
                    if (_flip == FlipType.Vertical || _flip == FlipType.Both) 
                    {
                        rect.y = _bmdAfterFlip.height - rect.bottom;
                        rect.bottom = rect.y + rect.height;
                    }
                }
                else 
                rect = packageItem.scale9Grid;
                
                newBmd = ToolSet.scaleBitmapWith9Grid(_bmdAfterFlip,
                                rect, Std.int(w), Std.int(h), packageItem.smoothing, packageItem.tileGridIndice);
            }
        }
        else if (packageItem.scaleByTile) 
        {
            w = this.width;
            h = this.height;
            oldBmd = _content.bitmapData;
            
            if (_bmdAfterFlip.width == w && _bmdAfterFlip.height == h) 
                newBmd = _bmdAfterFlip
            else if (w == 0 || h == 0) 
                newBmd = null
            else 
            newBmd = ToolSet.tileBitmap(_bmdAfterFlip, _bmdAfterFlip.rect, Std.int(w), Std.int(h));
        }
        else 
        {
            newBmd = _bmdAfterFlip;
        }
        
        if (oldBmd != newBmd) 
        {
            if (oldBmd != null && oldBmd != _bmdAfterFlip && oldBmd != packageItem.image) 
                oldBmd.dispose();
            _content.bitmapData = newBmd;
        }
    }
    
    override public function setup_beforeAdd(xml : FastXML) : Void
    {
        super.setup_beforeAdd(xml);
        
        var str : String;
        str = xml.att.color;
        if (str != null) 
            this.color = ToolSet.convertFromHtmlColor(str);
        
        str = xml.att.flip;
        if (str != null) 
            _flip = FlipType.parse(str);
    }
}
