package fairygui;

import tweenxcore.Tools.Easing;
import fairygui.GObject;
import fairygui.utils.EaseLookup;


class GearBase
{
    public var controller(get, set) : Controller;
    public var tween(get, set) : Bool;
    public var tweenTime(get, set) : Float;
    public var delay(get, set) : Float;
    public var easeType(get, set) : Float->Float;

    public static var disableAllTweenEffect : Bool = false;
    
    private var _tween : Bool = false;
    private var _easeType : Float->Float;
    private var _tweenTime : Float = 0;
    private var _delay : Float = 0;
    
    private var _owner : GObject;
    private var _controller : Controller;
    
    public function new(owner : GObject)
    {
        _owner = owner;
        _easeType = Easing.quadOut;
        _tweenTime = 0.3;
        _delay = 0;
    }
    
    @:final private function get_controller() : Controller
    {
        return _controller;
    }
    
    private function set_controller(val : Controller) : Controller
    {
        if (val != _controller) 
        {
            _controller = val;
            if (_controller != null) 
                init();
        }
        return val;
    }
    
    @:final private function get_tween() : Bool
    {
        return _tween;
    }
    
    private function set_tween(val : Bool) : Bool
    {
        _tween = val;
        return val;
    }
    
    @:final private function get_tweenTime() : Float
    {
        return _tweenTime;
    }
    
    private function set_tweenTime(value : Float) : Float
    {
        _tweenTime = value;
        return value;
    }
    
    @:final private function get_delay() : Float
    {
        return _delay;
    }
    
    private function set_delay(value : Float) : Float
    {
        _delay = value;
        return value;
    }
    
    @:final private function get_easeType() : Float->Float
    {
        return _easeType;
    }
    
    private function set_easeType(value : Float->Float) : Float -> Float
    {
        _easeType = value;
        return value;
    }
    
    public function setup(xml : FastXML) : Void
    {
        _controller = _owner.parent.getController(xml.att.controller);
        if (_controller == null) 
            return;
        
        init();
        
        var str : String;
        
        str = xml.att.tween;
        if (str != null) 
            _tween = true;
        
        str = xml.att.ease;
        if (str != null) 
        {
            var pos : Int = str.indexOf(".");
            if (pos != -1) 
                str = str.substr(0, pos) + ".ease" + str.substr(pos + 1);
            if (str == "Linear") 
                _easeType = EaseLookup.find("linear.easenone")
            else 
            _easeType = EaseLookup.find(str);
        }
        
        str = xml.att.duration;
        if (str != null) 
            _tweenTime = Std.parseFloat(str);
        
        str = xml.att.delay;
        if (str != null) 
            _delay = Std.parseFloat(str);
        
        if (Std.is(this, GearDisplay)) 
        {
            str = xml.att.pages;
            if (str != null) 
            {
                var arr : Array<String> = str.split(",");
                cast((this), GearDisplay).pages = arr;
            }
        }
        else 
        {
            var pages : Array<Dynamic> = null;
            var values : Array<Dynamic> = null;
            
            str = xml.att.pages;
            if (str != null) 
                pages = str.split(",");
            
            str = xml.att.values;
            if (str != null) 
                values = str.split("|");
            
            if (pages != null && values != null) 
            {
                for (i in 0...values.length)
                {
                    addStatus(pages[i], values[i]);
                }
            }
            
            str = xml.att.resolve("default");
            if (str != null) 
                addStatus(null, str);
        }
    }
    
    public function updateFromRelations(dx : Float, dy : Float) : Void
    {
    }
    
    private function addStatus(pageId : String, value : String) : Void
    {
    }
    
    private function init() : Void
    {
    }
    
    public function apply() : Void
    {
    }
    
    public function updateState() : Void
    {
    }
}
