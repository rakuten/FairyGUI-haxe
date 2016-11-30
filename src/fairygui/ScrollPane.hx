package fairygui;

import tweenx909.TweenX;

import openfl.errors.Error;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.display.DisplayObject;

import fairygui.event.GTouchEvent;
import fairygui.utils.GTimers;
import fairygui.utils.ToolSet;
import fairygui.utils.CompatUtil;
import fairygui.utils.EaseLookup;



@:meta(Event(name="scroll",type="openfl.events.Event"))

@:meta(Event(name="scrollEnd",type="openfl.events.Event"))

@:meta(Event(name="pullDownRelease",type="openfl.events.Event"))

@:meta(Event(name="pullUpRelease",type="openfl.events.Event"))

class ScrollPane extends EventDispatcher
{
    public var owner(get, never) : GComponent;
    public var bouncebackEffect(get, set) : Bool;
    public var touchEffect(get, set) : Bool;
    public var scrollSpeed(get, set) : Int;
    public var snapToItem(get, set) : Bool;
    public var mouseWheelEnabled(get, set) : Bool;
    public var percX(get, set) : Float;
    public var percY(get, set) : Float;
    public var posX(get, set) : Float;
    public var posY(get, set) : Float;
    public var isBottomMost(get, never) : Bool;
    public var isRightMost(get, never) : Bool;
    public var currentPageX(get, set) : Int;
    public var currentPageY(get, set) : Int;
    public var scrollingPosX(get, never) : Float;
    public var scrollingPosY(get, never) : Float;
    public var contentWidth(get, never) : Float;
    public var contentHeight(get, never) : Float;
    public var viewWidth(get, set) : Int;
    public var viewHeight(get, set) : Int;

    private var _owner : GComponent;
    private var _container : Sprite;
    private var _maskContainer : Sprite;
    private var _mask : Sprite;
    
    private var _viewWidth : Float;
    private var _viewHeight : Float;
    private var _contentWidth : Float;
    private var _contentHeight : Float;
    
    private var _scrollType : Int;
    private var _scrollSpeed : Int;
    private var _mouseWheelSpeed : Int;
    private var _scrollBarMargin : Margin;
    private var _bouncebackEffect : Bool;
    private var _touchEffect : Bool;
    private var _scrollBarDisplayAuto : Bool;
    private var _vScrollNone : Bool;
    private var _hScrollNone : Bool;
    
    private var _displayOnLeft : Bool;
    private var _snapToItem : Bool;
    private var _displayInDemand : Bool;
    private var _mouseWheelEnabled : Bool;
    private var _pageMode : Bool;
    private var _pageSizeH : Float;
    private var _pageSizeV : Float;
    private var _inertiaDisabled : Bool;
    private var _maskDisabled : Bool;
    
    private var _xPerc : Float;
    private var _yPerc : Float;
    private var _xPos : Float;
    private var _yPos : Float;
    private var _xOverlap : Float
    ;private var _yOverlap : Float;
    
    private static var _easeTypeFunc : Float -> Float;
    private var _throwTween : ThrowTween;
    private var _tweening : Int;
    private var _tweener : TweenX;
    
    private var _time1 : UInt;
    private var _time2 : UInt;
    private var _y1 : Float;
    private var _y2 : Float;
    private var _x1 : Float;
    private var _x2 : Float;
    private var _xOffset : Float;
    private var _yOffset : Float;
    
    private var _needRefresh : Bool;
    private var _holdAreaPoint : Point;
    private var _isHoldAreaDone : Bool;
    private var _aniFlag : Int;
    private var _scrollBarVisible : Bool;
    
    private var _hzScrollBar : GScrollBar;
    private var _vtScrollBar : GScrollBar;

    public var isDragged : Bool;
    public static var draggingPane : ScrollPane;
    private static var _gestureFlag : Int = 0;
    
    private static var sHelperPoint : Point = new Point();
    private static var sHelperRect : Rectangle = new Rectangle();
    
    public static inline var SCROLL_END : String = "scrollEnd";
    public static inline var PULL_DOWN_RELEASE : String = "pullDownRelease";
    public static inline var PULL_UP_RELEASE : String = "pullUpRelease";
    
