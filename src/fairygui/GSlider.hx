package fairygui;

import fairygui.event.GTouchEvent;
import fairygui.event.StateChangeEvent;
import fairygui.GTextField;
import openfl.geom.Point;

@:meta(Event(name = "stateChanged", type = "fairygui.event.StateChangeEvent"))

class GSlider extends GComponent
{
    public var titleType(get, set):Int;
    public var max(get, set):Int;
    public var value(get, set):Int;

    private var _max:Int = 0;
    private var _value:Int = 0;
    private var _titleType:Int = 0;
    private var _reverse:Bool = false;

    private var _titleObject:GTextField;
    private var _barObjectH:GObject;
    private var _barObjectV:GObject;
    private var _barMaxWidth:Int = 0;
    private var _barMaxHeight:Int = 0;
    private var _barMaxWidthDelta:Int = 0;
    private var _barMaxHeightDelta:Int = 0;
    private var _gripObject:GObject;
    private var _clickPos:Point;
    private var _clickPercent:Float = 0;
    private var _barStartX:Int;
    private var _barStartY:Int;

    public var changeOnClick:Bool = true;

    /**是否可拖动开关**/
    public var canDrag:Bool = true;

    public function new()
    {
        super();

        _titleType = ProgressTitleType.Percent;
        _value = 50;
        _max = 100;
        _clickPos = new Point();
    }

    @:final private function get_titleType():Int
    {
        return _titleType;
    }

    @:final private function set_titleType(value:Int):Int
    {
        _titleType = value;
        return value;
    }

    @:final private function get_max():Int
    {
        return _max;
    }

    @:final private function set_max(value:Int):Int
    {
        if (_max != value)
        {
            _max = value;
            update();
        }
        return value;
    }

    @:final private function get_value():Int
    {
        return _value;
    }

    @:final private function set_value(value:Int):Int
    {
        if (_value != value)
        {
            _value = value;
            update();
        }
        return value;
    }

    public function update():Void
    {
        var percent:Float = Math.min(_value / _max, 1);
        updateWidthPercent(percent);
    }

    private function updateWidthPercent(percent:Float):Void
    {
        if (_titleObject != null)
        {
            switch (_titleType)
            {
                case ProgressTitleType.Percent:
                    _titleObject.text = Math.round(percent * 100) + "%";

                case ProgressTitleType.ValueAndMax:
                    _titleObject.text = _value + "/" + _max;

                case ProgressTitleType.Value:
                    _titleObject.text = "" + _value;

                case ProgressTitleType.Max:
                    _titleObject.text = "" + _max;
            }
        }

        var fullWidth:Int = Std.int(this.width - this._barMaxWidthDelta);
        var fullHeight:Int = Std.int(this.height - this._barMaxHeightDelta);
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
                _barObjectH.width = Math.round(fullWidth * percent);
                _barObjectH.x = _barStartX + (fullWidth - _barObjectH.width);
            }
            if (_barObjectV != null)
            {
                _barObjectV.height = Math.round(fullHeight * percent);
                _barObjectV.y = _barStartY + (fullHeight - _barObjectV.height);
            }
        }
    }

    override private function constructFromXML(xml:FastXML):Void
    {
        super.constructFromXML(xml);

        xml = xml.nodes.Slider.get(0);

        var str:String;
        str = xml.att.titleType;
        if (str != null)
            _titleType = ProgressTitleType.parse(str);

        _reverse = xml.att.reverse == "true";

        _titleObject = try cast(getChild("title"), GTextField)
        catch (e:Dynamic) null;
        _barObjectH = getChild("bar");
        _barObjectV = getChild("bar_v");
        _gripObject = getChild("grip");

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
        if (_gripObject != null)
        {
            _gripObject.addEventListener(GTouchEvent.BEGIN, __gripMouseDown);
            _gripObject.addEventListener(GTouchEvent.DRAG, __gripMouseMove);
        }

        addEventListener(GTouchEvent.BEGIN, __barMouseDown);
    }

    override private function handleSizeChanged():Void
    {
        super.handleSizeChanged();

        if (_barObjectH != null)
            _barMaxWidth = Std.int(this.width - _barMaxWidthDelta);
        if (_barObjectV != null)
            _barMaxHeight = Std.int(this.height - _barMaxHeightDelta);
        if (!this._underConstruct)
            update();
    }

    override public function setup_afterAdd(xml:FastXML):Void
    {
        super.setup_afterAdd(xml);

        xml = xml.nodes.Slider.get(0);
        if (xml != null)
        {
            _value = Std.parseInt(xml.att.value);
            _max = Std.parseInt(xml.att.max);
        }

        update();
    }

    private function __gripMouseDown(evt:GTouchEvent):Void
    {
        this.canDrag = true;

        evt.stopPropagation();

        _clickPos = this.globalToLocal(evt.stageX, evt.stageY);
        _clickPercent = _value / _max;
    }

    private function __gripMouseMove(evt:GTouchEvent):Void
    {
        if (!this.canDrag)
        {
            return;
        }

        var pt:Point = this.globalToLocal(evt.stageX, evt.stageY);
        var deltaX:Int = Std.int(pt.x - _clickPos.x);
        var deltaY:Int = Std.int(pt.y - _clickPos.y);
        if (_reverse)
        {
            deltaX = -deltaX;
            deltaY = -deltaY;
        }

        var percent:Float;
        if (_barObjectH != null)
            percent = _clickPercent + deltaX / _barMaxWidth;
        else
            percent = _clickPercent + deltaY / _barMaxHeight;

        if (percent > 1)
            percent = 1;
        else if (percent < 0)
            percent = 0;

        var newValue:Int = Math.round(_max * percent);
        if (newValue != _value)
        {
            _value = newValue;
            dispatchEvent(new StateChangeEvent(StateChangeEvent.CHANGED));
        }
        updateWidthPercent(percent);
    }

    private function __barMouseDown(evt:GTouchEvent):Void
    {
        if (!changeOnClick)
            return;

        var pt:Point = _gripObject.globalToLocal(evt.stageX, evt.stageY);
        var percent:Float = _value / _max;
        var delta:Float = 0;
        if (_barObjectH != null)
            delta = (pt.x - _gripObject.width / 2) / _barMaxWidth;
        if (_barObjectV != null)
            delta = (pt.y - _gripObject.height / 2) / _barMaxHeight;

        if (_reverse)
            percent -= delta;
        else
            percent += delta;

        if (percent > 1)
            percent = 1;
        else if (percent < 0)
            percent = 0;
        var newValue:Int = Math.round(_max * percent);
        if (newValue != _value)
        {
            _value = newValue;
            dispatchEvent(new StateChangeEvent(StateChangeEvent.CHANGED));
        }
        updateWidthPercent(percent);
    }
}


