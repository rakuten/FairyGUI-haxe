package fairygui;

import tweenx909.TweenX;
import tweenxcore.Tools.Easing;

import openfl.filters.ColorMatrixFilter;
import openfl.media.Sound;
import openfl.Lib;

import fairygui.utils.ColorMatrix;
import fairygui.utils.GTimers;
import fairygui.utils.ToolSet;
import fairygui.GObject;
import fairygui.utils.CompatUtil;
import fairygui.utils.EaseLookup;

class Transition
{
    public var autoPlay(get, set) : Bool;
    public var playing(get, never) : Bool;
    public var timeScale(get, set) : Float;

    public var name : String;
    public var autoPlayRepeat : Int = 0;
    public var autoPlayDelay : Float = 0;
    
    private var _owner : GComponent;
    private var _ownerBaseX : Float = 0;
    private var _ownerBaseY : Float = 0;
    private var _items : Array<TransitionItem>;
    private var _totalTimes : Int = 0;
    private var _totalTasks : Int = 0;
    private var _playing : Bool = false;
    private var _onComplete : Dynamic;
    private var _onCompleteParam : Dynamic;
    private var _options : Int = 0;
    private var _reversed : Bool = false;
    private var _maxTime : Float = 0;
    private var _autoPlay : Bool = false;
    private var _timeScale : Float = 0;
    
    public var OPTION_IGNORE_DISPLAY_CONTROLLER : Int = 1;
    
    private static inline var FRAME_RATE : Int = 24;
    
    public function new(owner : GComponent)
    {
        _owner = owner;
        _items = new Array<TransitionItem>();
        _maxTime = 0;
        autoPlayDelay = 0;
        _timeScale = 1;
    }
    
    private function get_autoPlay() : Bool
    {
        return _autoPlay;
    }
    
    private function set_autoPlay(value : Bool) : Bool
    {
        if (_autoPlay != value) 
        {
            _autoPlay = value;
            if (_autoPlay) 
            {
                if (_owner.onStage) 
                    play(null, null, autoPlayRepeat, autoPlayDelay);
            }
            else 
            {
                if (!_owner.onStage) 
                    stop(false, true);
            }
        }
        return value;
    }
    
    public function play(onComplete : Dynamic = null, onCompleteParam : Dynamic = null,
            times : Int = 1, delay : Float = 0) : Void
    {
        _play(onComplete, onCompleteParam, times, delay, false);
    }
    
    public function playReverse(onComplete : Dynamic = null, onCompleteParam : Dynamic = null,
            times : Int = 1, delay : Float = 0) : Void
    {
        _play(onComplete, onCompleteParam, 1, delay, true);
    }
    
    private function _play(onComplete : Dynamic = null, onCompleteParam : Dynamic = null,
            times : Int = 1, delay : Float = 0, reversed : Bool = false) : Void
    {
        stop();
        
        if (times < 0) 
            times = CompatUtil.INT_MAX_VALUE
        else if (times == 0) 
            times = 1;
        _totalTimes = times;
        _reversed = reversed;
        internalPlay(delay);
        _playing = _totalTasks > 0;
        
        if (_playing) 
        {
            _onComplete = onComplete;
            _onCompleteParam = onCompleteParam;
            
            _owner.internalVisible++;
            if ((_options & OPTION_IGNORE_DISPLAY_CONTROLLER) != 0) 
            {
                var cnt : Int = _items.length;
                for (i in 0...cnt){
                    var item : TransitionItem = _items[i];
                    if (item.target != null && item.target != _owner) 
                        item.target.internalVisible++;
                }
            }
        }
        else if (onComplete != null) 
        {
            if (onComplete.length > 0) 
                onComplete(onCompleteParam)
            else 
            onComplete();
        }
    }
    