    public function new(owner : GComponent,
            scrollType : Int,
            scrollBarMargin : Margin,
            scrollBarDisplay : Int,
            flags : Int,
            vtScrollBarRes : String,
            hzScrollBarRes : String)
    {
        super();
        if (_easeTypeFunc == null) 
            _easeTypeFunc = EaseLookup.find("Cubic.easeOut");
        _throwTween = new ThrowTween();
        
        _owner = owner;
        owner.opaque = true;
        
        _scrollBarMargin = scrollBarMargin;
        _scrollType = scrollType;
        _scrollSpeed = UIConfig.defaultScrollSpeed;
        _mouseWheelSpeed = _scrollSpeed * 2;
        
        _displayOnLeft = (flags & 1) != 0;
        _snapToItem = (flags & 2) != 0;
        _displayInDemand = (flags & 4) != 0;
        _pageMode = (flags & 8) != 0;
        if ((flags & 16) > 0)
            _touchEffect = true
        else if ((flags & 32) > 0)
            _touchEffect = false
        else 
        _touchEffect = UIConfig.defaultScrollTouchEffect;
        if ((flags & 64) > 0)
            _bouncebackEffect = true
        else if ((flags & 128) > 0)
            _bouncebackEffect = false
        else 
        _bouncebackEffect = UIConfig.defaultScrollBounceEffect;

        _inertiaDisabled = (flags & 256) != 0;
        _maskDisabled = (flags & 512) != 0;
        
        if (scrollBarDisplay == ScrollBarDisplayType.Default) 
            scrollBarDisplay = UIConfig.defaultScrollBarDisplay;
        
        _xPerc = 0;
        _yPerc = 0;
        _xPos = 0;
        _yPos = 0;
        _xOverlap = 0;
        _yOverlap = 0;
        _scrollBarVisible = true;
        _mouseWheelEnabled = true;
        _holdAreaPoint = new Point();
        _pageSizeH = 1;
        _pageSizeV = 1;
        
        _maskContainer = new Sprite();
        _maskContainer.mouseEnabled = false;
        _owner._rootContainer.addChild(_maskContainer);
        
        _container = _owner._container;
        _container.x = 0;
        _container.y = 0;
        _container.mouseEnabled = false;
        _maskContainer.addChild(_container);
        
        if (!_maskDisabled) 
        {
            _mask = new Sprite();
            _mask.mouseEnabled = false;
            _mask.mouseChildren = false;
            _container.mask = _mask;
            _maskContainer.addChild(_mask);
        }
        var res : String;
        if (scrollBarDisplay != ScrollBarDisplayType.Hidden) 
        {
            if (_scrollType == ScrollType.Both || _scrollType == ScrollType.Vertical) 
            {
                res = (vtScrollBarRes != null) ? vtScrollBarRes : UIConfig.verticalScrollBar;
                if (res != null) 
                {
                    _vtScrollBar = try cast(UIPackage.createObjectFromURL(res), GScrollBar) catch(e:Dynamic) null;
                    if (_vtScrollBar == null) 
                        throw new Error("cannot create scrollbar from " + res);
                    _vtScrollBar.setScrollPane(this, true);
                    _owner._rootContainer.addChild(_vtScrollBar.displayObject);
                }
            }
            if (_scrollType == ScrollType.Both || _scrollType == ScrollType.Horizontal) 
            {
                res = (hzScrollBarRes != null) ? hzScrollBarRes : UIConfig.horizontalScrollBar;
                if (res != null)
                {
                    _hzScrollBar = try cast(UIPackage.createObjectFromURL(res), GScrollBar) catch(e:Dynamic) null;
                    if (_hzScrollBar == null) 
                        throw new Error("cannot create scrollbar from " + res);
                    _hzScrollBar.setScrollPane(this, false);
                    _owner._rootContainer.addChild(_hzScrollBar.displayObject);
                }
            }
            
            _scrollBarDisplayAuto = scrollBarDisplay == ScrollBarDisplayType.Auto;
            if (_scrollBarDisplayAuto) 
            {
                _scrollBarVisible = false;
                if (_vtScrollBar != null) 
                    _vtScrollBar.displayObject.visible = false;
                if (_hzScrollBar != null) 
                    _hzScrollBar.displayObject.visible = false;
                
                if (CompatUtil.supportsCursor)
                {
                    _owner._rootContainer.addEventListener(MouseEvent.ROLL_OVER, __rollOver);
                    _owner._rootContainer.addEventListener(MouseEvent.ROLL_OUT, __rollOut);
                }
            }
        }
        else 
            _mouseWheelEnabled = false;
        
        _contentWidth = 0;
        _contentHeight = 0;
        setSize(owner.width, owner.height);
        
        _owner._rootContainer.addEventListener(MouseEvent.MOUSE_WHEEL, __mouseWheel);
        _owner.addEventListener(GTouchEvent.BEGIN, __mouseDown);
        _owner.addEventListener(GTouchEvent.END, __mouseUp);
    }
    
    private function get_owner() : GComponent
    {
        return _owner;
    }
    
    private function get_bouncebackEffect() : Bool
    {
        return _bouncebackEffect;
    }
    
    private function set_bouncebackEffect(sc : Bool) : Bool
    {
        _bouncebackEffect = sc;
        return sc;
    }
    
    private function get_touchEffect() : Bool
    {
        return _touchEffect;
    }
    
    private function set_touchEffect(sc : Bool) : Bool
    {
        _touchEffect = sc;
        return sc;
    }
    
    private function set_scrollSpeed(val : Int) : Int
    {
        _scrollSpeed = val;
        if (_scrollSpeed == 0) 
            _scrollSpeed = UIConfig.defaultScrollSpeed;
        _mouseWheelSpeed = _scrollSpeed * 2;
        return val;
    }
    
    private function get_scrollSpeed() : Int
    {
        return _scrollSpeed;
    }
    
    private function get_snapToItem() : Bool
    {
        return _snapToItem;
    }
    
    private function set_snapToItem(value : Bool) : Bool
    {
        _snapToItem = value;
        return value;
    }
    
    private function get_mouseWheelEnabled() : Bool
    {
        return _mouseWheelEnabled;
    }
    
    private function set_mouseWheelEnabled(value : Bool) : Bool
    {
        _mouseWheelEnabled = value;
        return value;
    }
    
    private function get_percX() : Float
    {
        return _xPerc;
    }
    
    private function set_percX(value : Float) : Float
    {
        setPercX(value, false);
        return value;
    }
    
    public function setPercX(value : Float, ani : Bool = false) : Void
    {
        _owner.ensureBoundsCorrect();
        
        value = ToolSet.clamp01(value);
        if (value != _xPerc) 
        {
            _xPerc = value;
            _xPos = _xPerc * _xOverlap;
            posChanged(ani);
        }
    }
    
    private function get_percY() : Float
    {
        return _yPerc;
    }
    
    private function set_percY(value : Float) : Float
    {
        setPercY(value, false);
        return value;
    }
    
    public function setPercY(value : Float, ani : Bool = false) : Void
    {
        _owner.ensureBoundsCorrect();
        
        value = ToolSet.clamp01(value);
        if (value != _yPerc) 
        {
            _yPerc = value;
            _yPos = _yPerc * _yOverlap;
            posChanged(ani);
        }
    }
    
    private function get_posX() : Float
    {
        return _xPos;
    }
    
    private function set_posX(value : Float) : Float
    {
        setPosX(value, false);
        return value;
    }
    
    public function setPosX(value : Float, ani : Bool = false) : Void
    {
        if (value != _xPos) 
        {
            _xPos = ToolSet.clamp(value, 0, _xOverlap);
            _xPerc = (_xOverlap == 0) ? 0 : _xPos / _xOverlap;
            
            posChanged(ani);
        }
    }
    
    private function get_posY() : Float
    {
        return _yPos;
    }
    
