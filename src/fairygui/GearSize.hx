package fairygui;

import tweenx909.TweenX;
import fairygui.GObject;


class GearSize extends GearBase
{
    public var tweener : TweenX;
    
    private var _storage : Map<String,GearSizeValue>;
    private var _default : GearSizeValue;
    private var _tweenValue : GearSizeValue;
    
    public function new(owner : GObject)
    {
        super(owner);
    }
    
    override private function init() : Void
    {
        _default = new GearSizeValue(_owner.width, _owner.height, _owner.scaleX, _owner.scaleY);
        _storage = new Map<String, GearSizeValue>();
    }
    
    override private function addStatus(pageId : String, value : String) : Void
    {
        if (value == "-") 
            return;
        
        var arr : Array<Dynamic> = value.split(",");
        var gv : GearSizeValue;
        if (pageId == null) 
            gv = _default
        else 
        {
            gv = new GearSizeValue();
            _storage[pageId] = gv;
        }
        gv.width = Std.parseInt(arr[0]);
        gv.height = Std.parseInt(arr[1]);
        if (arr.length > 2) 
        {
            gv.scaleX = Std.parseFloat(arr[2]);
            gv.scaleY = Std.parseFloat(arr[3]);
        }
    }
    
    override public function apply() : Void
    {
        var gv : GearSizeValue = _storage[_controller.selectedPageId];
        if (gv == null) 
            gv = _default;
        
        if (_tween && UIPackage._constructing <=0 && !GearBase.disableAllTweenEffect)
        {
            var a : Bool;
            var b : Bool;
            if (tweener != null) 
            {
                a = tweener.vars.onUpdateParams[0];
                b = tweener.vars.onUpdateParams[1];
                if (a && (tweener.vars.width != gv.width || tweener.vars.height != gv.height) || b && (tweener.vars.scaleX != gv.scaleX || tweener.vars.scaleY != gv.scaleY)) 
                {
                    _owner._gearLocked = true;
                    if (a) 
                        _owner.setSize(tweener.vars.width, tweener.vars.height,  _owner.checkGearController(1, _controller));
                    if (b) 
                        _owner.setScale(tweener.vars.scaleX, tweener.vars.scaleY);
                    _owner._gearLocked = false;
                    tweener.stop();
                    tweener = null;
                    if(_displayLockToken!=0)
                    {
                        _owner.releaseDisplayLock(_displayLockToken);
                        _displayLockToken = 0;
                    }
                }
                else 
                return;
            }
            
            a = gv.width != _owner.width || gv.height != _owner.height;
            b = gv.scaleX != _owner.scaleX || gv.scaleY != _owner.scaleY;
            if (a || b) 
            {
                if(_owner.checkGearController(0, _controller))
                    _displayLockToken = _owner.addDisplayLock();
                var vars =
                {
                    width : gv.width,
                    height : gv.height,
                    scaleX : gv.scaleX,
                    scaleY : gv.scaleY
                };
                if (_tweenValue == null)
                    _tweenValue = new GearSizeValue(0, 0, 0, 0);
                _tweenValue.width = _owner.width;
                _tweenValue.height = _owner.height;
                _tweenValue.scaleX = _owner.scaleX;
                _tweenValue.scaleY = _owner.scaleY;
                tweener = TweenX.to(_tweenValue, vars, _tweenTime).ease(_easeType).delay(_delay).onUpdate(__tweenUpdate.bind(a, b)).onFinish(__tweenComplete);
            }
        }
        else 
        {
            _owner._gearLocked = true;
            _owner.setSize(gv.width, gv.height, _owner.checkGearController(1, _controller));
            _owner.setScale(gv.scaleX, gv.scaleY);
            _owner._gearLocked = false;
        }
    }
    
    private function __tweenUpdate(a : Bool, b : Bool) : Void
    {
        _owner._gearLocked = true;
        if (a) 
            _owner.setSize(_tweenValue.width, _tweenValue.height, _owner.checkGearController(1, _controller));
        if (b) 
            _owner.setScale(_tweenValue.scaleX, _tweenValue.scaleY);
        _owner._gearLocked = false;
    }
    
    private function __tweenComplete() : Void
    {
        if(_displayLockToken!=0)
        {
            _owner.releaseDisplayLock(_displayLockToken);
            _displayLockToken = 0;
        }
        tweener = null;
    }
    
    override public function updateState() : Void
    {
        var gv : GearSizeValue = _storage[_controller.selectedPageId];
        if (gv == null) 
        {
            gv = new GearSizeValue();
            _storage[_controller.selectedPageId] = gv;
        }
        
        gv.width = _owner.width;
        gv.height = _owner.height;
        gv.scaleX = _owner.scaleX;
        gv.scaleY = _owner.scaleY;
    }
    
    override public function updateFromRelations(dx : Float, dy : Float) : Void
    {
        if (_controller == null || _storage == null) 
            return;
        
        for (gv in _storage.iterator())
        {
            gv.width += dx;
            gv.height += dy;
        }
        cast((_default), GearSizeValue).width += dx;
        cast((_default), GearSizeValue).height += dy;
        
        updateState();
    }
}



class GearSizeValue
{
    public var width : Float;
    public var height : Float;
    public var scaleX : Float;
    public var scaleY : Float;
    
    public function new(width : Float = 0, height : Float = 0, scaleX : Float = 0, scaleY : Float = 0)
    {
        this.width = width;
        this.height = height;
        this.scaleX = scaleX;
        this.scaleY = scaleY;
    }
}