    public function stop(setToComplete : Bool = true, processCallback : Bool = false) : Void
    {
        if (_playing) 
        {
            _playing = false;
            _totalTasks = 0;
            _totalTimes = 0;
            var func : Dynamic = _onComplete;
            var param : Dynamic = _onCompleteParam;
            _onComplete = null;
            _onCompleteParam = null;
            
            _owner.internalVisible--;
            var item : TransitionItem;
            var cnt : Int = _items.length;
            if (_reversed) 
            {
                var i : Int = cnt - 1;
                while (i >= 0){
                    item = _items[i];
                    if (item.target == null) 
                        {i--;continue;
                    };
                    
                    stopItem(item, setToComplete);
                    i--;
                }
            }
            else 
            {
                for (i in 0...cnt){
                    item = _items[i];
                    if (item.target == null) 
                        continue;
                    
                    stopItem(item, setToComplete);
                }
            }
            
            if (processCallback && func != null) 
            {
                if (func.length > 0) 
                    func(param)
                else 
                func();
            }
        }
    }
    
    private function stopItem(item : TransitionItem, setToComplete : Bool) : Void
    {
        if ((_options & OPTION_IGNORE_DISPLAY_CONTROLLER) != 0 && item.target != _owner) 
            item.target.internalVisible--;
        
        if (item.type == TransitionActionType.ColorFilter && item.filterCreated)
            item.target.filters = null;
        
        if (item.completed) 
            return;
        
        if (item.tweener != null) 
        {
            item.tweener.stop();
            item.tweener = null;
        }
        
        if (item.type == TransitionActionType.Transition) 
        {
            var trans : Transition = cast((item.target), GComponent).getTransition(item.value.s);
            if (trans != null) 
                trans.stop(setToComplete, false);
        }
        else if (item.type == TransitionActionType.Shake) 
        {
            if (GTimers.inst.exists(item.__shake)) 
            {
                GTimers.inst.remove(item.__shake);
                item.target._gearLocked = true;
                item.target.setXY(item.target.x - item.startValue.f1, item.target.y - item.startValue.f2);
                item.target._gearLocked = false;
            }
        }
        else 
        {
            if (setToComplete) 
            {
                if (item.tween) 
                {
                    if (!item.yoyo || item.repeat % 2 == 0) 
                        applyValue(item, (_reversed) ? item.startValue : item.endValue)
                    else 
                    applyValue(item, (_reversed) ? item.endValue : item.startValue);
                }
                else if (item.type != TransitionActionType.Sound) 
                    applyValue(item, item.value);
            }
        }
    }
    
    public function dispose() : Void
    {
        if (!_playing) 
            return;
        
        _playing = false;
        var cnt : Int = _items.length;
        for (i in 0...cnt){
            var item : TransitionItem = _items[i];
            if (item.target == null || item.completed) 
                continue;
            
            if (item.tweener != null) 
            {
                item.tweener.stop();
                item.tweener = null;
            }
            
            if (item.type == TransitionActionType.Transition) 
            {
                var trans : Transition = cast((item.target), GComponent).getTransition(item.value.s);
                if (trans != null) 
                    trans.dispose();
            }
            else if (item.type == TransitionActionType.Shake) 
            {
                GTimers.inst.remove(item.__shake);
            }
        }
    }
    
    private function get_playing() : Bool
    {
        return _playing;
    }
    
