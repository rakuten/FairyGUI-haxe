package fairygui;

import fairygui.GObjectPool;
import fairygui.IAnimationGear;
import fairygui.IColorGear;
import fairygui.PackageItem;
import openfl.errors.Error;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Loader;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;
import openfl.net.URLRequest;

import fairygui.display.UISprite;
import fairygui.utils.ToolSet;

class GLoader extends GObject implements IColorGear implements IAnimationGear
{
    public var url(get, set) : String;
    public var align(get, set) : Int;
    public var verticalAlign(get, set) : Int;
    public var fill(get, set) : Int;
    public var autoSize(get, set) : Bool;
    public var playing(get, set) : Bool;
    public var frame(get, set) : Int;
    public var color(get, set) : UInt;
    public var showErrorSign(get, set) : Bool;
    public var texture(get, set):BitmapData;

    private var _url : String;
    private var _align : Int = 0;
    private var _verticalAlign : Int = 0;
    private var _autoSize : Bool = false;
    private var _fill : Int = 0;
    private var _showErrorSign : Bool = false;
    private var _playing : Bool = false;
    private var _frame : Int = 0;
    private var _color : UInt = 0;
    
    private var _contentItem : PackageItem;
    private var _contentSourceWidth : Int = 0;
    private var _contentSourceHeight : Int = 0;
    private var _contentWidth : Int = 0;
    private var _contentHeight : Int = 0;
    
    private var _container : Sprite;
    private var _content : DisplayObject;
    private var _errorSign : GObject;
    
    private var _updatingLayout : Bool = false;
    
    private var _loading : Int = 0;
    private var _externalLoader : Loader;
    private var _initExternalURLBeforeLoadSuccess:String;
    
    private static var _errorSignPool : GObjectPool = new GObjectPool();
    
    public function new()
    {
        super();
        _playing = true;
        _url = "";
        _align = AlignType.Left;
        _verticalAlign = VertAlignType.Top;
        _showErrorSign = true;
        _color = 0xFFFFFF;
    }
    
    override private function createDisplayObject() : Void
    {
        _container = new UISprite(this);
        setDisplayObject(_container);
    }
    
    override public function dispose() : Void
    {
        if (_contentItem != null) 
        {
            if (_loading == 1) 
                _contentItem.owner.removeItemCallback(_contentItem, __imageLoaded);
            else if (_loading == 2) 
                _contentItem.owner.removeItemCallback(_contentItem, __movieClipLoaded);
        }
        else 
        {
            //external
            if (_content != null) 
                freeExternal(_content);
        }
        super.dispose();
    }
    
    private function get_url() : String
    {
        return _url;
    }
    
    private function set_url(value : String) : String
    {
        if (_url == value) 
            return "";
        
        _url = value;
        loadContent();
        updateGear(7);
        return value;
    }
    
    override private function get_icon() : String
    {
        return _url;
    }
    
    override private function set_icon(value : String) : String
    {
        this.url = value;
        return value;
    }
    
    private function get_align() : Int
    {
        return _align;
    }
    
    private function set_align(value : Int) : Int
    {
        if (_align != value) 
        {
            _align = value;
            updateLayout();
        }
        return value;
    }
    
    private function get_verticalAlign() : Int
    {
        return _verticalAlign;
    }
    
    private function set_verticalAlign(value : Int) : Int
    {
        if (_verticalAlign != value) 
        {
            _verticalAlign = value;
            updateLayout();
        }
        return value;
    }
    
    private function get_fill() : Int
    {
        return _fill;
    }
    
    private function set_fill(value : Int) : Int
    {
        if (_fill != value) 
        {
            _fill = value;
            updateLayout();
        }
        return value;
    }
    
    private function get_autoSize() : Bool
    {
        return _autoSize;
    }
    
    private function set_autoSize(value : Bool) : Bool
    {
        if (_autoSize != value) 
        {
            _autoSize = value;
            updateLayout();
        }
        return value;
    }
    
    private function get_playing() : Bool
    {
        return _playing;
    }
    
    private function set_playing(value : Bool) : Bool
    {
        if (_playing != value) 
        {
            _playing = value;
            if (Std.is(_content, fairygui.display.MovieClip)) 
                cast(_content, fairygui.display.MovieClip).playing = value;
            else if (Std.is(_content, openfl.display.MovieClip))
                cast(_content, openfl.display.MovieClip).stop();
            updateGear(5);
        }
        return value;
    }
    