    private function set_posY(value : Float) : Float
    {
        setPosY(value, false);
        return value;
    }
    
    public function setPosY(value : Float, ani : Bool = false) : Void
    {
        if (value != _yPos) 
        {
            _yPos = ToolSet.clamp(value, 0, _yOverlap);
            _yPerc = (_yOverlap == 0) ? 0 : _yPos / _yOverlap;
            
            posChanged(ani);
        }
    }
    
    private function get_isBottomMost() : Bool
    {
        return _yPerc == 1 || _yOverlap == 0;
    }
    
    private function get_isRightMost() : Bool
    {
        return _xPerc == 1 || _xOverlap == 0;
    }
    
    private function get_currentPageX() : Int
    {
        return (_pageMode) ? Math.floor(this.posX / _pageSizeH) : 0;
    }
    
    private function set_currentPageX(value : Int) : Int
    {
        if (_pageMode && _xOverlap > 0) 
            this.setPosX(value * _pageSizeH, false);
        return value;
    }
    
    private function get_currentPageY() : Int
    {
        return (_pageMode) ? Math.floor(this.posY / _pageSizeV) : 0;
    }
    
    private function set_currentPageY(value : Int) : Int
    {
        if (_pageMode && _yOverlap > 0) 
            this.setPosY(value * _pageSizeV, false);
        return value;
    }
    
    private function get_scrollingPosX() : Float
    {
        return ToolSet.clamp(-_container.x, 0, _xOverlap);
    }
    
    private function get_scrollingPosY() : Float
    {
        return ToolSet.clamp(-_container.y, 0, _yOverlap);
    }
    
    private function get_contentWidth() : Float
    {
        return _contentWidth;
    }
    
    private function get_contentHeight() : Float
    {
        return _contentHeight;
    }
    
    private function get_viewWidth() : Int
    {
        return Std.int(_viewWidth);
    }
    
    private function set_viewWidth(value : Int) : Int
    {
        value = value + _owner.margin.left + _owner.margin.right;
        if (_vtScrollBar != null) 
            value += Std.int(_vtScrollBar.width);
        _owner.width = value;
        return value;
    }
    
    private function get_viewHeight() : Int
    {
        return Std.int(_viewHeight);
    }
    
    private function set_viewHeight(value : Int) : Int
    {
        value = value + _owner.margin.top + _owner.margin.bottom;
        if (_hzScrollBar != null) 
            value += Std.int(_hzScrollBar.height);
        _owner.height = value;
        return value;
    }
    
    private function getDeltaX(move : Float) : Float
    {
        return (_pageMode ? _pageSizeH : move) / (_contentWidth - _viewWidth);
    }
    
    private function getDeltaY(move : Float) : Float
    {
        return (_pageMode ? _pageSizeV : move) / (_contentHeight - _viewHeight);
    }
    
    public function scrollTop(ani : Bool = false) : Void
    {
        this.setPercY(0, ani);
    }
    
    public function scrollBottom(ani : Bool = false) : Void
    {
        this.setPercY(1, ani);
    }
    
    public function scrollUp(speed : Float = 1, ani : Bool = false) : Void
    {
        this.setPercY(_yPerc - getDeltaY(_scrollSpeed * speed), ani);
    }
    
    public function scrollDown(speed : Float = 1, ani : Bool = false) : Void
    {
        this.setPercY(_yPerc + getDeltaY(_scrollSpeed * speed), ani);
    }
    
    public function scrollLeft(speed : Float = 1, ani : Bool = false) : Void
    {
        this.setPercX(_xPerc - getDeltaX(_scrollSpeed * speed), ani);
    }
    
    public function scrollRight(speed : Float = 1, ani : Bool = false) : Void
    {
        this.setPercX(_xPerc + getDeltaX(_scrollSpeed * speed), ani);
    }
    
    /**
     * @param target GObject: can be any object on stage, not limited to the direct child of this container.
     * 				or Rectangle: Rect in local coordinates
     * @param ani If moving to target position with animation
     * @param setFirst If true, scroll to make the target on the top/left; If false, scroll to make the target any position in view.
     */
    public function scrollToView(target : Dynamic, ani : Bool = false, setFirst : Bool = false) : Void
    {
        _owner.ensureBoundsCorrect();
        if (_needRefresh) 
            refresh();
        
        var rect : Rectangle;
        if (Std.is(target, GObject)) 
        {
            if (target.parent != _owner) 
            {
                cast(target, GObject).parent.localToGlobalRect(target.x, target.y,
                        target.width, target.height, sHelperRect);
                rect = _owner.globalToLocalRect(sHelperRect.x, sHelperRect.y,
                                sHelperRect.width, sHelperRect.height, sHelperRect);
            }
            else 
            {
                rect = sHelperRect;
                rect.setTo(target.x, target.y, target.width, target.height);
            }
        }
        else 
            rect = cast(target, Rectangle);
        
        
        if (_yOverlap > 0) 
        {
            var bottom : Float = _yPos + _viewHeight;
            if (setFirst || rect.y <= _yPos || rect.height >= _viewHeight) 
            {
                if (_pageMode) 
                    this.setPosY(Math.floor(rect.y / _pageSizeV) * _pageSizeV, ani)
                else 
                    this.setPosY(rect.y, ani);
            }
            else if (rect.y + rect.height > bottom) 
            {
                if (_pageMode) 
                    this.setPosY(Math.floor(rect.y / _pageSizeV) * _pageSizeV, ani)
                else if (rect.height <= _viewHeight / 2) 
                    this.setPosY(rect.y + rect.height * 2 - _viewHeight, ani)
                else 
                    this.setPosY(rect.y + rect.height - _viewHeight, ani);
            }
        }
        if (_xOverlap > 0) 
        {
            var right : Float = _xPos + _viewWidth;
            if (setFirst || rect.x <= _xPos || rect.width >= _viewWidth) 
            {
                if (_pageMode) 
                    this.setPosX(Math.floor(rect.x / _pageSizeH) * _pageSizeH, ani)
                else 
                    this.setPosX(rect.x, ani);
            }
            else if (rect.x + rect.width > right) 
            {
                if (_pageMode) 
                    this.setPosX(Math.floor(rect.x / _pageSizeH) * _pageSizeH, ani)
                else if (rect.width <= _viewWidth / 2) 
                    this.setPosX(rect.x + rect.width * 2 - _viewWidth, ani)
                else 
                    this.setPosX(rect.x + rect.width - _viewWidth, ani);
            }
        }
        
        if (!ani && _needRefresh) 
            refresh();
    }
    