    public function setValue(label : String, args : Array<Dynamic>) : Void
    {
        var cnt : Int = _items.length;
        var value : TransitionValue;
        for (i in 0...cnt){
            var item : TransitionItem = _items[i];
            if (item.label == null && item.label2 == null) 
                continue;
            
            if (item.label == label) 
            {
                if (item.tween) 
                    value = item.startValue
                else 
                value = item.value;
            }
            else if (item.label2 == label) 
            {
                value = item.endValue;
            }
            else 
            continue;
            
            var _sw3_ = (item.type);            

            switch (_sw3_)
            {
                case TransitionActionType.XY, TransitionActionType.Size, TransitionActionType.Pivot, TransitionActionType.Scale, TransitionActionType.Skew:
                    value.b1 = true;
                    value.b2 = true;
                    value.f1 = Std.parseFloat(args[0]);
                    value.f2 = Std.parseFloat(args[1]);
                
                case TransitionActionType.Alpha:
                    value.f1 = Std.parseFloat(args[0]);
                
                case TransitionActionType.Rotation:
                    value.f1 = Std.parseInt(args[0]);
                
                case TransitionActionType.Color:
                    value.c = Std.parseInt(args[0]);
                
                case TransitionActionType.Animation:
                    value.i = Std.parseInt(args[0]);
                    if (args.length > 1) 
                        value.b = args[1];
                
                case TransitionActionType.Visible:
                    value.b = args[0];
                
                case TransitionActionType.Sound:
                    value.s = args[0];
                    if (args.length > 1) 
                        value.f1 = Std.parseFloat(args[1]);
                
                case TransitionActionType.Transition:
                    value.s = args[0];
                    if (args.length > 1) 
                        value.i = Std.parseInt(args[1]);
                
                case TransitionActionType.Shake:
                    value.f1 = Std.parseFloat(args[0]);
                    if (args.length > 1) 
                        value.f2 = Std.parseFloat(args[1]);
                
                case TransitionActionType.ColorFilter:
                    value.f1 = Std.parseFloat(args[0]);
                    value.f2 = Std.parseFloat(args[1]);
                    value.f3 = Std.parseFloat(args[2]);
                    value.f4 = Std.parseFloat(args[3]);
            }
        }
    }
    
    public function setHook(label : String, callback : Dynamic) : Void
    {
        var cnt : Int = _items.length;
        for (i in 0...cnt){
            var item : TransitionItem = _items[i];
            if (item.label == label) 
            {
                item.hook = callback;
                break;
            }
            else if (item.label2 == label) 
            {
                item.hook2 = callback;
                break;
            }
        }
    }
    
    public function clearHooks() : Void
    {
        var cnt : Int = _items.length;
        for (i in 0...cnt){
            var item : TransitionItem = _items[i];
            item.hook = null;
            item.hook2 = null;
        }
    }
    
    public function setTarget(label : String, newTarget : GObject) : Void
    {
        var cnt : Int = _items.length;
        for (i in 0...cnt){
            var item : TransitionItem = _items[i];
            if (item.label == label) 
                item.targetId = newTarget.id;
        }
    }
    
    public function setDuration(label : String, value : Float) : Void
    {
        var cnt : Int = _items.length;
        for (i in 0...cnt){
            var item : TransitionItem = _items[i];
            if (item.tween && item.label == label) 
                item.duration = value;
        }
    }
    
    private function get_timeScale() : Float
    {
        return _timeScale;
    }
    
    private function set_timeScale(value : Float) : Float
    {
        _timeScale = value;
        
        if (_playing) 
        {
            var cnt : Int = _items.length;
            for (i in 0...cnt){
                var item : TransitionItem = _items[i];
                if (item.tweener != null) 
                    item.tweener.timeScale = _timeScale;
            }
        }
        return value;
    }
    
    @:allow(fairygui)
    private function updateFromRelations(targetId : String, dx : Float, dy : Float) : Void
    {
        var cnt : Int = _items.length;
        if (cnt == 0) 
            return;
        
        for (i in 0...cnt){
            var item : TransitionItem = _items[i];
            if (item.type == TransitionActionType.XY && item.targetId == targetId) 
            {
                if (item.tween) 
                {
                    item.startValue.f1 += dx;
                    item.startValue.f2 += dy;
                    item.endValue.f1 += dx;
                    item.endValue.f2 += dy;
                }
                else 
                {
                    item.value.f1 += dx;
                    item.value.f2 += dy;
                }
            }
        }
    }
    
