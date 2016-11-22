package fairygui.event;


import openfl.display.DisplayObject;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.TouchEvent;

class GTouchEvent extends Event
{
    public var realTarget(get, never) : DisplayObject;
    public var clickCount(get, never) : Int;
    public var stageX(get, never) : Float;
    public var stageY(get, never) : Float;
    public var shiftKey(get, never) : Bool;
    public var ctrlKey(get, never) : Bool;
    public var touchPointID(get, never) : Int;
    public var isPropagationStop(get, never) : Bool;

    private var _stopPropagation : Bool;
    
    private var _realTarget : DisplayObject;
    private var _clickCount : Int;
    private var _stageX : Float;
    private var _stageY : Float;
    private var _shiftKey : Bool;
    private var _ctrlKey : Bool;
    private var _touchPointID : Int;
    
    public static inline var BEGIN : String = "beginGTouch";
    public static inline var DRAG : String = "dragGTouch";
    public static inline var END : String = "endGTouch";
    public static inline var CLICK : String = "clickGTouch";
    
    public function new(type : String)
    {
        super(type, false, false);
    }
    
    public function copyFrom(evt : Event, clickCount : Int = 1) : Void
    {
        if (Std.is(evt, MouseEvent)) 
        {
            _stageX = cast(evt, MouseEvent).stageX;
            _stageY = cast(evt, MouseEvent).stageY;
            _shiftKey = cast(evt, MouseEvent).shiftKey;
            _ctrlKey = cast(evt, MouseEvent).ctrlKey;
        }
        else 
        {
            _stageX = cast(evt, TouchEvent).stageX;
            _stageY = cast(evt, TouchEvent).stageY;
            _shiftKey = cast(evt, TouchEvent).shiftKey;
            _ctrlKey = cast(evt, TouchEvent).ctrlKey;
            _touchPointID = cast((evt), TouchEvent).touchPointID;
        }
        _realTarget = try cast(evt.target, DisplayObject) catch(e:Dynamic) null;
        _clickCount = clickCount;
        _stopPropagation = false;
    }
    
    @:final private function get_realTarget() : DisplayObject
    {
        return _realTarget;
    }
    @:final private function get_clickCount() : Int
    {
        return _clickCount;
    }
    @:final private function get_stageX() : Float
    {
        return _stageX;
    }
    @:final private function get_stageY() : Float
    {
        return _stageY;
    }
    @:final private function get_shiftKey() : Bool
    {
        return _shiftKey;
    }
    @:final private function get_ctrlKey() : Bool
    {
        return _ctrlKey;
    }
    @:final private function get_touchPointID() : Int
    {
        return _touchPointID;
    }
    override public function stopPropagation() : Void
    {
        _stopPropagation = true;
    }
    
    @:final private function get_isPropagationStop() : Bool
    {
        return _stopPropagation;
    }
    
    override public function clone() : Event{
        var ret : GTouchEvent = new GTouchEvent(type);
        ret._realTarget = _realTarget;
        ret._clickCount = _clickCount;
        ret._stageX = _stageX;
        ret._stageY = _stageY;
        ret._shiftKey = _shiftKey;
        ret._ctrlKey = _ctrlKey;
        ret._touchPointID = _touchPointID;
        return ret;
    }
}