    /**
     * @param obj obj must be the direct child of this container
     */
    public function isChildInView(obj : GObject) : Bool
    {
        var dist : Float;
        if (_yOverlap > 0) 
        {
            dist = obj.y + _container.y;
            if (dist < (-obj.height - 20) || dist > (_viewHeight + 20))
                return false;
        }
        
        if (_xOverlap > 0) 
        {
            dist = obj.x + _container.x;
            if (dist < (-obj.width - 20) || dist > (_viewWidth + 20))
                return false;
        }
        
        return true;
    }
    
    public function cancelDragging() : Void
    {
        _owner.removeEventListener(GTouchEvent.DRAG, __mouseMove);
        
        if (draggingPane == this) 
            draggingPane = null;
        
        _gestureFlag = 0;
        isDragged = false;
        _maskContainer.mouseChildren = true;

    }
    
    @:allow(fairygui)
    private function onOwnerSizeChanged() : Void
    {
        setSize(_owner.width, _owner.height);
        posChanged(false);
    }
    
    @:allow(fairygui)
    private function adjustMaskContainer() : Void
    {
        var mx : Float;
        var my : Float;
        if (_displayOnLeft && _vtScrollBar != null) 
            mx = Math.floor(_owner.margin.left + _vtScrollBar.width)
        else 
            mx = Math.floor(_owner.margin.left);

        my = Math.floor(_owner.margin.top);
        mx += _owner._alignOffset.x;
        my += _owner._alignOffset.y;
        
        _maskContainer.x = mx;
        _maskContainer.y = my;
    }
    
    private function setSize(aWidth : Float, aHeight : Float) : Void
    {
        adjustMaskContainer();
        
        if (_hzScrollBar != null) 
        {
            _hzScrollBar.y = aHeight - _hzScrollBar.height;
            if (_vtScrollBar != null) 
            {
                _hzScrollBar.width = aWidth - _vtScrollBar.width - _scrollBarMargin.left - _scrollBarMargin.right;
                if (_displayOnLeft) 
                    _hzScrollBar.x = _scrollBarMargin.left + _vtScrollBar.width
                else 
                    _hzScrollBar.x = _scrollBarMargin.left;
            }
            else 
            {
                _hzScrollBar.width = aWidth - _scrollBarMargin.left - _scrollBarMargin.right;
                _hzScrollBar.x = _scrollBarMargin.left;
            }
        }
        if (_vtScrollBar != null) 
        {
            if (!_displayOnLeft) 
                _vtScrollBar.x = aWidth - _vtScrollBar.width;
            if (_hzScrollBar != null) 
                _vtScrollBar.height = aHeight - _hzScrollBar.height - _scrollBarMargin.top - _scrollBarMargin.bottom
            else 
                _vtScrollBar.height = aHeight - _scrollBarMargin.top - _scrollBarMargin.bottom;

            _vtScrollBar.y = _scrollBarMargin.top;
        }
        
        _viewWidth = aWidth;
        _viewHeight = aHeight;
        if (_hzScrollBar != null && !_hScrollNone) 
            _viewHeight -= _hzScrollBar.height;
        if (_vtScrollBar != null && !_vScrollNone) 
            _viewWidth -= _vtScrollBar.width;
        _viewWidth -= (_owner.margin.left + _owner.margin.right);
        _viewHeight -= (_owner.margin.top + _owner.margin.bottom);
        
        _viewWidth = Math.max(1, _viewWidth);
        _viewHeight = Math.max(1, _viewHeight);
        _pageSizeH = _viewWidth;
        _pageSizeV = _viewHeight;
        
        handleSizeChanged();
    }
    
    @:allow(fairygui)
    private function setContentSize(aWidth : Float, aHeight : Float) : Void
    {
        if (_contentWidth == aWidth && _contentHeight == aHeight) 
            return;
        
        _contentWidth = aWidth;
        _contentHeight = aHeight;
        handleSizeChanged();
    }
    
    @:allow(fairygui)
    private function changeContentSizeOnScrolling(deltaWidth : Float, deltaHeight : Float,
            deltaPosX : Float, deltaPosY : Float) : Void
    {
        _contentWidth += deltaWidth;
        _contentHeight += deltaHeight;

        if (isDragged)
        {
            if (deltaPosX != 0) 
                _container.x -= deltaPosX;
            if (deltaPosY != 0) 
                _container.y -= deltaPosY;
            
            validateHolderPos();
            
            _xOffset += deltaPosX;
            _yOffset += deltaPosY;
            
            _y1 = _y2 = _container.y;
            _x1 = _x2 = _container.x;
            
            _yPos = -_container.y;
            _xPos = -_container.x;
        }
        else if (_tweening == 2) 
        {
            if (deltaPosX != 0) 
            {
                _container.x -= deltaPosX;
                _throwTween.start.x -= deltaPosX;
            }
            if (deltaPosY != 0) 
            {
                _container.y -= deltaPosY;
                _throwTween.start.y -= deltaPosY;
            }
        }
        
        handleSizeChanged(true);
    }
    