    private function internalPlay(delay : Float) : Void
    {
        _ownerBaseX = _owner.x;
        _ownerBaseY = _owner.y;
        
        _totalTasks = 0;
        var cnt : Int = _items.length;
        var parms : Dynamic;
        var i : Int;
        var item : TransitionItem;
        var startTime : Float;

        for (i in 0...cnt){
            item = _items[i];
            if (item.targetId != null)
                item.target = _owner.getChildById(item.targetId)
            else 
            item.target = _owner;
            if (item.target == null) 
                continue;
            
            if (item.tween) 
            {
                if (_reversed)
                    startTime = delay + _maxTime - item.time - item.duration
                else 
                startTime = delay + item.time;
                if(startTime>0 && (item.type==TransitionActionType.XY || item.type==TransitionActionType.Size))
                {
                    _totalTasks++;
                    item.completed = false;
                    item.tweener = TweenX.func(__delayCall.bind(item), startTime);
                    if(_timeScale!=1)
                        item.tweener.timeScale = _timeScale;

                }
                else
                {
                    startTween(item, startTime);
                }
            }
            else 
            {
                if (_reversed) 
                    startTime = delay + _maxTime - item.time
                else 
                startTime = delay + item.time;
                
                if (startTime == 0) 
                    applyValue(item, item.value)
                else 
                {
                    item.completed = false;
                    _totalTasks++;

                    item.tweener = TweenX.func(__delayCall2.bind(item), startTime);
                    if (_timeScale != 1) 
                        item.tweener.timeScale = _timeScale;
                }
            }
        }
    }
    
    private function startTween(item : TransitionItem, delay:Float) : Void
    {
        var parms : Dynamic = { };

        var startValue:TransitionValue;
        var endValue:TransitionValue;

        if (_reversed) 
        {
            startValue = item.endValue;
            endValue = item.startValue;

        }
        else 
        {
            startValue = item.startValue;
            endValue = item.endValue;
        }
        var _sw4_ = item.type;
        switch(_sw4_)
        {
            case TransitionActionType.XY,TransitionActionType.Size:
                if(item.type==TransitionActionType.XY)
                {
                    if (item.target == _owner)
                    {
                        if(!startValue.b1)
                            startValue.f1 = 0;
                        if(!startValue.b2)
                            startValue.f2 = 0;
                    }
                    else
                    {
                        if(!startValue.b1)
                            startValue.f1 = item.target.x;
                        if(!startValue.b2)
                            startValue.f2 = item.target.y;
                    }
                }
                else
                {
                    if(!startValue.b1)
                        startValue.f1 = item.target.width;
                    if(!startValue.b2)
                        startValue.f2 = item.target.height;
                }


                item.value.f1 = startValue.f1;
                item.value.f2 = startValue.f2;

                if (!item.endValue.b1)
                    item.endValue.f1 = item.value.f1;
                if (!item.endValue.b2)
                    item.endValue.f2 = item.value.f2;

                item.value.b1 = startValue.b1 || endValue.b1;
                item.value.b2 = startValue.b2 || endValue.b2;

                parms.f1 = item.endValue.f1;
                parms.f2 = item.endValue.f2;
            case TransitionActionType.Scale,TransitionActionType.Skew:
                item.value.f1 = startValue.f1;
                item.value.f2 = startValue.f2;
                parms.f1 = endValue.f1;
                parms.f2 = endValue.f2;

            case TransitionActionType.Alpha:
                item.value.f1 = startValue.f1;
                parms.f1 = endValue.f1;

            case TransitionActionType.Rotation:
                item.value.f1 = startValue.f1;
                parms.f1 = endValue.f1;

            case TransitionActionType.Color:
                item.value.c = startValue.c;
                parms.hexColors = { c:endValue.c};

            case TransitionActionType.ColorFilter:
                item.value.f1 = startValue.f1;
                item.value.f2 = startValue.f2;
                item.value.f3 = startValue.f3;
                item.value.f4 = startValue.f4;
                parms.f1 = endValue.f1;
                parms.f2 = endValue.f2;
                parms.f3 = endValue.f3;
                parms.f4 = endValue.f4;
        }
        var itemDelay:Float = 0;
        if (delay > 0)
            itemDelay = delay;
        else
            applyValue(item, item.value);

        var itemRepeat:Int = 0;
        var itemYoyo:Bool = false;
        if (item.repeat != 0) 
        {
            if (item.repeat == -1)
                itemRepeat = CompatUtil.INT_MAX_VALUE
            else
                itemRepeat = item.repeat;
            itemYoyo = item.yoyo;
        }

        _totalTasks++;
        item.completed = false;

        item.tweener = TweenX.to(item.value, parms, 0, itemDelay, itemRepeat, itemYoyo).ease(item.easeType).onPlay(__tweenStart.bind(item)).onUpdate(__tweenUpdate.bind(item)).onFinish(__tweenComplete.bind(item));
        if (_timeScale != 1) 
            item.tweener.timeScale=_timeScale;
    }
    
