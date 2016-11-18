package fairygui;

import tweenx909.TweenX;
import fairygui.GObject;

import openfl.geom.Point;

class GearLook extends GearBase
{
    public var tweener : TweenX;
    
    private var _storage : Map<String, GearLookValue>;
    private var _default : GearLookValue;
    private var _tweenValue : Point;
    
    public function new(owner : GObject)
    {
        super(owner);
    }
    
    override private function init() : Void
    {
        _default = new GearLookValue(_owner.alpha, _owner.rotation, _owner.grayed);
        _storage = new Map<String, GearLookValue>();
    }
    
    override private function addStatus(pageId : String, value : String) : Void
    {
        if (value == "-") 
            return;
        
        var arr : Array<Dynamic> = value.split(",");
        var gv : GearLookValue;
        if (pageId == null) 
            gv = _default
        else 
        {
            gv = new GearLookValue();
            _storage[pageId] = gv;
        }
        gv.alpha = Std.parseFloat(arr[0]);
        gv.rotation = Std.parseInt(arr[1]);
        gv.grayed = (arr[2] == "1") ? true : false;
    }
    
    override public function apply() : Void
    {
        var gv : GearLookValue = _storage[_controller.selectedPageId];
        if (gv == null) 
            gv = _default;
        
        if (_tween && UIPackage._constructing < 1 && !GearBase.disableAllTweenEffect)
        {
            _owner._gearLocked = true;
            _owner.grayed = gv.grayed;
            _owner._gearLocked = false;
            
            var a : Bool;
            var b : Bool;
            if (tweener != null) 
            {
                a = tweener.vars.onUpdateParams[0];
                b = tweener.vars.onUpdateParams[1];
                if (a && tweener.vars.x != gv.alpha || b && tweener.vars.y != gv.rotation) 
                {
                    _owner._gearLocked = true;
                    if (a) 
                        _owner.alpha = tweener.vars.x;
                    if (b) 
                        _owner.rotation = tweener.vars.y;
                    _owner._gearLocked = false;
                    tweener.stop();
                    tweener = null;
                    _owner.internalVisible--;
                }
                else 
                return;
            }
            
            a = gv.alpha != _owner.alpha;
            b = gv.rotation != _owner.rotation;
            if (a || b) 
            {
                _owner.internalVisible++;
                var vars : Dynamic = 
                {
                    x : gv.alpha,
                    y : gv.rotation
                };
                if (_tweenValue == null)
                    _tweenValue = new Point();
                _tweenValue.x = _owner.alpha;
                _tweenValue.y = _owner.rotation;
                tweener = TweenX.to(_tweenValue, vars, _tweenTime).ease(_easeType).delay(_delay).onUpdate(__tweenUpdate.bind(a,b)).onFinish(__tweenComplete);
            }
        }
        else 
        {
            _owner._gearLocked = true;
            _owner.alpha = gv.alpha;
            _owner.rotation = gv.rotation;
            _owner.grayed = gv.grayed;
            _owner._gearLocked = false;
        }
    }
    
    private function __tweenUpdate(a : Bool, b : Bool) : Void
    {
        _owner._gearLocked = true;
        if (a) 
            _owner.alpha = _tweenValue.x;
        if (b) 
            _owner.rotation = Std.int(_tweenValue.y);
        _owner._gearLocked = false;
    }
    
    private function __tweenComplete() : Void
    {
        _owner.internalVisible--;
        tweener = null;
    }
    
    override public function updateState() : Void
    {
        if (_controller == null || _owner._gearLocked || _owner._underConstruct) 
            return;
        
        var gv : GearLookValue = _storage[_controller.selectedPageId];
        if (gv == null) 
        {
            gv = new GearLookValue();
            _storage[_controller.selectedPageId] = gv;
        }
        
        gv.alpha = _owner.alpha;
        gv.rotation = _owner.rotation;
        gv.grayed = _owner.grayed;
    }
}


class GearLookValue
{
    public var alpha : Float;
    public var rotation : Int;
    public var grayed : Bool;
    
    public function new(alpha : Float = 0, rotation : Int = 0, grayed : Bool = false)
    {
        this.alpha = alpha;
        this.rotation = rotation;
        this.grayed = grayed;
    }
}
