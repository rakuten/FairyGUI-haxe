package fairygui;

import fairygui.event.DragEvent;
import fairygui.event.GTouchEvent;
import fairygui.event.IBubbleEvent;
import fairygui.GProgressBar;
import fairygui.GRichTextField;
import fairygui.GRoot;
import fairygui.GSlider;
import fairygui.GTextField;
import fairygui.GTextInput;
import fairygui.PackageItem;
import fairygui.Relations;
import fairygui.utils.ColorMatrix;
import fairygui.utils.CompatUtil;
import fairygui.utils.GTimers;
import fairygui.utils.SimpleDispatcher;
import fairygui.utils.ToolSet;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.InteractiveObject;
import openfl.display.Stage;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.MouseEvent;
import openfl.events.TouchEvent;
import openfl.filters.ColorMatrixFilter;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.Lib;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import Reflect;

@:meta(Event(name = "startDrag", type = "fairygui.event.DragEvent"))

@:meta(Event(name = "endDrag", type = "fairygui.event.DragEvent"))

@:meta(Event(name = "dragMoving", type = "fairygui.event.DragEvent"))

@:meta(Event(name = "beginGTouch", type = "fairygui.event.GTouchEvent"))

@:meta(Event(name = "endGTouch", type = "fairygui.event.GTouchEvent"))

@:meta(Event(name = "dragGTouch", type = "fairygui.event.GTouchEvent"))

@:meta(Event(name = "clickGTouch", type = "fairygui.event.GTouchEvent"))

class GObject extends EventDispatcher
{
    public var id(get, never):String;
    @:isVar public var name(get, set):String;
    @:isVar public var x(get, set):Float;
    @:isVar public var y(get, set):Float;
    @:isVar public var pixelSnapping(get, set):Bool;
    @:isVar public var width(get, set):Float;
    @:isVar public var height(get, set):Float;
    public var actualWidth(get, never):Float;
    public var actualHeight(get, never):Float;
    @:isVar public var scaleX(get, set):Float;
    @:isVar public var scaleY(get, set):Float;
    public var pivotX(get, set):Float;
    public var pivotY(get, set):Float;
    public var touchable(get, set):Bool;
    public var grayed(get, set):Bool;
    public var enabled(get, set):Bool;
    @:isVar public var rotation(get, set):Float;
    public var normalizeRotation(get, never):Float;
    @:isVar public var alpha(get, set):Float;
    @:isVar public var visible(get, set):Bool;
//    public var finalVisible(get, never):Bool;
    public var internalVisible(get, never):Bool;
    public var internalVisible2(get, never):Bool;
    public var sortingOrder(get, set):Int;
    public var focusable(get, set):Bool;
    public var focused(get, never):Bool;
    public var tooltips(get, set):String;
    @:isVar public var blendMode(get, set):String;
    public var filters(get, set):Array<Dynamic>;
    public var inContainer(get, never):Bool;
    public var onStage(get, never):Bool;
    public var resourceURL(get, never):String;
    public var group(get, set):GGroup;
    public var gearXY(get, never):GearXY;
    public var gearSize(get, never):GearSize;
    public var gearLook(get, never):GearLook;
    public var relations(get, never):Relations;
    public var displayObject(get, never):DisplayObject;
    @:isVar public var parent(get, set):GComponent;
    public var root(get, never):GRoot;
    public var asCom(get, never):GComponent;
    public var asButton(get, never):GButton;
    public var asLabel(get, never):GLabel;
    public var asProgress(get, never):GProgressBar;
    public var asTextField(get, never):GTextField;
    public var asRichTextField(get, never):GRichTextField;
    public var asTextInput(get, never):GTextInput;
    public var asLoader(get, never):GLoader;
    public var asList(get, never):GList;
    public var asGraph(get, never):GGraph;
    public var asGroup(get, never):GGroup;
    public var asSlider(get, never):GSlider;
    public var asComboBox(get, never):GComboBox;
    public var asImage(get, never):GImage;
    public var asMovieClip(get, never):GMovieClip;
    public var text(get, set):String;
    public var icon(get, set):String;
    public var draggable(get, set):Bool;
    public var dragBounds(get, set):Rectangle;
    public var dragging(get, never):Bool;
    public var isDown(get, never):Bool;

    @:isVar public var data(get, set):Dynamic;
    private var _data:Dynamic;

    public var packageItem:PackageItem;
    public static var draggingObject:GObject;

    public var sourceWidth:Float;
    public var sourceHeight:Float;
    public var initWidth:Float;
    public var initHeight:Float;
    public var minWidth:Float;
    public var minHeight:Float;
    public var maxWidth:Float;
    public var maxHeight:Float;

    private var _x:Float;
    private var _y:Float;
    private var _alpha:Float;
    private var _rotation:Float;
    private var _visible:Bool;
    private var _touchable:Bool;
    private var _grayed:Bool = false;
    private var _draggable:Bool = false;
    private var _scaleX:Float;
    private var _scaleY:Float;
    private var _pivotX:Float;
    private var _pivotY:Float;
    private var _pivotAsAnchor:Bool = false;
    private var _pivotOffsetX:Float;
    private var _pivotOffsetY:Float;
    private var _sortingOrder:Int = 0;
    private var _internalVisible:Bool;
    private var _handlingController:Bool;
    private var _focusable:Bool = false;
    private var _tooltips:String;
    private var _pixelSnapping:Bool = false;

    private var _relations:Relations;
    private var _group:GGroup;
    private var _gears:Array<GearBase>;
    private var _displayObject:DisplayObject;
    private var _dragBounds:Rectangle;

    private var _yOffset:Int = 0;
    //Size的实现方式，有两种，0-GObject的w/h等于DisplayObject的w/h。1-GObject的sourceWidth/sourceHeight等于DisplayObject的w/h，剩余部分由scale实现
    private var _sizeImplType:Int = 0;

    @:allow(fairygui)
    private var _parent:GComponent;
    @:allow(fairygui)
    private var _dispatcher:SimpleDispatcher;
    @:allow(fairygui)
    private var _width:Float;
    @:allow(fairygui)
    private var _height:Float;
    @:allow(fairygui)
    private var _rawWidth:Float;
    @:allow(fairygui)
    private var _rawHeight:Float;
    @:allow(fairygui)
    private var _id:String;
    @:allow(fairygui)
    private var _name:String;
    @:allow(fairygui)
    private var _underConstruct:Bool = false;
    @:allow(fairygui)
    private var _gearLocked:Bool = false;
    @:allow(fairygui)
    private var _sizePercentInGroup:Float;