    private function __delayCall(item : TransitionItem) : Void
    {
        item.tweener = null;
        _totalTasks--;

        startTween(item, 0);
    }
    
    private function __delayCall2(item : TransitionItem) : Void
    {
        item.tweener = null;
        _totalTasks--;
        item.completed = true;
        
        applyValue(item, item.value);
        if (item.hook != null) 
            item.hook();
        
        checkAllComplete();
    }
    
    private function __tweenStart(item : TransitionItem) : Void
    {
        if (item.hook != null) 
            item.hook();
    }
    
    private function __tweenUpdate(item : TransitionItem) : Void
    {
        applyValue(item, item.value);
    }
    
    private function __tweenComplete(item : TransitionItem) : Void
    {
        item.tweener = null;
        _totalTasks--;
        item.completed = true;
        if (item.hook2 != null) 
            item.hook2();
        
        checkAllComplete();
    }
    
    private function __playTransComplete(item : TransitionItem) : Void
    {
        _totalTasks--;
        item.completed = true;
        checkAllComplete();
    }
    
    private function checkAllComplete() : Void
    {
        if (_playing && _totalTasks == 0) 
        {
            if (_totalTimes < 0) 
            {
                internalPlay(0);
            }
            else 
            {
                _totalTimes--;
                if (_totalTimes > 0) 
                    internalPlay(0)
                else 
                {
                    _playing = false;
                    _owner.internalVisible--;
                    
                    var cnt : Int = _items.length;
                    for (i in 0...cnt){
                        var item : TransitionItem = _items[i];
                        if (item.target != null) 
                        {
                            if ((_options & OPTION_IGNORE_DISPLAY_CONTROLLER) != 0 && item.target != _owner) 
                                item.target.internalVisible--;
                        }
                        
                        if (item.filterCreated) 
                        {
                            item.filterCreated = false;
                            item.target.filters = null;
                        }
                    }
                    
                    if (_onComplete != null) 
                    {
                        var func :Dynamic = _onComplete;
                        var param : Dynamic = _onCompleteParam;
                        _onComplete = null;
                        _onCompleteParam = null;
                        if (func.length > 0) 
                            func(param)
                        else 
                        func();
                    }
                }
            }
        }
    }
    
