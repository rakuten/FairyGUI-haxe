package fairygui;

import tweenx909.TweenX;
import fairygui.GObject;

import openfl.geom.Point;

class GearLook extends GearBase
{
    public var tweener:TweenX;

    private var _storage:Map<String, GearLookValue>;
    private var _default:GearLookValue;
    private var _tweenValue:Point;

    public function new(owner:GObject)
    {
        super(owner);
    }

    override private function init():Void
    {
        _default = new GearLookValue(_owner.alpha, _owner.rotation, _owner.grayed);
        _storage = new Map<String, GearLookValue>();
    }

    override private function addStatus(pageId:String, value:String):Void
    {
        if (value == "-")
            return;

        var arr:Array<String> = value.split(",");
        var gv:GearLookValue;
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
    private var a:Bool;
    private var b:Bool;

    override public function apply():Void
    {
        var gv:GearLookValue = _storage[_controller.selectedPageId];
        if (gv == null)
            gv = _default;

        if (_tween && UIPackage._constructing < 1 && !GearBase.disableAllTweenEffect)
        {
            _owner._gearLocked = true;
            _owner.grayed = gv.grayed;
            _owner._gearLocked = false;

//            var a : Bool;
//            var b : Bool;
            if (tweener != null)
            {
//                a = tweener.vars.onUpdateParams[0];
//                b = tweener.vars.onUpdateParams[1];
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
                    if (_displayLockToken != 0)
                    {
                        _owner.releaseDisplayLock(_displayLockToken);
                        _displayLockToken = 0;
                    }
                }
                else
                {
                    return;
                }
            }

            a = gv.alpha != _owner.alpha;
            b = gv.rotation != _owner.rotation;
            if (a || b)
            {
                if (_owner.checkGearController(0, _controller))
                    _displayLockToken = _owner.addDisplayLock();
                var vars =
                {
                    x : gv.alpha,
                    y : gv.rotation
                };

                if (_tweenValue == null)
                    _tweenValue = new Point();
                _tweenValue.x = _owner.alpha;
                _tweenValue.y = _owner.rotation;
                tweener = TweenX.to(_tweenValue, vars, _tweenTime).ease(_easeType).delay(_delay).onUpdate(__tweenUpdate.bind(a, b)).onFinish(__tweenComplete);
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

    private function __tweenUpdate(val1:Bool, val2:Bool):Void
    {
        _owner._gearLocked = true;
        if (val1)
            _owner.alpha = _tweenValue.x;
        if (val2)
            _owner.rotation = Std.int(_tweenValue.y);
        _owner._gearLocked = false;
    }

    private function __tweenComplete():Void
    {
        if (_displayLockToken != 0)
        {
            _owner.releaseDisplayLock(_displayLockToken);
            _displayLockToken = 0;
        }
        tweener = null;
    }

    override public function updateState():Void
    {
        var gv:GearLookValue = _storage[_controller.selectedPageId];
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
    public var alpha:Float;
    public var rotation:Float;
    public var grayed:Bool;

    public function new(alpha:Float = 0, rotation:Float = 0, grayed:Bool = false)
    {
        this.alpha = alpha;
        this.rotation = rotation;
        this.grayed = grayed;
    }
}