    @:allow(fairygui)
    private static var _gInstanceCounter:Int = 0;

    @:allow(fairygui)
    private static inline var XY_CHANGED:Int = 1;
    @:allow(fairygui)
    private static inline var SIZE_CHANGED:Int = 2;
    @:allow(fairygui)
    private static inline var SIZE_DELAY_CHANGE:Int = 3;

    public function new()
    {
        super();
        _x = 0;
        _y = 0;
        _width = 0;
        _height = 0;
        _rawWidth = 0;
        _rawHeight = 0;
        sourceWidth = 0;
        sourceHeight = 0;
        initWidth = 0;
        initHeight = 0;
        minWidth = 0;
        minHeight = 0;
        maxWidth = 0;
        maxHeight = 0;
        _id = "_n" + _gInstanceCounter++;
        _name = "";
        _alpha = 1;
        _rotation = 0;
        _visible = true;
        _internalVisible = true;
        _touchable = true;
        _scaleX = 1;
        _scaleY = 1;
        _pivotX = 0;
        _pivotY = 0;
        _pivotOffsetX = 0;
        _pivotOffsetY = 0;

        createDisplayObject();

        _relations = new Relations(this);
        _dispatcher = new SimpleDispatcher();
        this._gears = new Array<GearBase>();
    }

    @:final private function get_id():String
    {
        return _id;
    }

    @:final private function get_name():String
    {
        return _name;
    }

    @:final private function set_name(value:String):String
    {
        _name = value;
        return value;
    }

    @:final private function set_data(value:Dynamic):Dynamic
    {
        _data = value;
        return value;
    }

    @:final private function get_data():Dynamic
    {
        return _data;
    }

    @:final private function get_x():Float
    {
        return _x;
    }

    @:final private function set_x(value:Float):Float
    {
        setXY(value, _y);
        return value;
    }

    @:final private function get_y():Float
    {
        return _y;
    }

    @:final private function set_y(value:Float):Float
    {
        setXY(_x, value);
        return value;
    }

    @:final public function setXY(xv:Float, yv:Float):Void
    {
        if (_x != xv || _y != yv)
        {
            var dx:Float = xv - _x;
            var dy:Float = yv - _y;
            _x = xv;
            _y = yv;

            handlePositionChanged();
            if (Std.is(this, GGroup))
                cast(this, GGroup).moveChildren(dx, dy);

            updateGear(1);

            if (parent != null && !Std.is(parent, GList))
            {
                _parent.setBoundsChangedFlag();
                if (_group != null)
                    _group.setBoundsChangedFlag();
                _dispatcher.dispatch(this, XY_CHANGED);
            }

            if (draggingObject == this && !sUpdateInDragging)
                this.localToGlobalRect(0, 0, this.width, this.height, sGlobalRect);
        }
    }

    private function get_pixelSnapping():Bool
    {
        return _pixelSnapping;
    }

    private function set_pixelSnapping(value:Bool):Bool
    {
        if (_pixelSnapping != value)
        {
            _pixelSnapping = value;
            handlePositionChanged();
        }
        return value;
    }

    public function center(restraint:Bool = false):Void
    {
        var r:GComponent;
        if (parent != null)
            r = parent;
        else
            r = this.root;

        this.setXY(Std.int((r.width - this.width) / 2), Std.int((r.height - this.height) / 2));
        if (restraint)
        {
            this.addRelation(r, RelationType.Center_Center);
            this.addRelation(r, RelationType.Middle_Middle);
        }
    }

    @:final private function get_width():Float
    {
        if (!this._underConstruct)
        {
            ensureSizeCorrect();
            if (_relations.sizeDirty)
                _relations.ensureRelationsSizeCorrect();
        }
        return _width;
    }

    @:final private function set_width(value:Float):Float
    {
        setSize(value, _rawHeight);
        return value;
    }

    @:final private function get_height():Float
    {
        if (!this._underConstruct)
        {
            ensureSizeCorrect();
            if (_relations.sizeDirty)
                _relations.ensureRelationsSizeCorrect();
        }
        return _height;
    }

    @:final private function set_height(value:Float):Float
    {
        setSize(_rawWidth, value);
        return value;
    }

    public function setSize(wv:Float, hv:Float, ignorePivot:Bool = false):Void
    {
        if (_rawWidth != wv || _rawHeight != hv)
        {
            _rawWidth = wv;
            _rawHeight = hv;
            if (wv < minWidth)
                wv = minWidth;
            if (hv < minHeight)
                hv = minHeight;
            if (maxWidth > 0 && wv > maxWidth)
                wv = maxWidth;
            if (maxHeight > 0 && hv > maxHeight)
                hv = maxHeight;
            var dWidth:Float = wv - _width;
            var dHeight:Float = hv - _height;

            _width = wv;
            _height = hv;

            handleSizeChanged();
            if (_pivotX != 0 || _pivotY != 0)
            {
                if (!_pivotAsAnchor)
                {
                    if (!ignorePivot)
                        this.setXY(this.x - _pivotX * dWidth, this.y - _pivotY * dHeight);
                    updatePivotOffset();
                }
                else
                {
                    applyPivot();
                }
            }

            if (Std.is(this, GGroup))
                cast(this, GGroup).resizeChildren(dWidth, dHeight);

            updateGear(2);

            if (_parent != null)
            {
                _parent.setBoundsChangedFlag();
                _relations.onOwnerSizeChanged(dWidth, dHeight);
                if (_group != null)
                    _group.setBoundsChangedFlag(true);
            }

            _dispatcher.dispatch(this, SIZE_CHANGED);
        }
    }

    public function ensureSizeCorrect():Void
    {
    }

    @:final private function get_actualWidth():Float
    {
        return this.width * _scaleX;
    }

    @:final private function get_actualHeight():Float
    {
        return this.height * _scaleY;
    }

    @:final private function get_scaleX():Float
    {
        return _scaleX;
    }

    @:final private function set_scaleX(value:Float):Float
    {
        setScale(value, _scaleY);
        return value;
    }

    @:final private function get_scaleY():Float
    {
        return _scaleY;
    }

    @:final private function set_scaleY(value:Float):Float
    {
        setScale(_scaleX, value);
        return value;
    }

