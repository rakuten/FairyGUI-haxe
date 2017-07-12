package fairygui;

import fairygui.GObject;
import fairygui.utils.CompatUtil;
import fairygui.utils.GTimers;

class GGroup extends GObject
{
    public var layout(get, set):Int;
    public var lineGap(get, set):Int;
    public var columnGap(get, set):Int;


    private var _percentReady:Bool = false;
    private var _boundsChanged:Bool = false;

    @:allow(fairygui)
    private var _updating:Int = 0;

    private var _layout:Int;

    public function get_layout():Int
    {
        return _layout;
    }

    public function set_layout(value:Int):Int
    {
        if (_layout != value)
        {
            _layout = value;
            setBoundsChangedFlag(true);
        }
        return value;
    }

    private var _lineGap:Int;

    public function get_lineGap():Int
    {
        return _lineGap;
    }

    public function set_lineGap(value:Int):Int
    {
        if (_lineGap != value)
        {
            _lineGap = value;
            setBoundsChangedFlag();
        }
        return value;
    }

    private var _columnGap:Int = 0;

    public function get_columnGap():Int
    {
        return _columnGap;
    }

    public function set_columnGap(value:Int):Int
    {
        if (_columnGap != value)
        {
            _columnGap = value;
            setBoundsChangedFlag();
        }
        return value;
    }

    public function setBoundsChangedFlag(childSizeChanged:Bool = false):Void
    {
        if (_updating == 0 && parent != null && !_underConstruct)
        {
            if (childSizeChanged)
                _percentReady = false;

            if (!_boundsChanged)
            {
                _boundsChanged = true;
                if (_layout != GroupLayoutType.None)
                    GTimers.inst.callLater(ensureBoundsCorrect);
            }
        }
    }

    public function ensureBoundsCorrect():Void
    {
        if (_boundsChanged)
            updateBounds();
    }

    public function new()
    {
        super();
    }

    public function updateBounds():Void
    {
        GTimers.inst.remove(ensureBoundsCorrect);
        _boundsChanged = false;

        if (parent == null)
            return;

        handleLayout();

        var cnt:Int = _parent.numChildren;
        var i:Int;
        var child:GObject;
        var ax:Int = CompatUtil.INT_MAX_VALUE;
        var ay:Int = CompatUtil.INT_MAX_VALUE;
        var ar:Int = CompatUtil.INT_MIN_VALUE;
        var ab:Int = CompatUtil.INT_MIN_VALUE;
        var tmp:Int;
        var empty:Bool = true;

        for (i in 0...cnt)
        {
            child = _parent.getChildAt(i);
            if (child.group == this)
            {
                tmp = Std.int(child.x);
                if (tmp < ax)
                    ax = tmp;
                tmp = Std.int(child.y);
                if (tmp < ay)
                    ay = tmp;
                tmp = Std.int(child.x + child.width);
                if (tmp > ar)
                    ar = tmp;
                tmp = Std.int(child.y + child.height);
                if (tmp > ab)
                    ab = tmp;
                empty = false;
            }
        }

        if (!empty)
        {
            _updating = 1;
            setXY(ax, ay);
            _updating = 2;
            setSize(ar - ax, ab - ay);
        }
        else
        {
            _updating = 2;
            setSize(0, 0);
        }

        _updating = 0;
    }

    private function handleLayout():Void
    {
        _updating |= 1;

        var child:GObject;
        var i:Int;
        var cnt:Int;

        if (_layout == GroupLayoutType.Horizontal)
        {
            var curX:Float;
            cnt = parent.numChildren;
            for (i in 0...cnt)
            {
                child = parent.getChildAt(i);
                if (child.group != this)
                    continue;

                if (Math.isNaN(curX))
                    curX = Std.int(child.x);
                else
                    child.x = curX;
                if (child.width != 0)
                    curX += Std.int(child.width + _columnGap);
            }
            if (!_percentReady)
                updatePercent();
        }
        else if (_layout == GroupLayoutType.Vertical)
        {
            var curY:Float;
            cnt = parent.numChildren;
            for (i in 0...cnt)
            {
                child = parent.getChildAt(i);
                if (child.group != this)
                    continue;

                if (Math.isNaN(curY))
                    curY = Std.int(child.y);
                else
                    child.y = curY;
                if (child.height != 0)
                    curY += Std.int(child.height + _lineGap);
            }
            if (!_percentReady)
                updatePercent();
        }

        _updating &= 2;
    }

    private function updatePercent():Void
    {
        _percentReady = true;

        var cnt:Int = parent.numChildren;
        var i:Int;
        var child:GObject;
        var size:Float = 0;
        if (_layout == GroupLayoutType.Horizontal)
        {
            for (i in 0...cnt)
            {
                child = parent.getChildAt(i);
                if (child.group != this)
                    continue;

                size += child.width;
            }

            for (i in 0...cnt)
            {
                child = parent.getChildAt(i);
                if (child.group != this)
                    continue;

                if (size > 0)
                    child._sizePercentInGroup = child.width / size;
                else
                    child._sizePercentInGroup = 0;
            }
        }
        else
        {
            for (i in 0...cnt)
            {
                child = parent.getChildAt(i);
                if (child.group != this)
                    continue;

                size += child.height;
            }

            for (i in 0...cnt)
            {
                child = parent.getChildAt(i);
                if (child.group != this)
                    continue;

                if (size > 0)
                    child._sizePercentInGroup = child.height / size;
                else
                    child._sizePercentInGroup = 0;
            }
        }
    }