    private function get_frame() : Int
    {
        return _frame;
    }
    
    private function set_frame(value : Int) : Int
    {
        if (_frame != value) 
        {
            _frame = value;
            if (Std.is(_content, fairygui.display.MovieClip)) 
                cast(_content, fairygui.display.MovieClip).currentFrame = value
            else if (Std.is(_content, openfl.display.MovieClip))
            {
                if (_playing) 
                    cast(_content, openfl.display.MovieClip).gotoAndPlay(_frame + 1);
                else 
                    cast(_content, openfl.display.MovieClip).gotoAndStop(_frame + 1);
            }
            updateGear(5);
        }
        return value;
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
        var ct : ColorTransform = _container.transform.colorTransform;
        ct.redMultiplier = ((_color >> 16) & 0xFF) / 255;
        ct.greenMultiplier = ((_color >> 8) & 0xFF) / 255;
        ct.blueMultiplier = (_color & 0xFF) / 255;
        _container.transform.colorTransform = ct;
    }
    
    private function get_showErrorSign() : Bool
    {
        return _showErrorSign;
    }
    
    private function set_showErrorSign(value : Bool) : Bool
    {
        _showErrorSign = value;
        return value;
    }

    private function get_texture():BitmapData
    {
        if(Std.is(_content, Bitmap))
            return cast(_content, Bitmap).bitmapData;
        else
            return null;
    }

    private function set_texture(value:BitmapData):BitmapData
    {
        this.url = null;

        if(!Std.is(_content,Bitmap))
        {
            _content = new Bitmap();
            _container.addChild(_content);
        }
        else
            _container.addChild(_content);

        cast(_content, Bitmap).bitmapData = value;
        _contentSourceWidth = value.width;
        _contentSourceHeight = value.height;
        updateLayout();
        return value;
    }
    
    private function loadContent() : Void
    {
        clearContent();
        
        if (_url == null) 
            return;
        
        if (ToolSet.startsWith(_url, "ui://")) 
            loadFromPackage(_url);
        else 
            loadExternal();
    }
    
    private function loadFromPackage(itemURL : String) : Void
    {
        _contentItem = UIPackage.getItemByURL(itemURL);
        if (_contentItem != null) 
        {
            if(_autoSize)
                this.setSize(_contentItem.width, _contentItem.height);

            if (_contentItem.type == PackageItemType.Image) 
            {
                if (_contentItem.loaded) 
                    __imageLoaded(_contentItem);
                else 
                {
                    _loading = 1;
                    _contentItem.owner.addItemCallback(_contentItem, __imageLoaded);
                }
            }
            else if (_contentItem.type == PackageItemType.MovieClip) 
            {
                if (_contentItem.loaded) 
                    __movieClipLoaded(_contentItem);
                else 
                {
                    _loading = 2;
                    _contentItem.owner.addItemCallback(_contentItem, __movieClipLoaded);
                }
            }
            else if (_contentItem.type == PackageItemType.Swf) 
            {
                _loading = 2;
                _contentItem.owner.addItemCallback(_contentItem, __swfLoaded);
            }
            else 
                setErrorState();
        }
        else 
            setErrorState();
    }
    
    private function __imageLoaded(pi : PackageItem) : Void
    {
        _loading = 0;
        
        if (pi.image == null) 
        {
            setErrorState();
        }
        else 
        {
            if (!(Std.is(_content, Bitmap))) 
            {
                _content = new Bitmap();
                _container.addChild(_content);
            }
            else 
            _container.addChild(_content);
            cast((_content), Bitmap).bitmapData = pi.image;
            cast((_content), Bitmap).smoothing = pi.smoothing;
            _contentSourceWidth = pi.width;
            _contentSourceHeight = pi.height;
            updateLayout();
        }
    }
    
    private function __movieClipLoaded(pi : PackageItem) : Void
    {
        _loading = 0;
        if (!(Std.is(_content, fairygui.display.MovieClip))) 
        {
            _content = new fairygui.display.MovieClip();
            _container.addChild(_content);
        }
        else 
        _container.addChild(_content);
        
        _contentSourceWidth = pi.width;
        _contentSourceHeight = pi.height;
        
        cast(_content, fairygui.display.MovieClip).interval = Std.int(pi.interval);
        cast(_content, fairygui.display.MovieClip).frames = pi.frames;
        cast(_content, fairygui.display.MovieClip).repeatDelay = Std.int(pi.repeatDelay);
        cast(_content, fairygui.display.MovieClip).swing = pi.swing;
        cast(_content, fairygui.display.MovieClip).boundsRect = new Rectangle(0, 0, _contentSourceWidth, _contentSourceHeight);
        
        updateLayout();
    }
    