    @:final public function setScale(sx:Float, sy:Float):Void
    {
        if (_scaleX != sx || _scaleY != sy)
        {
            _scaleX = sx;
            _scaleY = sy;
            handleScaleChanged();
            applyPivot();

            updateGear(2);
        }
    }

    @:final private function get_pivotX():Float
    {
        return _pivotX;
    }

    @:final private function set_pivotX(value:Float):Float
    {
        setPivot(value, _pivotY);
        return value;
    }

    @:final private function get_pivotY():Float
    {
        return _pivotY;
    }

    @:final private function set_pivotY(value:Float):Float
    {
        setPivot(_pivotX, value);
        return value;
    }

    @:final public function setPivot(xv:Float, yv:Float, asAnchor:Bool = false):Void
    {
        if (_pivotX != xv || _pivotY != yv || _pivotAsAnchor != asAnchor)
        {
            _pivotX = xv;
            _pivotY = yv;
            _pivotAsAnchor = asAnchor;

            updatePivotOffset();
            handlePositionChanged();
        }
    }

    private function internalSetPivot(xv:Float, yv:Float, asAnchor:Bool):Void
    {
        _pivotX = xv;
        _pivotY = yv;
        _pivotAsAnchor = asAnchor;
        if (_pivotAsAnchor)
            handlePositionChanged();
    }

    private function updatePivotOffset():Void
    {
        if (_pivotX != 0 || _pivotY != 0)
        {
            var rot:Float = this.normalizeRotation;
            if (rot != 0 || _scaleX != 1 || _scaleY != 1)
            {
                var rotInRad:Float = rot * ToolSet.DEG_TO_RAD;
                var cos:Float = Math.cos(rotInRad);
                var sin:Float = Math.sin(rotInRad);
                var a:Float = _scaleX * cos;
                var b:Float = _scaleX * sin;
                var c:Float = _scaleY * -sin;
                var d:Float = _scaleY * cos;
                var px:Float = _pivotX * _width;
                var py:Float = _pivotY * _height;
                _pivotOffsetX = px - (a * px + c * py);
                _pivotOffsetY = py - (d * py + b * px);
            }
            else
            {
                _pivotOffsetX = 0;
                _pivotOffsetY = 0;
            }
        }
        else
        {
            _pivotOffsetX = 0;
            _pivotOffsetY = 0;
        }
    }

    private function applyPivot():Void
    {
        if (_pivotX != 0 || _pivotY != 0)
        {
            updatePivotOffset();
            handlePositionChanged();
        }
    }

    @:final private function get_touchable():Bool
    {
        return _touchable;
    }

    private function set_touchable(value:Bool):Bool
    {
        if (_touchable != value)
        {
            _touchable = value;
            updateGear(3);

            //Touch is not supported by GImage/GMovieClip/GTextField
            if (Std.is(this, GImage) || Std.is(this, GMovieClip) || Std.is(this, GTextField) && !Std.is(this, GTextInput) && !Std.is(this, GRichTextField))
                return false;

            if (Std.is(_displayObject, InteractiveObject))
            {
                if (Std.is(this, GComponent))
                {
                    cast(this, GComponent).handleTouchable(_touchable);
                }
                else
                {
                    cast(_displayObject, InteractiveObject).mouseEnabled = _touchable;
                    if (Std.is(_displayObject, DisplayObjectContainer))
                        cast(_displayObject, DisplayObjectContainer).mouseChildren = _touchable;
                }
            }
        }
        return value;
    }

    @:final private function get_grayed():Bool
    {
        return _grayed;
    }

    private function set_grayed(value:Bool):Bool
    {
        if (_grayed != value)
        {
            _grayed = value;
            handleGrayedChanged();
            updateGear(3);
        }
        return value;
    }

    @:final private function get_enabled():Bool
    {
        return !_grayed && _touchable;
    }

    private function set_enabled(value:Bool):Bool
    {
        this.grayed = !value;
        this.touchable = value;
        return value;
    }

    @:final private function get_rotation():Float
    {
        return _rotation;
    }

    private function set_rotation(value:Float):Float
    {
        if (_rotation != value)
        {
            _rotation = value;
            if (_displayObject != null)
                _displayObject.rotation = this.normalizeRotation;

            applyPivot();
            updateGear(3);
        }
        return value;
    }

    private function get_normalizeRotation():Float
    {
        var rot:Float = _rotation % 360;
        if (rot > 180)
            rot = rot - 360
        else if (rot < -180)
            rot = 360 + rot;
        return rot;
    }

    @:final private function get_alpha():Float
    {
        return _alpha;
    }

    private function set_alpha(value:Float):Float
    {
        if (_alpha != value)
        {
            _alpha = value;
            handleAlphaChanged();
            updateGear(3);
        }
        return value;
    }

    @:final private function get_visible():Bool
    {
        return _visible;
    }

    private function set_visible(value:Bool):Bool
    {
        if(_visible!=value)
        {
            _visible = value;
            handleVisibleChanged();
            if(_parent != null)
                _parent.setBoundsChangedFlag();
        }
        return value;
    }

    private function get_internalVisible():Bool
    {
        return _internalVisible && (_group == null || _group.internalVisible);
    }

    private function get_internalVisible2():Bool
    {
        return _visible && (_group == null || _group.internalVisible2);
    }

    @:final private function get_sortingOrder():Int
    {
        return _sortingOrder;
    }

    private function set_sortingOrder(value:Int):Int
    {
        if (value < 0)
            value = 0;
        if (_sortingOrder != value)
        {
            var old:Int = _sortingOrder;
            _sortingOrder = value;
            if (_parent != null)
                _parent.childSortingOrderChanged(this, old, _sortingOrder);
        }
        return value;
    }

    @:final private function get_focusable():Bool
    {
        return _focusable;
    }

    private function set_focusable(value:Bool):Bool
    {
        _focusable = value;
        return value;
    }

    private function get_focused():Bool
    {
        return this.root.focus == this;
    }

    public function requestFocus():Void
    {
        var p:GObject = this;
        while (p != null && !p._focusable)
            p = p.parent;
        if (p != null)
            this.root.focus = p;
    }

    @:final private function get_tooltips():String
    {
        return _tooltips;
    }

