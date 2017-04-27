package fairygui;

import fairygui.GObject;
import fairygui.IColorGear;
import fairygui.PackageItem;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;

import fairygui.display.UIImage;
import fairygui.utils.ToolSet;

class GImage extends GObject implements IColorGear
{
    public var color(get, set) : UInt;
    public var flip(get, set) : Int;
    public var texture(get, set) : BitmapData;

    private var _bmdSource:BitmapData;
    private var _content : Bitmap;
    private var _color : UInt = 0;
    private var _flip : Int = 0;
    
    public function new()
    {
        super();
        _color = 0xFFFFFF;
    }
    
    private function get_color() : UInt
    {
        return _color;
    }
    
    private function set_color(value : UInt) : UInt
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
            updateBitmap();
        }
        return value;
    }

    public function get_texture():BitmapData
    {
        return _bmdSource;
    }

    public function set_texture(value:BitmapData):BitmapData
    {
        _bmdSource = value;
        handleSizeChanged();
        return value;
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
        
        if (_content.bitmapData != null && _content.bitmapData != _bmdSource)
        {
            _content.bitmapData.dispose();
            _content.bitmapData = null;
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
        if(_bmdSource!=null)
            return;

        _bmdSource = pi.image;
        _content.bitmapData = _bmdSource;
        _content.smoothing = packageItem.smoothing;
        updateBitmap();
    }
    
    override private function handleSizeChanged() : Void
    {
        if (packageItem.scale9Grid == null && !packageItem.scaleByTile || _bmdSource!=packageItem.image)
            _sizeImplType = 1;
        else 
            _sizeImplType = 0;
        handleScaleChanged();
        updateBitmap();
    }
    
    private function updateBitmap() : Void
    {
        if(_bmdSource==null)
            return;

        var newBmd:BitmapData = _bmdSource;
        var w:Int = Std.int(this.width);
        var h:Int = Std.int(this.height);

        if(w<=0 || h<=0)
            newBmd = null;
        else if(_bmdSource==packageItem.image && (_bmdSource.width!=w || _bmdSource.height!=h))
        {
            if(packageItem.scale9Grid!=null)
                newBmd = ToolSet.scaleBitmapWith9Grid(_bmdSource,
                packageItem.scale9Grid, w, h, packageItem.smoothing, packageItem.tileGridIndice);
            else if(packageItem.scaleByTile)
                newBmd = ToolSet.tileBitmap(_bmdSource, _bmdSource.rect, w, h);
        }

        if(newBmd!=null && _flip!=FlipType.None)
        {
            var mat:Matrix = new Matrix();
            var a:Int=1;
            var b:Int=1;
            if(_flip==FlipType.Both)
            {
                mat.scale(-1,-1);
                mat.translate(newBmd.width, newBmd.height);
            }
            else if(_flip==FlipType.Horizontal)
            {
                mat.scale(-1, 1);
                mat.translate(newBmd.width, 0);
            }
            else
            {
                mat.scale(1,-1);
                mat.translate(0, newBmd.height);
            }

            var bmdAfterFlip:BitmapData = new BitmapData(newBmd.width,newBmd.height,newBmd.transparent,0);
            bmdAfterFlip.draw(newBmd, mat);

            if(newBmd!=_bmdSource)
                newBmd.dispose();

            newBmd = bmdAfterFlip;
        }
        var oldBmd:BitmapData = _content.bitmapData;
        if(oldBmd!=newBmd)
        {
            if(oldBmd != null && oldBmd!=_bmdSource)
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
            this.flip = FlipType.parse(str);
    }
}