    private function handleSizeChanged(onScrolling : Bool = false) : Void
    {
        if (_displayInDemand) 
        {
            if (_vtScrollBar != null) 
            {
                if (_contentHeight <= _viewHeight) 
                {
                    if (!_vScrollNone) 
                    {
                        _vScrollNone = true;
                        _viewWidth += _vtScrollBar.width;
                    }
                }
                else 
                {
                    if (_vScrollNone) 
                    {
                        _vScrollNone = false;
                        _viewWidth -= _vtScrollBar.width;
                    }
                }
            }
            if (_hzScrollBar != null) 
            {
                if (_contentWidth <= _viewWidth) 
                {
                    if (!_hScrollNone) 
                    {
                        _hScrollNone = true;
                        _viewHeight += _vtScrollBar.height;
                    }
                }
                else 
                {
                    if (_hScrollNone) 
                    {
                        _hScrollNone = false;
                        _viewHeight -= _vtScrollBar.height;
                    }
                }
            }
        }
        
        if (_vtScrollBar != null) 
        {
            if (_viewHeight < _vtScrollBar.minSize) 
                //没有使用_vtScrollBar.visible是因为ScrollBar用了一个trick，它并不在owner的DisplayList里，因此_vtScrollBar.visible是无效的
            _vtScrollBar.displayObject.visible = false
            else 
            {
                _vtScrollBar.displayObject.visible = _scrollBarVisible && !_vScrollNone;
                if (_contentHeight == 0) 
                    _vtScrollBar.displayPerc = 0
                else 
                    _vtScrollBar.displayPerc = Math.min(1, _viewHeight / _contentHeight);
            }
        }
        if (_hzScrollBar != null) 
        {
            if (_viewWidth < _hzScrollBar.minSize) 
                _hzScrollBar.displayObject.visible = false
            else 
            {
                _hzScrollBar.displayObject.visible = _scrollBarVisible && !_hScrollNone;
                if (_contentWidth == 0) 
                    _hzScrollBar.displayPerc = 0
                else 
                    _hzScrollBar.displayPerc = Math.min(1, _viewWidth / _contentWidth);
            }
        }
        
        if (!_maskDisabled) 
        {
            var g : Graphics = _mask.graphics;
            g.clear();
            g.lineStyle(0, 0, 0);
            g.beginFill(0, 0);
            g.drawRect(-_owner._alignOffset.x, -_owner._alignOffset.y, _viewWidth, _viewHeight);
            g.endFill();
        }
        
        if (_scrollType == ScrollType.Horizontal || _scrollType == ScrollType.Both) 
            _xOverlap = Math.ceil(Math.max(0, _contentWidth - _viewWidth))
        else 
        _xOverlap = 0;
        if (_scrollType == ScrollType.Vertical || _scrollType == ScrollType.Both) 
            _yOverlap = Math.ceil(Math.max(0, _contentHeight - _viewHeight))
        else 
        _yOverlap = 0;
        
        if (_tweening == 0 && onScrolling) 
        {
            //如果原来是在边缘，且不在缓动状态，那么尝试继续贴边。（如果在缓动状态，需要修改tween的终值，暂时未支持）
            if (_xPerc == 0 || _xPerc == 1) 
            {
                _xPos = _xPerc * _xOverlap;
                _container.x = -_xPos;
            }
            if (_yPerc == 0 || _yPerc == 1) 
            {
                _yPos = _yPerc * _yOverlap;
                _container.y = -_yPos;
            }
        }
        else 
        {
            //边界检查
            _xPos = ToolSet.clamp(_xPos, 0, _xOverlap);
            _xPerc = (_xOverlap > 0) ? _xPos / _xOverlap : 0;
            
            _yPos = ToolSet.clamp(_yPos, 0, _yOverlap);
            _yPerc = (_yOverlap > 0) ? _yPos / _yOverlap : 0;
        }
        
        validateHolderPos();
        
        if (_vtScrollBar != null) 
            _vtScrollBar.scrollPerc = _yPerc;
        if (_hzScrollBar != null) 
            _hzScrollBar.scrollPerc = _xPerc;
    }
    
    private function validateHolderPos() : Void
    {
        _container.x = ToolSet.clamp(_container.x, -_xOverlap, 0);
        _container.y = ToolSet.clamp(_container.y, -_yOverlap, 0);
    }
    
    private function posChanged(ani : Bool) : Void
    {
        if (_aniFlag == 0) 
            _aniFlag = (ani) ? 1 : -1
        else if (_aniFlag == 1 && !ani) 
            _aniFlag = -1;
        
        _needRefresh = true;
        GTimers.inst.callLater(refresh);
        
        //如果在甩手指滚动过程中用代码重新设置滚动位置，要停止滚动
        if (_tweening == 2) 
            killTween();
    }
    
    private function killTween() : Void
    {
        if (_tweening == 1) 
        {
            _tweener.goto(_tweener.totalTime, true);
        }
        else if (_tweening == 2) 
        {
            _tweener.stop();
            _tweener = null;
            _tweening = 0;
            
            validateHolderPos();
            syncScrollBar(true);
            dispatchEvent(new Event(SCROLL_END));
        }
    }
    
    private function refresh() : Void
    {
        _needRefresh = false;
        GTimers.inst.remove(refresh);
        
        if (_pageMode) 
        {
            var page : Int;
            var delta : Float;
            if (_yOverlap > 0 && _yPerc != 1 && _yPerc != 0) 
            {
                page = Math.floor(_yPos / _pageSizeV);
                delta = _yPos - page * _pageSizeV;
                if (delta > _pageSizeV / 2) 
                    page++;
                _yPos = page * _pageSizeV;
                if (_yPos > _yOverlap) 
                {
                    _yPos = _yOverlap;
                    _yPerc = 1;
                }
                else 
                    _yPerc = _yPos / _yOverlap;
            }
            
            if (_xOverlap > 0 && _xPerc != 1 && _xPerc != 0)
            {
                page = Math.floor(_xPos / _pageSizeH);
                delta = _xPos - page * _pageSizeH;
                if (delta > _pageSizeH / 2) 
                    page++;
                _xPos = page * _pageSizeH;
                if (_xPos > _xOverlap) 
                {
                    _xPos = _xOverlap;
                    _xPerc = 1;
                }
                else 
                    _xPerc = _xPos / _xOverlap;
            }
        }
        else if (_snapToItem) 
        {
            var pt : Point = _owner.getSnappingPosition((_xPerc == 1) ? 0 : _xPos, (_yPerc == 1) ? 0 : _yPos, sHelperPoint);
            if (_xPerc != 1 && pt.x != _xPos) 
            {
                _xPos = pt.x;
                _xPerc = _xPos / _xOverlap;
                if (_xPerc > 1) 
                {
                    _xPerc = 1;
                    _xPos = _xOverlap;
                }
            }
            if (_yPerc != 1 && pt.y != _yPos) 
            {
                _yPos = pt.y;
                _yPerc = _yPos / _yOverlap;
                if (_yPerc > 1) 
                {
                    _yPerc = 1;
                    _yPos = _yOverlap;
                }
            }
        }
        
        refresh2();
        
        dispatchEvent(new Event(Event.SCROLL));
        
        if (_needRefresh)   //user change scroll pos in on scroll  
        {
            _needRefresh = false;
            GTimers.inst.remove(refresh);
            
            refresh2();
        }
        _aniFlag = 0;
    }
    