    private function applyValue(item : TransitionItem, value : TransitionValue) : Void
    {
        item.target._gearLocked = true;
        
        var _sw6_ = item.type;

        switch (_sw6_)
        {
            case TransitionActionType.XY:
                if (item.target == _owner) 
                {
                    var f1 : Float;
                    var f2 : Float;
                    if (!value.b1) 
                        f1 = item.target.x
                    else 
                    f1 = value.f1 + _ownerBaseX;
                    if (!value.b2) 
                        f2 = item.target.y
                    else 
                        f2 = value.f2 + _ownerBaseY;
                    item.target.setXY(f1, f2);
                }
                else 
                {
                    if (!value.b1) 
                        value.f1 = item.target.x;

                    if (!value.b2) 
                        value.f2 = item.target.y;

                    item.target.setXY(value.f1, value.f2);
                }
            
            case TransitionActionType.Size:
                if (!value.b1) 
                    value.f1 = item.target.width;

                if (!value.b2) 
                    value.f2 = item.target.height;

                item.target.setSize(value.f1, value.f2);
            
            case TransitionActionType.Pivot:
                item.target.setPivot(value.f1, value.f2);
            
            case TransitionActionType.Alpha:
                item.target.alpha = value.f1;
            
            case TransitionActionType.Rotation:
                item.target.rotation = value.f1;
            
            case TransitionActionType.Scale:
                item.target.setScale(value.f1, value.f2);
            
            case TransitionActionType.Skew:

            case TransitionActionType.Color:
                cast((item.target), IColorGear).color = value.c;
            
            case TransitionActionType.Animation:
                if (!value.b1) 
                    value.i = cast((item.target), IAnimationGear).frame;

                cast((item.target), IAnimationGear).frame = value.i;
                cast((item.target), IAnimationGear).playing = value.b;
            
            case TransitionActionType.Visible:
                item.target.visible = value.b;
            
            case TransitionActionType.Transition:
                var trans : Transition = cast((item.target), GComponent).getTransition(value.s);
                if (trans != null) 
                {
                    if (value.i == 0) 
                        trans.stop(false, true)
                    else if (trans.playing) 
                        trans._totalTimes = value.i == -(1) ? CompatUtil.INT_MAX_VALUE : value.i
                    else 
                    {
                        item.completed = false;
                        _totalTasks++;
                        if (_reversed) 
                            trans.playReverse(__playTransComplete, item, value.i)
                        else 
                        trans.play(__playTransComplete, item, value.i);
                        if (_timeScale != 1) 
                            trans.timeScale = _timeScale;
                    }
                }
            
            case TransitionActionType.Sound:
                var pi : PackageItem = UIPackage.getItemByURL(value.s);
                if (pi != null) 
                {
                    var sound : Sound = pi.owner.getSound(pi);
                    if (sound != null) 
                        GRoot.inst.playOneShotSound(sound, value.f1);
                }
            
            case TransitionActionType.Shake:
                item.startValue.f1 = 0;  //offsetX  
                item.startValue.f2 = 0;  //offsetY  
                item.startValue.f3 = item.value.f2;  //shakePeriod  
                item.startValue.i = Lib.getTimer();  //startTime
                GTimers.inst.add(1, 0, item.__shake, this.shakeItem);
                _totalTasks++;
                item.completed = false;
            
            case TransitionActionType.ColorFilter:
                var cf : ColorMatrixFilter;
                var arr : Array<Dynamic> = item.target.filters;
                
                if (arr == null || !(Std.is(arr[0], ColorMatrixFilter))) 
                {
                    cf = new ColorMatrixFilter();
                    arr = [cf];
                    item.filterCreated = true;
                }
                else 
                cf = cast((arr[0]), ColorMatrixFilter);
                
                var cm : ColorMatrix = new ColorMatrix();
                cm.adjustBrightness(value.f1);
                cm.adjustContrast(value.f2);
                cm.adjustSaturation(value.f3);
                cm.adjustHue(value.f4);
                cf.matrix = cm;
                item.target.filters = arr;
        }
        
        item.target._gearLocked = false;
    }
    
    private function shakeItem(item : TransitionItem) : Void
    {
        var r : Float = Math.ceil(item.value.f1 * item.startValue.f3 / item.value.f2);
        var rx : Float = (Math.random() * 2 - 1) * r;
        var ry : Float = (Math.random() * 2 - 1) * r;
        rx = (rx > 0) ? Math.ceil(rx) : Math.floor(rx);
        ry = (ry > 0) ? Math.ceil(ry) : Math.floor(ry);
        
        item.target._gearLocked = true;
        item.target.setXY(item.target.x - item.startValue.f1 + rx, item.target.y - item.startValue.f2 + ry);
        item.target._gearLocked = false;
        
        item.startValue.f1 = rx;
        item.startValue.f2 = ry;
        
        var t : Int = Lib.getTimer();
        item.startValue.f3 -= (t - item.startValue.i) / 1000;
        item.startValue.i = t;
        if (item.startValue.f3 <= 0) 
        {
            item.target._gearLocked = true;
            item.target.setXY(item.target.x - item.startValue.f1, item.target.y - item.startValue.f2);
            item.target._gearLocked = false;
            
            item.completed = true;
            _totalTasks--;
            GTimers.inst.remove(item.__shake);
            
            checkAllComplete();
        }
    }
    