    private function set_tooltips(value:String):String
    {
        if (_tooltips != null && CompatUtil.supportsCursor)
        {
            this.removeEventListener(MouseEvent.ROLL_OVER, __rollOver);
            this.removeEventListener(MouseEvent.ROLL_OUT, __rollOut);
        }

        _tooltips = value;
        if (_tooltips != null && CompatUtil.supportsCursor)
        {
            this.addEventListener(MouseEvent.ROLL_OVER, __rollOver);
            this.addEventListener(MouseEvent.ROLL_OUT, __rollOut);
        }
        return value;
    }

    private function __rollOver(evt:Event):Void
    {
        GTimers.inst.callDelay(100, __doShowTooltips);
    }

    private function __doShowTooltips():Void
    {
        var r:GRoot = this.root;
        if (r != null)
            this.root.showTooltips(_tooltips);
    }

    private function __rollOut(evt:Event):Void
    {
        GTimers.inst.remove(__doShowTooltips);
        this.root.hideTooltips();
    }

    private function get_blendMode():String
    {
        return _displayObject.blendMode;
    }

    private function set_blendMode(value:String):String
    {
        _displayObject.blendMode = value;
        return value;
    }

    private function get_filters():Array<Dynamic>
    {
        return _displayObject.filters;
    }

    private function set_filters(value:Array<Dynamic>):Array<Dynamic>
    {
        _displayObject.filters = cast value;
        return value;
    }

    @:final private function get_inContainer():Bool
    {
        return _displayObject != null && _displayObject.parent != null;
    }

    @:final private function get_onStage():Bool
    {
        return _displayObject != null && _displayObject.stage != null;
    }

    @:final private function get_resourceURL():String
    {
        if (packageItem != null)
            return "ui://" + packageItem.owner.id + packageItem.id
        else
            return null;
    }

    @:final private function set_group(value:GGroup):GGroup
    {
        if (_group != value)
        {
            if (_group != null)
                _group.setBoundsChangedFlag(true);
            _group = value;
            if (_group != null)
                _group.setBoundsChangedFlag(true);
            handleVisibleChanged();
            if (_parent != null)
                _parent.childStateChanged(this);
        }
        return value;
    }

    @:final private function get_group():GGroup
    {
        return _group;
    }

    @:final public function getGear(index:Int):GearBase
    {
        var gear:GearBase = this._gears[index];
        if (gear == null)
        {
            switch (index)
            {
                case 0:
                    gear = new GearDisplay(this);
                case 1:
                    gear = new GearXY(this);
                case 2:
                    gear = new GearSize(this);
                case 3:
                    gear = new GearLook(this);
                case 4:
                    gear = new GearColor(this);
                case 5:
                    gear = new GearAnimation(this);
                case 6:
                    gear = new GearText(this);
                case 7:
                    gear = new GearIcon(this);
                default:
                    throw new Error("FairyGUI: invalid gear index!");
            }
            this._gears[index] = gear;
        }
        return gear;
    }

    private function updateGear(index:Int):Void
    {
        if (_underConstruct || _gearLocked)
            return;

        var gear:GearBase = this._gears[index];
        if (gear != null && gear.controller != null)
            gear.updateState();
    }

    @:allow(fairygui)
    private function checkGearController(index:Int, c:Controller):Bool
    {
        return this._gears[index] != null && this._gears[index].controller == c;
    }

    @:allow(fairygui)
    private function updateGearFromRelations(index:Int, dx:Float, dy:Float):Void
    {
        if (this._gears[index] != null)
            this._gears[index].updateFromRelations(dx, dy);
    }

    @:allow(fairygui)
    private function addDisplayLock():UInt
    {
        var gearDisplay:GearDisplay = cast(this._gears[0], GearDisplay);
        if (gearDisplay != null && gearDisplay.controller != null)
        {
            var ret:UInt = gearDisplay.addLock();
            checkGearDisplay();

            return ret;
        }
        else
            return 0;
    }

    @:allow(fairygui)
    private function releaseDisplayLock(token:UInt):Void
    {
        if (this._gears[0] == null)
        {
            return;
        }
        var gearDisplay:GearDisplay = cast(this._gears[0], GearDisplay);
        if (gearDisplay != null && gearDisplay.controller != null)
        {
            gearDisplay.releaseLock(token);
            checkGearDisplay();
        }
    }

    private function checkGearDisplay():Void
    {
        if (_handlingController)
            return;

        var connected:Bool = this._gears[0] == null || cast(this._gears[0], GearDisplay).connected;
        if (connected != _internalVisible)
        {
            _internalVisible = connected;
            if (_parent != null)
                _parent.childStateChanged(this);
        }
    }

    @:final private function get_gearXY():GearXY
    {
        return cast(getGear(1), GearXY);
    }

    @:final private function get_gearSize():GearSize
    {
        return cast(getGear(2), GearSize);
    }

    @:final private function get_gearLook():GearLook
    {
        return cast(getGear(3), GearLook);
    }

    @:final private function get_relations():Relations
    {
        return _relations;
    }

    @:final public function addRelation(target:GObject, relationType:Int, usePercent:Bool = false):Void
    {
        _relations.add(target, relationType, usePercent);
    }

    @:final public function removeRelation(target:GObject, relationType:Int):Void
    {
        _relations.remove(target, relationType);
    }

    @:final private function get_displayObject():DisplayObject
    {
        return _displayObject;
    }

    @:final private function setDisplayObject(value:DisplayObject):Void
    {
        _displayObject = value;
    }

    @:final private function get_parent():GComponent
    {
        return _parent;
    }

    @:final private function set_parent(val:GComponent):GComponent
    {
        _parent = val;
        return val;
    }

    @:final public function removeFromParent():Void
    {
        if (_parent != null)
            _parent.removeChild(this);
    }

    private function get_root():GRoot
    {
        if (Std.is(this, GRoot))
            return cast(this, GRoot);

        var p:GObject = _parent;
        while (p != null)
        {
            if (Std.is(p, GRoot))
                return cast(p, GRoot);
            p = p.parent;
        }
        return GRoot.inst;
    }

    @:final private function get_asCom():GComponent
    {
        return try cast(this, GComponent)
        catch (e:Dynamic) null;
    }

    @:final private function get_asButton():GButton
    {
        return try cast(this, GButton)
        catch (e:Dynamic) null;
    }

    @:final private function get_asLabel():GLabel
    {
        return try cast(this, GLabel)
        catch (e:Dynamic) null;
    }