    private function refresh2() : Void
    {
        var contentXLoc : Int = Std.int(_xPos);
        var contentYLoc : Int = Std.int(_yPos);
        
        if (_aniFlag == 1 && !isDragged)
        {
            var toX : Float = _container.x;
            var toY : Float = _container.y;
            
            if (_yOverlap > 0) 
            {
                toY = -contentYLoc;
            }
            else 
            {
                if (_container.y != 0) 
                    _container.y = 0;
            }
            if (_xOverlap > 0) 
            {
                toX = -contentXLoc;
            }
            else 
            {
                if (_container.x != 0) 
                    _container.x = 0;
            }
            
            if (toX != _container.x || toY != _container.y) 
            {
                if (_tweener != null) 
                    _tweener.stop();
                
                _maskContainer.mouseChildren = false;
                _tweening = 1;
                _tweener = TweenX.to(_container, {
                                    x : toX,
                                    y : toY
                                    },0.5).ease(_easeTypeFunc).onUpdate(__tweenUpdate).onFinish(__tweenComplete);
            }
        }
        else 
        {
            if (_tweener != null) 
                killTween();


            //如果在拖动的过程中Refresh，这里要进行处理，保证拖动继续正常进行
            if (isDragged)
            {
                _xOffset += _container.x - (-contentXLoc);
                _yOffset += _container.y - (-contentYLoc);
            }
            
            _container.y = -contentYLoc;
            _container.x = -contentXLoc;
            
            //如果在拖动的过程中Refresh，这里要进行处理，保证手指离开是滚动正常进行
            if (isDragged)
            {
                _y1 = _y2 = _container.y;
                _x1 = _x2 = _container.x;
            }
            
            if (_vtScrollBar != null) 
                _vtScrollBar.scrollPerc = _yPerc;
            if (_hzScrollBar != null) 
                _hzScrollBar.scrollPerc = _xPerc;
        }
    }
    
    private function syncPos() : Void
    {
        if (_xOverlap > 0) 
        {
            _xPos = ToolSet.clamp(-_container.x, 0, _xOverlap);
            _xPerc = _xPos / _xOverlap;
        }
        
        if (_yOverlap > 0) 
        {
            _yPos = ToolSet.clamp(-_container.y, 0, _yOverlap);
            _yPerc = _yPos / _yOverlap;
        }
    }
    
    private function syncScrollBar(end : Bool = false) : Void
    {
        if (end) 
        {
            if (_vtScrollBar != null) 
            {
                if (_scrollBarDisplayAuto) 
                    showScrollBar(false);
            }
            if (_hzScrollBar != null) 
            {
                if (_scrollBarDisplayAuto) 
                    showScrollBar(false);
            }
            _maskContainer.mouseChildren = true;
        }
        else 
        {
            if (_vtScrollBar != null) 
            {
                _vtScrollBar.scrollPerc = (_yOverlap == 0) ? 0 : ToolSet.clamp(-_container.y, 0, _yOverlap) / _yOverlap;
                if (_scrollBarDisplayAuto) 
                    showScrollBar(true);
            }
            if (_hzScrollBar != null) 
            {
                _hzScrollBar.scrollPerc = (_xOverlap == 0) ? 0 : ToolSet.clamp(-_container.x, 0, _xOverlap) / _xOverlap;
                if (_scrollBarDisplayAuto) 
                    showScrollBar(true);
            }
        }
    }
    
    private function __mouseDown(e : Event) : Void
    {
        if (!_touchEffect) 
            return;
        
        if (_tweener != null) 
            killTween();
        
        _x1 = _x2 = _container.x;
        _y1 = _y2 = _container.y;
        
        _xOffset = _maskContainer.mouseX - _container.x;
        _yOffset = _maskContainer.mouseY - _container.y;
        
        _time1 = _time2 = Math.round(haxe.Timer.stamp() * 1000);
        _holdAreaPoint.x = _maskContainer.mouseX;
        _holdAreaPoint.y = _maskContainer.mouseY;
        _isHoldAreaDone = false;
        isDragged = false;
        
        _owner.addEventListener(GTouchEvent.DRAG, __mouseMove);
    }
    
