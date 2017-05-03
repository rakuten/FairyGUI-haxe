package fairygui;

import openfl.system.System;
import tweenxcore.Tools.Easing;
import tweenx909.TweenX;
import fairygui.GTextField;


class GProgressBar extends GComponent
{
    public var titleType(get, set) : Int;
    public var max(get, set) : Float;
    @:isVar public var value(get, set) : Float;

    private var _max : Float;
    private var _value : Float;
    private var _titleType : Int = 0;
    private var _reverse : Bool = false;
    
    private var _titleObject : GTextField;
    private var _aniObject : GObject;
    private var _barObjectH : GObject;
    private var _barObjectV : GObject;
    private var _barMaxWidth : Int = 0;
    private var _barMaxHeight : Int = 0;
    private var _barMaxWidthDelta : Int = 0;
    private var _barMaxHeightDelta : Int = 0;
    private var _barStartX : Int = 0;
    private var _barStartY : Int = 0;
    
    private var _tweener : TweenX;
    public var _tweenValue : Float = 0;
    
    public function new()
    {
        super();

        _titleType = ProgressTitleType.Percent;
        _value = 50;
        _max = 100;
    }
    
    @:final private function get_titleType() : Int
    {
        return _titleType;
    }
    
    @:final private function set_titleType(value : Int) : Int
    {
        if (_titleType != value) 
        {
            _titleType = value;
            update(_value);
        }
        return value;
    }
    
    @:final private function get_max() : Float
    {
        return _max;
    }
    
    @:final private function set_max(value : Float) : Float
    {
        if (_max != value) 
        {
            _max = value;
            update(_value);
        }
        return value;
    }
    
    @:final private function get_value() : Float
    {
        return _value;
    }
    
    @:final private function set_value(value : Float) : Float
    {
        if (_tweener != null) 
        {
            _tweener.stop();
            _tweener = null;
        }
        
        if (_value != value) 
        {
            _value = value;
            update(_value);
        }
        return value;
    }
    
    public function tweenValue(value : Float, duration : Float) : TweenX
    {
        if (_value != value) 
        {
            if (_tweener != null) 
                _tweener.stop();
            
            _tweenValue = _value;
            _value = value;
            _tweener = TweenX.to(this, {_tweenValue : value},duration,Easing.linear).onUpdate(onTweenUpdate).onFinish(onTweenComplete);
            return _tweener;
        }
        else 
        return null;
    }
    
    private function onTweenUpdate() : Void
    {
        update(_tweenValue);
    }

    private function onTweenComplete():Void
    {
        _tweener = null;
    }
    
    public function update(newValue : Float) : Void
    {
        var percent:Float = _max!=0 ? Math.min(newValue/_max,1) : 0;
        if (_titleObject != null) 
        {
            switch (_titleType)
            {
                case ProgressTitleType.Percent:
                    _titleObject.text = Math.round(percent * 100) + "%";
                
                case ProgressTitleType.ValueAndMax:
                    _titleObject.text = Math.round(newValue) + "/" + Math.round(_max);
                
                case ProgressTitleType.Value:
                    _titleObject.text = "" + Math.round(newValue);
                
                case ProgressTitleType.Max:
                    _titleObject.text = "" + Math.round(_max);
            }
        }
        
        var fullWidth : Int = Std.int(this.width - this._barMaxWidthDelta);
        var fullHeight : Int = Std.int(this.height - this._barMaxHeightDelta);
        if (!_reverse) 
        {
            if (_barObjectH != null) 
                _barObjectH.width = fullWidth * percent;
            if (_barObjectV != null) 
                _barObjectV.height = fullHeight * percent;
        }
        else 
        {
            if (_barObjectH != null) 
            {
                _barObjectH.width = fullWidth * percent;
                _barObjectH.x = _barStartX + (fullWidth - _barObjectH.width);
            }
            if (_barObjectV != null) 
            {
                _barObjectV.height = fullHeight * percent;
                _barObjectV.y = _barStartY + (fullHeight - _barObjectV.height);
            }
        }
        if (Std.is(_aniObject, GMovieClip)) 
            cast((_aniObject), GMovieClip).frame = Math.round(percent * 100)
        else if (Std.is(_aniObject, GSwfObject)) 
            cast((_aniObject), GSwfObject).frame = Math.round(percent * 100);
    }
    
    override private function constructFromXML(xml : FastXML) : Void
    {
        super.constructFromXML(xml);
        
        xml = xml.nodes.ProgressBar.get(0);
        
        var str : String;
        str = xml.att.titleType;
        if (str != null) 
            _titleType = ProgressTitleType.parse(str);
        
        _reverse = xml.att.reverse == "true";
        
        _titleObject = try cast(getChild("title"), GTextField) catch(e:Dynamic) null;
        _barObjectH = getChild("bar");
        _barObjectV = getChild("bar_v");
        _aniObject = getChild("ani");
        
        if (_barObjectH != null) 
        {
            _barMaxWidth = Std.int(_barObjectH.width);
            _barMaxWidthDelta = Std.int(this.width - _barMaxWidth);
            _barStartX = Std.int(_barObjectH.x);
        }
        if (_barObjectV != null) 
        {
            _barMaxHeight = Std.int(_barObjectV.height);
            _barMaxHeightDelta = Std.int(this.height - _barMaxHeight);
            _barStartY = Std.int(_barObjectV.y);
        }
    }
    
    override private function handleSizeChanged() : Void
    {
        super.handleSizeChanged();
        
        if (_barObjectH != null) 
            _barMaxWidth = Std.int(this.width - _barMaxWidthDelta);
        if (_barObjectV != null) 
            _barMaxHeight = Std.int(this.height - _barMaxHeightDelta);
        if (!this._underConstruct) 
            update(_value);
    }
    
    override public function setup_afterAdd(xml : FastXML) : Void
    {
        super.setup_afterAdd(xml);
        
        xml = xml.nodes.ProgressBar.get(0);
        if (xml != null) 
        {
            _value = Std.parseInt(xml.att.value);
            if (Math.isNaN(_value))
                _value = 0;
            _max = Std.parseInt(xml.att.max);
            if (Math.isNaN(_max))
                _max = 0;
        }
        update(_value);
    }
    
    override public function dispose() : Void
    {
        if (_tweener != null) 
            _tweener.stop();
        super.dispose();
    }
}