    @:final private function get_asProgress():GProgressBar
    {
        return try cast(this, GProgressBar)
        catch (e:Dynamic) null;
    }

    @:final private function get_asTextField():GTextField
    {
        return try cast(this, GTextField)
        catch (e:Dynamic) null;
    }

    @:final private function get_asRichTextField():GRichTextField
    {
        return try cast(this, GRichTextField)
        catch (e:Dynamic) null;
    }

    @:final private function get_asTextInput():GTextInput
    {
        return try cast(this, GTextInput)
        catch (e:Dynamic) null;
    }

    @:final private function get_asLoader():GLoader
    {
        return try cast(this, GLoader)
        catch (e:Dynamic) null;
    }

    @:final private function get_asList():GList
    {
        return try cast(this, GList)
        catch (e:Dynamic) null;
    }

    @:final private function get_asGraph():GGraph
    {
        return try cast(this, GGraph)
        catch (e:Dynamic) null;
    }

    @:final private function get_asGroup():GGroup
    {
        return try cast(this, GGroup)
        catch (e:Dynamic) null;
    }

    @:final private function get_asSlider():GSlider
    {
        return try cast(this, GSlider)
        catch (e:Dynamic) null;
    }

    @:final private function get_asComboBox():GComboBox
    {
        return try cast(this, GComboBox)
        catch (e:Dynamic) null;
    }

    @:final private function get_asImage():GImage
    {
        return try cast(this, GImage)
        catch (e:Dynamic) null;
    }

    @:final private function get_asMovieClip():GMovieClip
    {
        return try cast(this, GMovieClip)
        catch (e:Dynamic) null;
    }

    private function get_text():String
    {
        return null;
    }

    private function set_text(value:String):String
    {
        return value;
    }

    private function get_icon():String
    {
        return null;
    }

    private function set_icon(value:String):String
    {
        return value;
    }

    public function dispose():Void
    {
        removeFromParent();
        _relations.dispose();
    }

    public function addClickListener(listener:Dynamic):Void
    {
        addEventListener(GTouchEvent.CLICK, listener);
    }

    public function removeClickListener(listener:Dynamic):Void
    {
        removeEventListener(GTouchEvent.CLICK, listener);
    }

    public function hasClickListener():Bool
    {
        return hasEventListener(GTouchEvent.CLICK);
    }

    public function addXYChangeCallback(listener:Dynamic):Void
    {
        _dispatcher.addListener(XY_CHANGED, listener);
    }

    public function addSizeChangeCallback(listener:Dynamic):Void
    {
        _dispatcher.addListener(SIZE_CHANGED, listener);
    }

    @:allow(fairygui)
    private function addSizeDelayChangeCallback(listener:Dynamic):Void
    {
        _dispatcher.addListener(SIZE_DELAY_CHANGE, listener);
    }

    public function removeXYChangeCallback(listener:Dynamic):Void
    {
        _dispatcher.removeListener(XY_CHANGED, listener);
    }

    public function removeSizeChangeCallback(listener:Dynamic):Void
    {
        _dispatcher.removeListener(SIZE_CHANGED, listener);
    }

    @:allow(fairygui)
    private function removeSizeDelayChangeCallback(listener:Dynamic):Void
    {
        _dispatcher.removeListener(SIZE_DELAY_CHANGE, listener);
    }