    private function __mouseMove(e : GTouchEvent) : Void
    {
        if (!_touchEffect) 
            return;
        
        if (draggingPane != null && draggingPane != this || GObject.draggingObject != null) //已经有其他拖动
            return;
        
        var sensitivity : Int;
        if (GRoot.touchScreen) 
            sensitivity = UIConfig.touchScrollSensitivity
        else 
            sensitivity = 8;
        
        var diff : Float;
        var diff2 : Float;
        var sv : Bool = false;
        var sh : Bool = false;
        var st : Bool = false;
        
        if (_scrollType == ScrollType.Vertical) 
        {
            if (!_isHoldAreaDone) 
            {
                //表示正在监测垂直方向的手势
                _gestureFlag |= 1;
                
                diff = Math.abs(_holdAreaPoint.y - _maskContainer.mouseY);
                if (diff < sensitivity) 
                    return;
                
                if ((_gestureFlag & 2) != 0)   //已经有水平方向的手势在监测，那么我们用严格的方式检查是不是按垂直方向移动，避免冲突  
                {
                    diff2 = Math.abs(_holdAreaPoint.x - _maskContainer.mouseX);
                    if (diff < diff2) //不通过则不允许滚动了
                        return;
                }
            }
            
            sv = true;
        }
        else if (_scrollType == ScrollType.Horizontal) 
        {
            if (!_isHoldAreaDone) 
            {
                _gestureFlag |= 2;
                
                diff = Math.abs(_holdAreaPoint.x - _maskContainer.mouseX);
                if (diff < sensitivity) 
                    return;
                
                if ((_gestureFlag & 1) != 0) 
                {
                    diff2 = Math.abs(_holdAreaPoint.y - _maskContainer.mouseY);
                    if (diff < diff2) 
                        return;
                }
            }
            
            sh = true;
        }
        else 
        {
            _gestureFlag = 3;
            
            if (!_isHoldAreaDone) 
            {
                diff = Math.abs(_holdAreaPoint.y - _maskContainer.mouseY);
                if (diff < sensitivity) 
                {
                    diff = Math.abs(_holdAreaPoint.x - _maskContainer.mouseX);
                    if (diff < sensitivity) 
                        return;
                }
            }
            
            sv = sh = true;
        }
        
        var t : UInt = Math.round(haxe.Timer.stamp() * 1000);
        if (t - _time2 > 50) 
        {
            _time2 = _time1;
            _time1 = t;
            st = true;
        }
        
        if (sv) 
        {
            var y : Int = Std.int(_maskContainer.mouseY - _yOffset);
            if (y > 0) 
            {
                if (!_bouncebackEffect || _inertiaDisabled) 
                    _container.y = 0
                else 
                _container.y = Std.int(y * 0.5);
            }
            else if (y < -_yOverlap) 
            {
                if (!_bouncebackEffect || _inertiaDisabled) 
                    _container.y = -Std.int(_yOverlap)
                else 
                _container.y = Std.int((y - _yOverlap) * 0.5);
            }
            else 
            {
                _container.y = y;
            }
            
            if (st) 
            {
                _y2 = _y1;
                _y1 = _container.y;
            }
        }
        
        if (sh) 
        {
            var x : Int = Std.int(_maskContainer.mouseX - _xOffset);
            if (x > 0) 
            {
                if (!_bouncebackEffect || _inertiaDisabled) 
                    _container.x = 0
                else 
                _container.x = Std.int(x * 0.5);
            }
            else if (x < 0 - _xOverlap) 
            {
                if (!_bouncebackEffect || _inertiaDisabled) 
                    _container.x = -Std.int(_xOverlap)
                else 
                _container.x = Std.int((x - _xOverlap) * 0.5);
            }
            else 
            {
                _container.x = x;
            }
            
            if (st) 
            {
                _x2 = _x1;
                _x1 = _container.x;
            }
        }
        
        draggingPane = this;
        _maskContainer.mouseChildren = false;
        _isHoldAreaDone = true;
        isDragged = true;
        
        syncPos();
        syncScrollBar();
        
        dispatchEvent(new Event(Event.SCROLL));
    }
    
    private function __mouseUp(e : Event) : Void
    {
        _owner.removeEventListener(GTouchEvent.DRAG, __mouseMove);
        
        if (draggingPane == this) 
            draggingPane = null;
        
        _gestureFlag = 0;
        
        if (!isDragged || !_touchEffect || _inertiaDisabled)
        {
            isDragged = false;
            return;
        }

        isDragged = false;
        var time : Float = (Math.round(haxe.Timer.stamp() * 1000) - _time2) / 1000;
        if (time == 0) 
            time = 0.001;
        var yVelocity : Float = (_container.y - _y2) / time;
        var xVelocity : Float = (_container.x - _x2) / time;
        var duration : Float = 0.3;
        
        _throwTween.start.x = _container.x;
        _throwTween.start.y = _container.y;
        
        var change1 : Point = _throwTween.change1;
        var change2 : Point = _throwTween.change2;
        var endX : Float = 0;
        var endY : Float = 0;
        var page : Int;
        var delta : Float;
        var fireRelease : Int = 0;
        var testPageSize : Float;
        
        if (_scrollType == ScrollType.Both || _scrollType == ScrollType.Horizontal) 
        {
            if (_container.x > UIConfig.touchDragSensitivity) 
                fireRelease = 1
            else if (_container.x < -_xOverlap - UIConfig.touchDragSensitivity) 
                fireRelease = 2;
            
            change1.x = ThrowTween.calculateChange(xVelocity, duration);
            change2.x = 0;
            endX = _container.x + change1.x;
            
            if (_pageMode && endX < 0 && endX > -_xOverlap) 
            {
                page = Math.floor(-endX / _pageSizeH);
                testPageSize = Math.min(_pageSizeH, _contentWidth - (page + 1) * _pageSizeH);
                delta = -endX - page * _pageSizeH;
                //页面吸附策略
                if (Math.abs(change1.x) > _pageSizeH)   //如果滚动距离超过1页,则需要超过页面的一半，才能到更下一页  
                {
                    if (delta > testPageSize * 0.5) 
                        page++;
                }
                //否则只需要页面的1/3，当然，需要考虑到左移和右移的情况
                else 
                {
                    if (delta > testPageSize * ((change1.x < 0) ? 0.3 : 0.7)) 
                        page++;
                }  //重新计算终点  
                
                
                
                endX = -page * _pageSizeH;
                if (endX < -_xOverlap) //最后一页未必有_pageSizeH那么大
                 endX = -_xOverlap;
                
                change1.x = endX - _container.x;
            }
        }
        else 
            change1.x = change2.x = 0;
        
        if (_scrollType == ScrollType.Both || _scrollType == ScrollType.Vertical) 
        {
            if (_container.y > UIConfig.touchDragSensitivity) 
                fireRelease = 1
            else if (_container.y < -_yOverlap - UIConfig.touchDragSensitivity) 
                fireRelease = 2;
            
            change1.y = ThrowTween.calculateChange(yVelocity, duration);
            change2.y = 0;
            endY = _container.y + change1.y;
            
            if (_pageMode && endY < 0 && endY > -_yOverlap) 
            {
                page = Math.floor(-endY / _pageSizeV);
                testPageSize = Math.min(_pageSizeV, _contentHeight - (page + 1) * _pageSizeV);
                delta = -endY - page * _pageSizeV;
                if (Math.abs(change1.y) > _pageSizeV) 
                {
                    if (delta > testPageSize * 0.5) 
                        page++;
                }
                else 
                {
                    if (delta > testPageSize * ((change1.y < 0) ? 0.3 : 0.7)) 
                        page++;
                }
                
                endY = -page * _pageSizeV;
                if (endY < -_yOverlap) 
                    endY = -_yOverlap;
                
                change1.y = endY - _container.y;
            }
        }
        else 
            change1.y = change2.y = 0;
        
        if (_snapToItem && !_pageMode) 
        {
            endX = -endX;
            endY = -endY;
            var pt : Point = _owner.getSnappingPosition(endX, endY, sHelperPoint);
            endX = -pt.x;
            endY = -pt.y;
            change1.x = endX - _container.x;
            change1.y = endY - _container.y;
        }
        
        if (_bouncebackEffect) 
        {
            if (endX > 0) 
                change2.x = 0 - _container.x - change1.x
            else if (endX < -_xOverlap) 
                change2.x = -_xOverlap - _container.x - change1.x;
            
            if (endY > 0) 
                change2.y = 0 - _container.y - change1.y
            else if (endY < -_yOverlap) 
                change2.y = -_yOverlap - _container.y - change1.y;
        }
        else 
        {
            if (endX > 0) 
                change1.x = 0 - _container.x
            else if (endX < -_xOverlap) 
                change1.x = -_xOverlap - _container.x;
            
            if (endY > 0) 
                change1.y = 0 - _container.y
            else if (endY < -_yOverlap) 
                change1.y = -_yOverlap - _container.y;
        }
        
        _throwTween.value = 0;
        _throwTween.change1 = change1;
        _throwTween.change2 = change2;
        
        if (_tweener != null) 
            killTween();
        
        _tweening = 2;
        _tweener = TweenX.to(_throwTween,
                                {value : 1},
                                duration).ease(_easeTypeFunc).onUpdate(__tweenUpdate2).onFinish(__tweenComplete2);

        if (fireRelease == 1) 
            dispatchEvent(new Event(PULL_DOWN_RELEASE))
        else if (fireRelease == 2) 
            dispatchEvent(new Event(PULL_UP_RELEASE));
    }
    