    public function setup(xml : FastXML) : Void
    {
        this.name = xml.att.name;
        var str : String = xml.att.options;
        if (str != null) 
            _options = Std.parseInt(str);
        this._autoPlay = xml.att.autoPlay == "true";
        if(this._autoPlay)
        {
            str = xml.att.autoPlayRepeat;
            if(str != null)
                this.autoPlayRepeat = Std.parseInt(str);
                str = xml.att.autoPlayDelay;
            if(str != null)
                this.autoPlayDelay = Std.parseFloat(str);
        }


        var col : FastXMLList = xml.nodes.item;
        for (cxml in col.iterator())
        {
            var item : TransitionItem = new TransitionItem();
            _items.push(item);
            
            item.time = Std.parseInt(cxml.att.time) / FRAME_RATE;
            item.targetId = cxml.att.target;
            str = cxml.att.type;
            switch (str)
            {
                case "XY":
                    item.type = TransitionActionType.XY;
                case "Size":
                    item.type = TransitionActionType.Size;
                case "Scale":
                    item.type = TransitionActionType.Scale;
                case "Pivot":
                    item.type = TransitionActionType.Pivot;
                case "Alpha":
                    item.type = TransitionActionType.Alpha;
                case "Rotation":
                    item.type = TransitionActionType.Rotation;
                case "Color":
                    item.type = TransitionActionType.Color;
                case "Animation":
                    item.type = TransitionActionType.Animation;
                case "Visible":
                    item.type = TransitionActionType.Visible;
                case "Sound":
                    item.type = TransitionActionType.Sound;
                case "Transition":
                    item.type = TransitionActionType.Transition;
                case "Shake":
                    item.type = TransitionActionType.Shake;
                case "ColorFilter":
                    item.type = TransitionActionType.ColorFilter;
                case "Skew":
                    item.type = TransitionActionType.Skew;
                default:
                    item.type = TransitionActionType.Unknown;
            }
            item.tween = cxml.att.tween == "true";
            item.label = cxml.att.label;
            if (item.label == null || item.label.length == 0)
                item.label = null;
            
            if (item.tween) 
            {
                item.duration = Std.parseInt(cxml.att.duration) / FRAME_RATE;
                if (item.time + item.duration > _maxTime) 
                    _maxTime = item.time + item.duration;
                
                str = cxml.att.ease;
                if (str != null) 
                {
                    var pos : Int = str.indexOf(".");
                    if (pos != -1) 
                        str = str.substr(0, pos) + ".ease" + str.substr(pos + 1);
                    if (str == "Linear") 
                        item.easeType = EaseLookup.find("linear.easenone")
                    else 
                    item.easeType = EaseLookup.find(str);
                }
                
                item.repeat = Std.parseInt(cxml.att.repeat);
                item.yoyo = cxml.att.yoyo == "true";
                item.label2 = cxml.att.label2;
                if (item.label2 == null || item.label2.length == 0)
                    item.label2 = null;
                
                var v : String = cxml.att.endValue;
                if (v != null) 
                {
                    decodeValue(item.type, cxml.att.startValue, item.startValue);
                    decodeValue(item.type, v, item.endValue);
                }
                else 
                {
                    item.tween = false;
                    decodeValue(item.type, cxml.att.startValue, item.value);
                }
            }
            else 
            {
                if (item.time > _maxTime)
                    _maxTime = item.time;
                decodeValue(item.type, cxml.att.value, item.value);
            }
        }
    }
    