    override public function addEventListener(type:String, listener:Dynamic, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void
    {
        super.addEventListener(type, listener, false, priority, useWeakReference);

        if (_displayObject != null)
        {
            if (MTOUCH_EVENTS.indexOf(type) != -1)
                initMTouch();
            else
            {
                if (type == MouseEvent.RIGHT_CLICK && Std.is(this, GComponent))
                    cast(this, GComponent).opaque = true;

                _displayObject.addEventListener(type, _reDispatch, useCapture, priority, useWeakReference);
            }
        }
    }

    override public function removeEventListener(type:String, listener:Dynamic, useCapture:Bool = false):Void
    {
        super.removeEventListener(type, listener, false);

        if (_displayObject != null && !this.hasEventListener(type))
        {
            _displayObject.removeEventListener(type, _reDispatch, true);
            _displayObject.removeEventListener(type, _reDispatch, false);
        }
    }

    private function _reDispatch(evt:Event):Void
    {
        var nevt:Event = evt.clone();
        this.dispatchEvent(nevt);
        if (evt.bubbles && Std.is(nevt, IBubbleEvent) && cast(nevt, IBubbleEvent).propagationStopped)
            evt.stopPropagation();
    }

    @:final private function get_draggable():Bool
    {
        return _draggable;
    }

    @:final private function set_draggable(value:Bool):Bool
    {
        if (_draggable != value)
        {
            _draggable = value;
            initDrag();
        }
        return value;
    }

    @:final private function get_dragBounds():Rectangle
    {
        return _dragBounds;
    }

    @:final private function set_dragBounds(value:Rectangle):Rectangle
    {
        _dragBounds = value;
        return value;
    }

    public function startDrag(touchPointID:Int = -1):Void
    {
        if (_displayObject.stage == null)
            return;

        dragBegin(null);
        triggerDown(touchPointID);
    }

    public function stopDrag():Void
    {
        dragEnd();
    }

    private function get_dragging():Bool
    {
        return draggingObject == this;
    }

    public function localToGlobal(ax:Float = 0, ay:Float = 0):Point
    {
        if (_pivotAsAnchor)
        {
            ax += _pivotX * _width;
            ay += _pivotY * _height;
        }
        sHelperPoint.x = ax;
        sHelperPoint.y = ay;
        return _displayObject.localToGlobal(sHelperPoint);
    }

    public function globalToLocal(ax:Float = 0, ay:Float = 0):Point
    {
        sHelperPoint.x = ax;
        sHelperPoint.y = ay;
        var pt:Point = _displayObject.globalToLocal(sHelperPoint);
        if (_pivotAsAnchor)
        {
            pt.x -= _pivotX * _width;
            pt.y -= _pivotY * _height;
        }
        return pt;
    }

    public function localToRoot(ax:Float = 0, ay:Float = 0):Point
    {
        if (_pivotAsAnchor)
        {
            ax += _pivotX * _width;
            ay += _pivotY * _height;
        }

        sHelperPoint.x = ax;
        sHelperPoint.y = ay;
        var pt:Point = _displayObject.localToGlobal(sHelperPoint);
        pt.x /= GRoot.contentScaleFactor;
        pt.y /= GRoot.contentScaleFactor;
        return pt;
    }

    public function rootToLocal(ax:Float = 0, ay:Float = 0):Point
    {
        sHelperPoint.x = ax;
        sHelperPoint.y = ay;
        sHelperPoint.x *= GRoot.contentScaleFactor;
        sHelperPoint.y *= GRoot.contentScaleFactor;
        var pt:Point = _displayObject.globalToLocal(sHelperPoint);
        if (_pivotAsAnchor)
        {
            pt.x -= _pivotX * _width;
            pt.y -= _pivotY * _height;
        }
        return pt;
    }

    public function localToGlobalRect(ax:Float = 0, ay:Float = 0, aWidth:Float = 0, aHeight:Float = 0,
                                      resultRect:Rectangle = null):Rectangle
    {
        if (resultRect == null)
            resultRect = new Rectangle();
        var pt:Point = this.localToGlobal(ax, ay);
        resultRect.x = pt.x;
        resultRect.y = pt.y;
        pt = this.localToGlobal(ax + aWidth, ay + aHeight);
        resultRect.right = pt.x;
        resultRect.bottom = pt.y;
        return resultRect;
    }

    public function globalToLocalRect(ax:Float = 0, ay:Float = 0, aWidth:Float = 0, aHeight:Float = 0,
                                      resultRect:Rectangle = null):Rectangle
    {
        if (resultRect == null)
            resultRect = new Rectangle();
        var pt:Point = this.globalToLocal(ax, ay);
        resultRect.x = pt.x;
        resultRect.y = pt.y;
        pt = this.globalToLocal(ax + aWidth, ay + aHeight);
        resultRect.right = pt.x;
        resultRect.bottom = pt.y;
        return resultRect;
    }

    private function createDisplayObject():Void
    {
    }

    private function switchDisplayObject(newObj:DisplayObject):Void
    {
        if (newObj == _displayObject)
            return;

        var old:DisplayObject = _displayObject;
        if (_displayObject.parent != null)
        {
            var i:Int = _displayObject.parent.getChildIndex(_displayObject);
            _displayObject.parent.addChildAt(newObj, i);
            _displayObject.parent.removeChild(_displayObject);
        }
        _displayObject = newObj;
        _displayObject.x = old.x;
        _displayObject.y = old.y;
        _displayObject.rotation = old.rotation;
        _displayObject.alpha = old.alpha;
        _displayObject.visible = old.visible;
        _displayObject.scaleX = old.scaleX;
        _displayObject.scaleY = old.scaleY;
        _displayObject.filters = old.filters;
        old.filters = null;
        if (Std.is(_displayObject, InteractiveObject) && Std.is(old, InteractiveObject))
        {
            cast(_displayObject, InteractiveObject).mouseEnabled = cast(old, InteractiveObject).mouseEnabled;
            if (Std.is(_displayObject, DisplayObjectContainer))
                cast(_displayObject, DisplayObjectContainer).mouseChildren = cast(old, DisplayObjectContainer).mouseChildren;
        }
    }

    private function handlePositionChanged():Void
    {
        if (_displayObject != null)
        {
            var xv:Float = _x;
            var yv:Float = _y + _yOffset;
            if (_pivotAsAnchor)
            {
                xv -= _pivotX * _width;
                yv -= _pivotY * _height;
            }
            if (_pixelSnapping)
            {
                xv = Math.round(xv);
                yv = Math.round(yv);
            }
            _displayObject.x = xv + _pivotOffsetX;
            _displayObject.y = yv + _pivotOffsetY;
        }
    }

    private function handleSizeChanged():Void
    {
        if (_displayObject != null && _sizeImplType == 1 && sourceWidth != 0 && sourceHeight != 0)
        {

            _displayObject.scaleX = _width / sourceWidth * _scaleX;
            _displayObject.scaleY = _height / sourceHeight * _scaleY;
        }
    }

    private function handleScaleChanged():Void
    {
        if (_displayObject != null)
        {
            if (_sizeImplType == 0 || sourceWidth == 0 || sourceHeight == 0)
            {
                _displayObject.scaleX = _scaleX;
                _displayObject.scaleY = _scaleY;
            }
            else
            {
                _displayObject.scaleX = _width / sourceWidth * _scaleX;
                _displayObject.scaleY = _height / sourceHeight * _scaleY;
            }
        }
    }

    public function handleControllerChanged(c:Controller):Void
    {
        _handlingController = true;
        for (i in 0...8)
        {
            var gear:GearBase = this._gears[i];
            if (gear != null && gear.controller == c)
                gear.apply();
        }
        _handlingController = false;

        checkGearDisplay();
    }

    private function handleGrayedChanged():Void
    {
        if (_displayObject != null)
        {
            if (_grayed)
                _displayObject.filters = ToolSet.GRAY_FILTERS;
            else
                _displayObject.filters = null;
        }
    }

    @:allow(fairygui)
    private function handleAlphaChanged():Void
    {
        if (_displayObject != null)
            _displayObject.alpha = _alpha;
    }

    @:allow(fairygui)
    private function handleVisibleChanged():Void
    {
        if (_displayObject != null)
            _displayObject.visible = internalVisible2;
    }

    public function constructFromResource():Void
    {
    }

    public function setup_beforeAdd(xml:FastXML):Void
    {
        var str:String;
        var arr:Array<String>;

        _id = xml.att.id;
        _name = xml.att.name;

        str = xml.att.xy;
        arr = str.split(",");
        this.setXY(Std.parseInt(arr[0]), Std.parseInt(arr[1]));

        str = xml.att.size;
        if (str != null)
        {
            arr = str.split(",");
            initWidth = Std.parseInt(arr[0]);
            initHeight = Std.parseInt(arr[1]);
            setSize(initWidth, initHeight, true);
        }

        str = xml.att.restrictSize;
        if (str != null)
        {
            arr = str.split(",");
            minWidth = Std.parseInt(arr[0]);
            maxWidth = Std.parseInt(arr[1]);
            minHeight = Std.parseInt(arr[2]);
            maxHeight = Std.parseInt(arr[3]);
        }

        str = xml.att.scale;
        if (str != null)
        {
            arr = str.split(",");
            setScale(Std.parseFloat(arr[0]), Std.parseFloat(arr[1]));
        }

        str = xml.att.rotation;
        if (str != null)
            this.rotation = Std.parseInt(str);

        str = xml.att.alpha;
        if (str != null)
            this.alpha = Std.parseFloat(str);

        str = xml.att.pivot;
        if (str != null)
        {
            arr = str.split(",");
            str = xml.att.anchor;
            this.setPivot(Std.parseFloat(arr[0]), Std.parseFloat(arr[1]), str == "true");
        }

        if (xml.att.touchable == "false")
            this.touchable = false;
        if (xml.att.visible == "false")
            this.visible = false;
        if (xml.att.grayed == "true")
            this.grayed = true;
        this.tooltips = xml.att.tooltips;

        str = xml.att.blend;
        if (str != null)
            this.blendMode = str;

        str = xml.att.filter;
        if (str != null)
        {
            switch (str)
            {
                case "color":
                    str = xml.att.filterData;
                    arr = str.split(",");
                    var cm:ColorMatrix = new ColorMatrix();
                    cm.adjustBrightness(Std.parseFloat(arr[0]));
                    cm.adjustContrast(Std.parseFloat(arr[1]));
                    cm.adjustSaturation(Std.parseFloat(arr[2]));
                    cm.adjustHue(Std.parseFloat(arr[3]));
                    var cf:ColorMatrixFilter = new ColorMatrixFilter(cm);
                    this.filters = [cf];
            }
        }

        str = xml.att.customData;
        if (str != null)
        this.data = str;
    }

    private static var GearXMLKeys:Dynamic = {
        gearDisplay : 0,
        gearXY : 1,
        gearSize : 2,
        gearLook : 3,
        gearColor : 4,
        gearAni : 5,
        gearText : 6,
        gearIcon : 7
    };

    public function setup_afterAdd(xml:FastXML):Void
    {
        var s:String = xml.att.group;
        if (s != null)
            _group = try cast(_parent.getChildById(s), GGroup)
            catch (e:Dynamic) null;

        var col:FastXMLList = xml.descendants();
        for (cxml in col.iterator())
        {
            var index:Null<Int> = Reflect.field(GearXMLKeys, cxml.x.nodeName);
            if (index != null)
                getGear(index).setup(cxml);
        }
    }

    //touch support
    //-------------------------------------------------------------------
    private var _touchPointId:Int = 0;
    private var _lastClick:Int = 0;
    private var _buttonStatus:Int = 0;
    private var _touchDownPoint:Point;
    private static var MTOUCH_EVENTS:Array<String> =
    [GTouchEvent.BEGIN, GTouchEvent.DRAG, GTouchEvent.END, GTouchEvent.CLICK];

    private function get_isDown():Bool
    {
        return _buttonStatus == 1;
    }

    public function triggerDown(touchPointID:Int = -1):Void
    {
        var st:Stage = _displayObject.stage;
        if (st != null)
        {
            _buttonStatus = 1;
            if (!GRoot.touchPointInput)
            {
                _displayObject.stage.addEventListener(MouseEvent.MOUSE_UP, __stageMouseup, false, 20);
                if (hasEventListener(GTouchEvent.DRAG))
                    _displayObject.stage.addEventListener(MouseEvent.MOUSE_MOVE, __mousemove);
            }
            else
            {
                _touchPointId = touchPointID;
                _displayObject.stage.addEventListener(TouchEvent.TOUCH_END, __stageMouseup, false, 20);
                if (hasEventListener(GTouchEvent.DRAG))
                    _displayObject.stage.addEventListener(TouchEvent.TOUCH_MOVE, __mousemove);
            }
        }
    }

    private function initMTouch():Void
    {
        if (Std.is(this, GComponent))
        {
            /*GComponent is by default not opaque for optimization.
            if a click listener registered, we set opaque to true
            */
            cast(this, GComponent).opaque = true;
        }
        if (!GRoot.touchPointInput)
        {
            _displayObject.addEventListener(MouseEvent.MOUSE_DOWN, p__mousedown);
            _displayObject.addEventListener(MouseEvent.MOUSE_UP, p__mouseup);
        }
        else
        {
            _displayObject.addEventListener(TouchEvent.TOUCH_BEGIN, p__mousedown);
            _displayObject.addEventListener(TouchEvent.TOUCH_END, p__mouseup);
        }
    }

    @:final private function p__mousedown(evt:Event):Void
    {
        var devt:GTouchEvent = new GTouchEvent(GTouchEvent.BEGIN);
        devt.copyFrom(evt);
        this.dispatchEvent(devt);
        if (devt.isPropagationStop)
            evt.stopPropagation();

        if (_touchDownPoint == null)
            _touchDownPoint = new Point();

        if (!GRoot.touchPointInput)
        {
            _touchDownPoint.x = cast(evt, MouseEvent).stageX;
            _touchDownPoint.y = cast(evt, MouseEvent).stageY;
            triggerDown();
        }
        else
        {
            _touchDownPoint.x = cast(evt, TouchEvent).stageX;
            _touchDownPoint.y = cast(evt, TouchEvent).stageY;
            triggerDown(cast(evt, TouchEvent).touchPointID);
        }
    }

    private function __mousemove(evt:Event):Void
    {
        if (_buttonStatus != 1 || GRoot.touchPointInput && _touchPointId != cast(evt, TouchEvent).touchPointID)
            return;

        var sensitivity:Int;
        if (GRoot.touchPointInput)
        {
            sensitivity = UIConfig.touchDragSensitivity;
            if (_touchDownPoint != null && Math.abs(_touchDownPoint.x - cast(evt, TouchEvent).stageX) < sensitivity && Math.abs(_touchDownPoint.y - cast(evt, TouchEvent).stageY) < sensitivity)
                return;
        }
        else
        {
            sensitivity = UIConfig.clickDragSensitivity;
            if (_touchDownPoint != null && Math.abs(_touchDownPoint.x - cast(evt, MouseEvent).stageX) < sensitivity && Math.abs(_touchDownPoint.y - cast(evt, MouseEvent).stageY) < sensitivity)
                return;
        }

        var devt:GTouchEvent = new GTouchEvent(GTouchEvent.DRAG);
        devt.copyFrom(evt);
        this.dispatchEvent(devt);
        if (devt.isPropagationStop)
            evt.stopPropagation();
    }

    @:final private function p__mouseup(evt:Event):Void
    {
        if (_buttonStatus != 1 || GRoot.touchPointInput && _touchPointId != cast((evt), TouchEvent).touchPointID)
            return;

        _buttonStatus = 2;
    }

    private function __stageMouseup(evt:Event):Void
    {
        if (!GRoot.touchPointInput)
        {
            cast(evt.currentTarget, Stage).removeEventListener(MouseEvent.MOUSE_UP, __stageMouseup);
            cast(evt.currentTarget, Stage).removeEventListener(MouseEvent.MOUSE_MOVE, __mousemove);
        }
        else
        {
            if (_touchPointId != cast(evt, TouchEvent).touchPointID)
                return;

            cast(evt.currentTarget, Stage).removeEventListener(TouchEvent.TOUCH_END, __stageMouseup);
            cast(evt.currentTarget, Stage).removeEventListener(TouchEvent.TOUCH_MOVE, __mousemove);
        }

        var devt:GTouchEvent;
        if (_buttonStatus == 2)
        {
            var cc:Int = 1;
            var now:Int = Lib.getTimer();
            if (now - _lastClick < 500)
            {
                cc = 2;
                _lastClick = 0;
            }
            else
                _lastClick = now;

            devt = new GTouchEvent(GTouchEvent.CLICK);
            devt.copyFrom(evt, cc);

            this.dispatchEvent(devt);
            if (devt.isPropagationStop)
            {
                var p:GObject = this.parent;
                while (p != null)
                {
                    p._buttonStatus = 0;
                    p = p.parent;
                }
            }
        }

        _buttonStatus = 0;

        devt = new GTouchEvent(GTouchEvent.END);
        devt.copyFrom(evt);
        this.dispatchEvent(devt);
    }

    public function cancelClick():Void
    {
        _buttonStatus = 0;
        var cnt:Int = cast(this, GComponent).numChildren;
        for (i in 0...cnt)
        {
            var child:GObject = cast(this, GComponent).getChildAt(i);
            child._buttonStatus = 0;
            if (Std.is(child, GComponent))
                child.cancelClick();
        }
    }

    //-------------------------------------------------------------------

    //drag support
    //-------------------------------------------------------------------
    private static var sGlobalDragStart:Point = new Point();
    private static var sGlobalRect:Rectangle = new Rectangle();
    private static var sHelperPoint:Point = new Point();
    private static var sDragHelperRect:Rectangle = new Rectangle();
    private static var sUpdateInDragging:Bool = false;

    private function initDrag():Void
    {
        if (_draggable)
            addEventListener(GTouchEvent.BEGIN, __begin);
        else
            removeEventListener(GTouchEvent.BEGIN, __begin);
    }

    private function dragBegin(evt:GTouchEvent):Void
    {
        if (draggingObject != null)
        {
            draggingObject.stopDrag();
            draggingObject = null;
        }

        if (evt != null)
        {
            sGlobalDragStart.x = evt.stageX;
            sGlobalDragStart.y = evt.stageY;
        }
        else
        {
            sGlobalDragStart.x = _displayObject.stage.mouseX;
            sGlobalDragStart.y = _displayObject.stage.mouseY;
        }
        this.localToGlobalRect(0, 0, this.width, this.height, sGlobalRect);
        draggingObject = this;

        addEventListener(GTouchEvent.DRAG, __dragging);
        addEventListener(GTouchEvent.END, __dragEnd);
    }

    private function dragEnd():Void
    {
        if (draggingObject == this)
        {
            removeEventListener(GTouchEvent.DRAG, p__dragStart);
            removeEventListener(GTouchEvent.END, __dragEnd);
            removeEventListener(GTouchEvent.DRAG, __dragging);
            draggingObject = null;
        }
    }

    private function __begin(evt:GTouchEvent):Void
    {
        if (Std.is(evt.realTarget, TextField) && cast(evt.realTarget, TextField).type == TextFieldType.INPUT)
            return;

        addEventListener(GTouchEvent.DRAG, p__dragStart);
    }

    private function p__dragStart(evt:GTouchEvent):Void
    {
        removeEventListener(GTouchEvent.DRAG, p__dragStart);

        if (Std.is(evt.realTarget, TextField) && cast(evt.realTarget, TextField).type == TextFieldType.INPUT)
            return;

        var dragEvent:DragEvent = new DragEvent(DragEvent.DRAG_START);
        dragEvent.stageX = evt.stageX;
        dragEvent.stageY = evt.stageY;
        dragEvent.touchPointID = evt.touchPointID;
        dispatchEvent(dragEvent);

        if (!dragEvent.isDefaultPrevented())
            dragBegin(evt);
    }

    private function __dragging(evt:GTouchEvent):Void
    {
        if (this.parent == null)
            return;

        var xx:Float = evt.stageX - sGlobalDragStart.x + sGlobalRect.x;
        var yy:Float = evt.stageY - sGlobalDragStart.y + sGlobalRect.y;

        if (_dragBounds != null)
        {
            var rect:Rectangle = GRoot.inst.localToGlobalRect(_dragBounds.x, _dragBounds.y,
            _dragBounds.width, _dragBounds.height, sDragHelperRect);
            if (xx < rect.x)
                xx = rect.x;
            else if (xx + sGlobalRect.width > rect.right)
            {
                xx = rect.right - sGlobalRect.width;
                if (xx < rect.x)
                    xx = rect.x;
            }

            if (yy < rect.y)
                yy = rect.y;
            else if (yy + sGlobalRect.height > rect.bottom)
            {
                yy = rect.bottom - sGlobalRect.height;
                if (yy < rect.y)
                    yy = rect.y;
            }
        }

        sUpdateInDragging = true;
        var pt:Point = this.parent.globalToLocal(xx, yy);
        this.setXY(Math.round(pt.x), Math.round(pt.y));
        sUpdateInDragging = false;


        var dragEvent:DragEvent = new DragEvent(DragEvent.DRAG_MOVING);
        dragEvent.stageX = evt.stageX;
        dragEvent.stageY = evt.stageY;
        dragEvent.touchPointID = evt.touchPointID;
        dispatchEvent(dragEvent);
    }

    private function __dragEnd(evt:GTouchEvent):Void
    {
        if (draggingObject == this)
        {
            stopDrag();

            var dragEvent:DragEvent = new DragEvent(DragEvent.DRAG_END);
            dragEvent.stageX = evt.stageX;
            dragEvent.stageY = evt.stageY;
            dragEvent.touchPointID = evt.touchPointID;
            dispatchEvent(dragEvent);
        }
    }
}