    private function __mouseWheel(evt : MouseEvent) : Void
    {
        if (!_mouseWheelEnabled) 
            return;
        
        var delta : Float = evt.delta;
        if (_xOverlap > 0 && _yOverlap == 0) 
        {
            if (delta < 0) 
                this.setPercX(_xPerc + getDeltaX(_mouseWheelSpeed), false)
            else 
                this.setPercX(_xPerc - getDeltaX(_mouseWheelSpeed), false);
        }
        else 
        {
            if (delta < 0) 
                this.setPercY(_yPerc + getDeltaY(_mouseWheelSpeed), false)
            else 
                this.setPercY(_yPerc - getDeltaY(_mouseWheelSpeed), false);
        }
    }
    
    private function __rollOver(evt : Event) : Void
    {
        showScrollBar(true);
    }
    
    private function __rollOut(evt : Event) : Void
    {
        showScrollBar(false);
    }
    
    private function showScrollBar(val : Bool) : Void
    {
        if (val) 
        {
            __showScrollBar(true);
            GTimers.inst.remove(__showScrollBar);
        }
        else 
            GTimers.inst.add(500, 1, __showScrollBar, val);
    }
    
    private function __showScrollBar(val : Bool) : Void
    {
        _scrollBarVisible = val && _viewWidth > 0 && _viewHeight > 0;
        if (_vtScrollBar != null) 
            _vtScrollBar.displayObject.visible = _scrollBarVisible && !_vScrollNone;
        if (_hzScrollBar != null) 
            _hzScrollBar.displayObject.visible = _scrollBarVisible && !_hScrollNone;
    }
    
    private function __tweenUpdate() : Void
    {
        syncScrollBar();
        
        dispatchEvent(new Event(Event.SCROLL));
    }
    
    private function __tweenComplete() : Void
    {
        _tweener = null;
        _tweening = 0;
        
        validateHolderPos();
        syncScrollBar(true);
        
        dispatchEvent(new Event(Event.SCROLL));
    }
    
    private function __tweenUpdate2() : Void
    {
        _throwTween.update(_container);
        
        syncPos();
        syncScrollBar();
        
        dispatchEvent(new Event(Event.SCROLL));
    }
    
    private function __tweenComplete2() : Void
    {
        _tweener = null;
        _tweening = 0;
        
        validateHolderPos();
        syncPos();
        syncScrollBar(true);
        
        dispatchEvent(new Event(Event.SCROLL));
        dispatchEvent(new Event(SCROLL_END));
    }
}


class ThrowTween
{
    public var value : Float;
    public var start : Point;
    public var change1 : Point;
    public var change2 : Point;
    
    private static var checkpoint : Float = 0.05;
    
    public function new()
    {
        start = new Point();
        change1 = new Point();
        change2 = new Point();
    }
    
    public function update(obj : DisplayObject) : Void
    {
        obj.x = Std.int(start.x + change1.x * value + change2.x * value * value);
        obj.y = Std.int(start.y + change1.y * value + change2.y * value * value);
    }
    
    public static function calculateChange(velocity : Float, duration : Float) : Float
    {
        return (duration * checkpoint * velocity) / easeOutCubic(checkpoint, 0, 1, 1);
    }
    
    public static function easeOutCubic(t : Float, b : Float, c : Float, d : Float) : Float
    {
        return c * ((t = t / d - 1) * t * t + 1) + b;
    }
}