    private function decodeValue(type : Int, str : String, value : TransitionValue) : Void
    {
        var arr : Array<Dynamic>;
        switch (type)
        {
            case TransitionActionType.XY, TransitionActionType.Size, TransitionActionType.Pivot, TransitionActionType.Skew:
                arr = str.split(",");
                if (arr[0] == "-") 
                {
                    value.b1 = false;
                }
                else 
                {
                    value.f1 = Std.parseFloat(arr[0]);
                    value.b1 = true;
                }
                if (arr[1] == "-") 
                {
                    value.b2 = false;
                }
                else 
                {
                    value.f2 = Std.parseFloat(arr[1]);
                    value.b2 = true;
                }
            
            case TransitionActionType.Alpha:
                value.f1 = Std.parseFloat(str);
            
            case TransitionActionType.Rotation:
                value.f1 = Std.parseInt(str);
            
            case TransitionActionType.Scale:
                arr = str.split(",");
                value.f1 = Std.parseFloat(arr[0]);
                value.f2 = Std.parseFloat(arr[1]);
            
            case TransitionActionType.Color:
                value.c = ToolSet.convertFromHtmlColor(str);
            
            case TransitionActionType.Animation:
                arr = str.split(",");
                if (arr[0] == "-") 
                {
                    value.b1 = false;
                }
                else 
                {
                    value.i = Std.parseInt(arr[0]);
                    value.b1 = true;
                }
                value.b = arr[1] == "p";
            
            case TransitionActionType.Visible:
                value.b = str == "true";
            
            case TransitionActionType.Sound:
                arr = str.split(",");
                value.s = arr[0];
                if (arr.length > 1) 
                {
                    var intv : Int = Std.parseInt(arr[1]);
                    if (intv == 0 || intv == 100) 
                        value.f1 = 1
                    else 
                    value.f1 = intv / 100;
                }
                else 
                value.f1 = 1;
            
            case TransitionActionType.Transition:
                arr = str.split(",");
                value.s = arr[0];
                if (arr.length > 1) 
                    value.i = Std.parseInt(arr[1])
                else 
                value.i = 1;
            
            case TransitionActionType.Shake:
                arr = str.split(",");
                value.f1 = Std.parseFloat(arr[0]);
                value.f2 = Std.parseFloat(arr[1]);
            
            case TransitionActionType.ColorFilter:
                arr = str.split(",");
                value.f1 = Std.parseFloat(arr[0]);
                value.f2 = Std.parseFloat(arr[1]);
                value.f3 = Std.parseFloat(arr[2]);
                value.f4 = Std.parseFloat(arr[3]);
        }
    }
}




class TransitionActionType
{
    public static inline var XY : Int = 0;
    public static inline var Size : Int = 1;
    public static inline var Scale : Int = 2;
    public static inline var Pivot : Int = 3;
    public static inline var Alpha : Int = 4;
    public static inline var Rotation : Int = 5;
    public static inline var Color : Int = 6;
    public static inline var Animation : Int = 7;
    public static inline var Visible : Int = 8;
    public static inline var Sound : Int = 9;
    public static inline var Transition : Int = 10;
    public static inline var Shake : Int = 11;
    public static inline var ColorFilter : Int = 12;
    public static inline var Skew : Int = 13;
    public static inline var Unknown : Int = 14;

    public function new()
    {
    }
}

class TransitionItem
{
    public var time : Float = 0;
    public var targetId : String;
    public var type : Int = 0;
    public var duration : Float = 0;
    public var value : TransitionValue;
    public var startValue : TransitionValue;
    public var endValue : TransitionValue;
    public var easeType : Float->Float;
    public var repeat : Int = 0;
    public var yoyo : Bool = false;
    public var tween : Bool = false;
    public var label : String;
    public var label2 : String;
    public var hook :Dynamic;
    public var hook2 :Dynamic;
    public var tweener : TweenX;
    public var completed : Bool = false;
    public var target : GObject;
    public var filterCreated : Bool = false;
    
    public var params : Array<Dynamic>;
    public function new()
    {
        easeType = Easing.quadOut;
        value = new TransitionValue();
        startValue = new TransitionValue();
        endValue = new TransitionValue();
        params = [this];
    }
    
    public function __shake(param : Dynamic) : Void
    {
        param(this);
    }
}

class TransitionValue
{
    public var f1 : Float = 0;  //x, scalex, pivotx,alpha,shakeAmplitude,rotation
    public var f2 : Float = 0;  //y, scaley, pivoty, shakePeriod
    public var f3 : Float = 0;
    public var f4 : Float = 0;
    public var i : Int = 0;  //frame
    public var c : Int = 0;  //color
    public var b : Bool = false;  //playing
    public var s : String;  //sound,transName  
    
    public var b1 : Bool = true;
    public var b2 : Bool = true;
    
    public function new()
    {
    }
}