    private function __swfLoaded(content : DisplayObject) : Void
    {
        _loading = 0;
        if (_content != null) 
            _container.removeChild(_content);
        _content = cast((content), DisplayObject);
        if (_content != null) 
        {
            try
            {
                _container.addChild(_content);
            }            catch (e : Error)
            {
                trace("__swfLoaded:" + e);
                _content = null;
            }
        }
        
        if (_content != null && (Std.is(_content, openfl.display.MovieClip)))
        {
            if (_playing) 
                cast(_content, openfl.display.MovieClip).gotoAndPlay(_frame + 1)
            else
                cast(_content, openfl.display.MovieClip).gotoAndStop(_frame + 1);
        }
        
        _contentSourceWidth = Std.int(_content.width);
        _contentSourceHeight = Std.int(_content.height);
        
        updateLayout();
    }
    
    private function loadExternal() : Void
    {
        if (_externalLoader == null) 
        {
            _externalLoader = new Loader();
            _externalLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, __externalLoadCompleted);
            _externalLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, __externalLoadFailed);
        }
        _initExternalURLBeforeLoadSuccess = _url;
        _externalLoader.load(new URLRequest(url));
    }
    
    private function freeExternal(content : DisplayObject) : Void
    {
    }
    
    @:final private function onExternalLoadSuccess(content : DisplayObject) : Void
    {
        _content = content;
        _container.addChild(_content);
        if (content.loaderInfo != null && content.loaderInfo != displayObject.loaderInfo)
        {
            _contentSourceWidth = content.loaderInfo.width;
            _contentSourceHeight = content.loaderInfo.height;
        }
        else 
        {
            _contentSourceWidth = Std.int(content.width);
            _contentSourceHeight = Std.int(content.height);
        }
        updateLayout();
    }
    
    @:final private function onExternalLoadFailed() : Void
    {
        setErrorState();
    }
    
    private function __externalLoadCompleted(evt : Event) : Void
    {
        if (_initExternalURLBeforeLoadSuccess == _url)
        {
            onExternalLoadSuccess(_externalLoader.content);
        }
        _initExternalURLBeforeLoadSuccess = null;
    }
    
    private function __externalLoadFailed(evt : Event) : Void
    {
        onExternalLoadFailed();
    }
    
    private function setErrorState() : Void
    {
        if (!_showErrorSign) 
            return;
        
        if (_errorSign == null) 
        {
            if (UIConfig.loaderErrorSign != null) 
            {
                _errorSign = _errorSignPool.getObject(UIConfig.loaderErrorSign);
            }
        }
        
        if (_errorSign != null) 
        {
            _errorSign.setSize(this.width, this.height);
            _container.addChild(_errorSign.displayObject);
        }
    }
    
    private function clearErrorState() : Void
    {
        if (_errorSign != null) 
        {
            _container.removeChild(_errorSign.displayObject);
            _errorSignPool.returnObject(_errorSign);
            _errorSign = null;
        }
    }
    
    private function updateLayout() : Void
    {
        if (_content == null) 
        {
            if (_autoSize) 
            {
                _updatingLayout = true;
                this.setSize(50, 30);
                _updatingLayout = false;
            }
            return;
        }
        
        _content.x = 0;
        _content.y = 0;
        _content.scaleX = 1;
        _content.scaleY = 1;
        _contentWidth = _contentSourceWidth;
        _contentHeight = _contentSourceHeight;
        
        if (_autoSize) 
        {
            _updatingLayout = true;
            if (_contentWidth == 0) 
                _contentWidth = 50;
            if (_contentHeight == 0) 
                _contentHeight = 30;
            this.setSize(_contentWidth, _contentHeight);
            _updatingLayout = false;
        }
        else 
        {
            var sx : Float = 1;
            var sy : Float = 1;
            if (_fill != LoaderFillType.None) 
            {
                sx = this.width / _contentSourceWidth;
                sy = this.height / _contentSourceHeight;
                
                if (sx != 1 || sy != 1) 
                {
                    if (_fill == LoaderFillType.ScaleMatchHeight) 
                        sx = sy
                    else if (_fill == LoaderFillType.ScaleMatchWidth) 
                        sy = sx
                    else if (_fill == LoaderFillType.Scale) 
                    {
                        if (sx > sy) 
                            sx = sy
                        else 
                        sy = sx;
                    }
                    _contentWidth = Std.int(_contentSourceWidth * sx);
                    _contentHeight = Std.int(_contentSourceHeight * sy);
                }
            }
            
            if (_contentItem != null && _contentItem.type == PackageItemType.Image) 
            {
                resizeImage();
            }
            else 
            {
                _content.scaleX = sx;
                _content.scaleY = sy;
            }
            
            if (_align == AlignType.Center) 
                _content.x = Std.int((this.width - _contentWidth) / 2)
            else if (_align == AlignType.Right) 
                _content.x = this.width - _contentWidth;
            if (_verticalAlign == VertAlignType.Middle) 
                _content.y = Std.int((this.height - _contentHeight) / 2)
            else if (_verticalAlign == VertAlignType.Bottom) 
                _content.y = this.height - _contentHeight;
        }
    }
    
    private function clearContent() : Void
    {
        clearErrorState();
        
        if (_content != null && _content.parent != null) 
            _container.removeChild(_content);
        
        if (_contentItem != null) 
        {
            if (_loading == 1) 
                _contentItem.owner.removeItemCallback(_contentItem, __imageLoaded)
            else if (_loading == 2) 
                _contentItem.owner.removeItemCallback(_contentItem, __movieClipLoaded);
        }
        else 
        {
            if (_content != null) 
                freeExternal(_content);
        }
        
        _contentItem = null;
        _loading = 0;
    }
    
    override private function handleSizeChanged() : Void
    {
        if (!_updatingLayout) 
            updateLayout();
    }
    
    private function resizeImage() : Void
    {
        var source : BitmapData = _contentItem.image;
        if (source == null) 
            return;

        var oldBmd : BitmapData;
        var newBmd : BitmapData;
        if (_contentItem.scale9Grid != null) 
        {
            _content.scaleX = 1;
            _content.scaleY = 1;

            oldBmd= cast(_content, Bitmap).bitmapData;

            if (source.width == _contentWidth && source.height == _contentHeight) 
                newBmd = source
            else if (_contentWidth == 0 || _contentHeight == 0) 
                newBmd = null
            else 
            newBmd = ToolSet.scaleBitmapWith9Grid(source,
                            _contentItem.scale9Grid, _contentWidth, _contentHeight, _contentItem.smoothing, _contentItem.tileGridIndice);
            
            if (oldBmd != newBmd) 
            {
                if (oldBmd != null && oldBmd != source) 
                    oldBmd.dispose();
                cast((_content), Bitmap).bitmapData = newBmd;
            }
        }
        else if (_contentItem.scaleByTile) 
        {
            _content.scaleX = 1;
            _content.scaleY = 1;
            
            oldBmd = cast((_content), Bitmap).bitmapData;
            
            if (source.width == _contentWidth && source.height == _contentHeight) 
                newBmd = source
            else if (_contentWidth == 0 || _contentHeight == 0) 
                newBmd = null
            else 
            newBmd = ToolSet.tileBitmap(source, source.rect, _contentWidth, _contentHeight);
            
            if (oldBmd != newBmd) 
            {
                if (oldBmd != null && oldBmd != source)
                    oldBmd.dispose();
                cast((_content), Bitmap).bitmapData = newBmd;
            }
        }
        else 
        {
            _content.scaleX = _contentWidth / _contentSourceWidth;
            _content.scaleY = _contentHeight / _contentSourceHeight;
        }
    }
    
    override public function setup_beforeAdd(xml : FastXML) : Void
    {
        super.setup_beforeAdd(xml);
        
        var str : String;
        str = xml.att.url;
        if (str != null) 
            _url = str;
        
        str = xml.att.align;
        if (str != null) 
            _align = AlignType.parse(str);
        
        str = xml.att.vAlign;
        if (str != null) 
            _verticalAlign = VertAlignType.parse(str);
        
        str = xml.att.fill;
        if (str != null) 
            _fill = LoaderFillType.parse(str);
        
        _autoSize = xml.att.autoSize == "true";
        
        str = xml.att.errorSign;
        if (str != null) 
            _showErrorSign = str == "true";
        
        _playing = xml.att.playing != "false";
        
        str = xml.att.color;
        if (str != null) 
            this.color = ToolSet.convertFromHtmlColor(str);
        
        if (_url != null && _url != "")
            loadContent();
    }
}