    @:allow(fairygui)
    private function moveChildren(dx:Float, dy:Float):Void
    {
        if ((_updating & 1) != 0 || parent == null)
            return;

        _updating |= 1;

        var cnt:Int = parent.numChildren;
        var child:GObject;
        for (i in 0...cnt)
        {
            child = parent.getChildAt(i);
            if (child.group == this)
            {
                child.setXY(child.x + dx, child.y + dy);
            }
        }

        _updating &= 2;
    }

    @:allow(fairygui)
    private function resizeChildren(dw:Float, dh:Float):Void
    {
        if (_layout == GroupLayoutType.None || (_updating & 2) != 0 || parent == null)
            return;

        _updating |= 2;

        if (!_percentReady)
            updatePercent();

        var cnt:Int = parent.numChildren;
        var i:Int;
        var j:Int;
        var child:GObject;
        var last:Int = -1;
        var numChildren:Int = 0;
        var lineSize:Float = 0;
        var remainSize:Float = 0;
        var found:Bool = false;

        for (i in 0...cnt)
        {
            child = parent.getChildAt(i);
            if (child.group != this)
                continue;

            last = i;
            numChildren++;
        }

        if (_layout == GroupLayoutType.Horizontal)
        {
            remainSize = lineSize = this.width - (numChildren - 1) * _columnGap;
            var curX:Float;
            var nw:Float;
            for (i in 0...cnt)
            {
                child = parent.getChildAt(i);
                if (child.group != this)
                    continue;

                if (Math.isNaN(curX))
                    curX = Std.int(child.x);
                else
                    child.x = curX;
                if (last == i)
                    nw = remainSize;
                else
                    nw = Math.round(child._sizePercentInGroup * lineSize);
                child.setSize(nw, child._rawHeight + dh, true);
                remainSize -= child.width;
                if (last == i)
                {
                    if (remainSize >= 1) //可能由于有些元件有宽度限制，导致无法铺满
                    {
                        for (j in 0...i+1)
                        {
                            child = parent.getChildAt(j);
                            if (child.group != this)
                                continue;

                            if (!found)
                            {
                                nw = child.width + remainSize;
                                if ((child.maxWidth == 0 || nw < child.maxWidth)
                                && (child.minWidth == 0 || nw > child.minWidth))
                                {
                                    child.setSize(nw, child.height, true);
                                    found = true;
                                }
                            }
                            else
                                child.x += remainSize;
                        }
                    }
                }
                else
                    curX += (child.width + _columnGap);
            }
        }
        else if (_layout == GroupLayoutType.Vertical)
        {
            remainSize = lineSize = this.height - (numChildren - 1) * _lineGap;
            var curY:Float;
            var nh:Float;
            for (i in 0...cnt)
            {
                child = parent.getChildAt(i);
                if (child.group != this)
                    continue;

                if (Math.isNaN(curY))
                    curY = Std.int(child.y);
                else
                    child.y = curY;
                if (last == i)
                    nh = remainSize;
                else
                    nh = Math.round(child._sizePercentInGroup * lineSize);
                child.setSize(child._rawWidth + dw, nh, true);
                remainSize -= child.height;
                if (last == i)
                {
                    if (remainSize >= 1) //可能由于有些元件有宽度限制，导致无法铺满
                    {
                        for (j in 0...i+1)
                        {
                            child = parent.getChildAt(j);
                            if (child.group != this)
                                continue;

                            if (!found)
                            {
                                nh = child.height + remainSize;
                                if ((child.maxHeight == 0 || nh < child.maxHeight)
                                && (child.minHeight == 0 || nh > child.minHeight))
                                {
                                    child.setSize(child.width, nh, true);
                                    found = true;
                                }
                            }
                            else
                            child.y += remainSize;
                        }
                    }
                }
                else
                    curY += (child.height + _lineGap);
            }
        }

        _updating &= 1;
    }

    override private function updateAlpha():Void
    {
        super.updateAlpha();

        if (this._underConstruct)
            return;

        var cnt:Int = _parent.numChildren;
        for (i in 0...cnt)
        {
            var child:GObject = _parent.getChildAt(i);
            if (child.group == this)
                child.alpha = this.alpha;
        }
    }

    override public function setup_beforeAdd(xml:FastXML):Void
    {
        super.setup_beforeAdd(xml);

        var str:String;

        str = xml.att.layout;
        if (str != null)
        {
            _layout = GroupLayoutType.parse(str);
            str = xml.att.lineGap;
            if (str != null)
                _lineGap = Std.parseInt(str);
            str = xml.att.colGap;
            if (str != null)
                _columnGap = Std.parseInt(str);
        }
    }
}
