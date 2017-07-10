package fairygui;

import fairygui.GObject;
import fairygui.utils.CompatUtil;

class GGroup extends GObject
{
    @:allow(fairygui)
    private var _updating:Bool = false;
    private var _empty:Bool = false;

    public function new()
    {
        super();
    }

    public function updateBounds():Void
    {
        if (_updating || parent == null)
            return;

        var cnt:Int = _parent.numChildren;
        var i:Int;
        var child:GObject;
        var ax:Int = CompatUtil.INT_MAX_VALUE;
        var ay:Int = CompatUtil.INT_MAX_VALUE;
        var ar:Int = CompatUtil.INT_MIN_VALUE;
        var ab:Int = CompatUtil.INT_MIN_VALUE;
        var tmp:Int;
        _empty = true;
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
                _empty = false;
            }
        }

        _updating = true;
        if (!_empty)
        {
            setXY(ax, ay);
            setSize(ar - ax, ab - ay);
        }
        else
            setSize(0, 0);
        _updating = false;
    }

    @:allow(fairygui)
    private function moveChildren(dx:Float, dy:Float):Void
    {
        if (_updating || parent == null)
            return;

        _updating = true;
        var cnt:Int = _parent.numChildren;
        var i:Int;
        var child:GObject;
        for (i in 0...cnt)
        {
            child = _parent.getChildAt(i);
            if (child.group == this)
            {
                child.setXY(child.x + dx, child.y + dy);
            }
        }
        _updating = false;
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
}
