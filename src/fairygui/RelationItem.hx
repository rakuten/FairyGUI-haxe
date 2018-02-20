package fairygui;

class RelationItem
{
    public var owner(get, never):GObject;
    public var target(get, set):GObject;
    public var isEmpty(get, never):Bool;

    private var _owner:GObject;
    private var _target:GObject;
    private var _defs:Array<RelationDef>;
    private var _targetX:Float = 0;
    private var _targetY:Float = 0;
    private var _targetWidth:Float = 0;
    private var _targetHeight:Float = 0;

    @:allow(fairygui)
    private function new(owner:GObject)
    {
        _owner = owner;
        _defs = new Array<RelationDef>();
    }

    @:final private function get_owner():GObject
    {
        return _owner;
    }

    private function set_target(value:GObject):GObject
    {
        if (_target != value)
        {
            if (_target != null)
                releaseRefTarget(_target);
            _target = value;
            if (_target != null)
                addRefTarget(_target);
        }
        return value;
    }

    @:final private function get_target():GObject
    {
        return _target;
    }

    public function add(relationType:Int, usePercent:Bool):Void
    {
        if (relationType == RelationType.Size)
        {
            add(RelationType.Width, usePercent);
            add(RelationType.Height, usePercent);
            return;
        }

        for (def in _defs)
        {
            if (def.type == relationType)
                return;
        }

        internalAdd(relationType, usePercent);
    }

    public function internalAdd(relationType:Int, usePercent:Bool):Void
    {
        if (relationType == RelationType.Size)
        {
            internalAdd(RelationType.Width, usePercent);
            internalAdd(RelationType.Height, usePercent);
            return;
        }

        var info:RelationDef = new RelationDef();
        info.percent = usePercent;
        info.type = relationType;
        _defs.push(info);

        //当使用中线关联时，因为需要除以2，很容易因为奇数宽度/高度造成小数点坐标；当使用百分比时，也会造成小数坐标；
        //所以设置了这类关联的对象，自动启用pixelSnapping
        if (usePercent ||
            relationType == RelationType.Left_Center ||
            relationType == RelationType.Center_Center ||
            relationType == RelationType.Right_Center ||
            relationType == RelationType.Top_Middle ||
            relationType == RelationType.Middle_Middle ||
            relationType == RelationType.Bottom_Middle)
            _owner.pixelSnapping = true;
    }

    public function remove(relationType:Int):Void
    {
        if (relationType == RelationType.Size)
        {
            remove(RelationType.Width);
            remove(RelationType.Height);
            return;
        }

        var dc:Int = _defs.length;
        for (k in 0...dc)
        {
            if (_defs[k].type == relationType)
            {
                _defs.splice(k, 1);
                break;
            }
        }
    }

    public function copyFrom(source:RelationItem):Void
    {
        this.target = source.target;

        _defs.splice(0, _defs.length);
        for (info in source._defs.iterator())
        {
            var info2:RelationDef = new RelationDef();
            info2.copyFrom(info);
            _defs.push(info2);
        }
    }

    public function dispose():Void
    {
        if (_target != null)
        {
            releaseRefTarget(_target);
            _target = null;
        }
    }

    @:final private function get_isEmpty():Bool
    {
        return _defs.length == 0;
    }

    public function applyOnSelfResized(dWidth:Float, dHeight:Float):Void
    {
        var ox:Float = _owner.x;
        var oy:Float = _owner.y;
        for (info in _defs)
        {
            switch (info.type)
            {
                case RelationType.Center_Center, RelationType.Right_Center:
                    _owner.x -= dWidth / 2;
                case RelationType.Right_Left, RelationType.Right_Right:
                    _owner.x -= dWidth;
                case RelationType.Middle_Middle, RelationType.Bottom_Middle:
                    _owner.y -= dHeight / 2;
                case RelationType.Bottom_Top, RelationType.Bottom_Bottom:
                    _owner.y -= dHeight;
            }
        }

        if (ox != _owner.x || oy != _owner.y)
        {
            ox = _owner.x - ox;
            oy = _owner.y - oy;

            _owner.updateGearFromRelations(1, ox, oy);

            if (_owner.parent != null && _owner.parent._transitions.length > 0)
            {
                for (trans in _owner.parent._transitions.iterator())
                {
                    trans.updateFromRelations(_owner.id, ox, oy);
                }
            }
        }
    }

    private function applyOnXYChanged(info:RelationDef, dx:Float, dy:Float):Void
    {
        switch (info.type)
        {
            case RelationType.Left_Left, RelationType.Left_Center, RelationType.Left_Right, RelationType.Center_Center, RelationType.Right_Left, RelationType.Right_Center, RelationType.Right_Right:
                _owner.x += dx;
            case RelationType.Top_Top, RelationType.Top_Middle, RelationType.Top_Bottom, RelationType.Middle_Middle, RelationType.Bottom_Top, RelationType.Bottom_Middle, RelationType.Bottom_Bottom:
                _owner.y += dy;
            case RelationType.Width, RelationType.Height:

            case RelationType.LeftExt_Left, RelationType.LeftExt_Right:
                _owner.x += dx;
                _owner.width = _owner._rawWidth - dx;
            case RelationType.RightExt_Left, RelationType.RightExt_Right:
                _owner.width = _owner._rawWidth + dx;
            case RelationType.TopExt_Top, RelationType.TopExt_Bottom:
                _owner.y += dy;
                _owner.height = _owner._rawHeight - dy;
            case RelationType.BottomExt_Top, RelationType.BottomExt_Bottom:
                _owner.height = _owner._rawHeight + dy;
        }
    }

    private function applyOnSizeChanged(info:RelationDef):Void
    {
        var targetX:Float;
        var targetY:Float;
        if (_target != _owner.parent)
        {
            targetX = _target.x;
            targetY = _target.y;
        }
        else
        {
            targetX = 0;
            targetY = 0;
        }
        var v:Float;
        var tmp:Float;

        switch (info.type)
        {
            case RelationType.Left_Left:
                if (info.percent && _target == _owner.parent)
                {
                    v = _owner.x - targetX;
                    v = v / _targetWidth * _target._width;
                    _owner.x = targetX + v;
                }
            case RelationType.Left_Center:
                v = _owner.x - (targetX + _targetWidth / 2);
                if (info.percent)
                    v = v / _targetWidth * _target._width;
                _owner.x = targetX + _target._width / 2 + v;
            case RelationType.Left_Right:
                v = _owner.x - (targetX + _targetWidth);
                if (info.percent)
                    v = v / _targetWidth * _target._width;
                _owner.x = targetX + _target._width + v;
            case RelationType.Center_Center:
                v = _owner.x + _owner._rawWidth / 2 - (targetX + _targetWidth / 2);
                if (info.percent)
                    v = v / _targetWidth * _target._width;
                _owner.x = targetX + _target._width / 2 + v - _owner._rawWidth / 2;
            case RelationType.Right_Left:
                v = _owner.x + _owner._rawWidth - targetX;
                if (info.percent)
                    v = v / _targetWidth * _target._width;
                _owner.x = targetX + v - _owner._rawWidth;
            case RelationType.Right_Center:
                v = _owner.x + _owner._rawWidth - (targetX + _targetWidth / 2);
                if (info.percent)
                    v = v / _targetWidth * _target._width;
                _owner.x = targetX + _target._width / 2 + v - _owner._rawWidth;
            case RelationType.Right_Right:
                v = _owner.x + _owner._rawWidth - (targetX + _targetWidth);
                if (info.percent)
                    v = v / _targetWidth * _target._width;
                _owner.x = targetX + _target._width + v - _owner._rawWidth;

            case RelationType.Top_Top:
                if (info.percent && _target == _owner.parent)
                {
                    v = _owner.y - targetY;
                    v = v / _targetHeight * _target._height;
                    _owner.y = targetY + v;
                }
            case RelationType.Top_Middle:
                v = _owner.y - (targetY + _targetHeight / 2);
                if (info.percent)
                    v = v / _targetHeight * _target._height;
                _owner.y = targetY + _target._height / 2 + v;
            case RelationType.Top_Bottom:
                v = _owner.y - (targetY + _targetHeight);
                if (info.percent)
                    v = v / _targetHeight * _target._height;
                _owner.y = targetY + _target._height + v;
            case RelationType.Middle_Middle:
                v = _owner.y + _owner._rawHeight / 2 - (targetY + _targetHeight / 2);
                if (info.percent)
                    v = v / _targetHeight * _target._height;
                _owner.y = targetY + _target._height / 2 + v - _owner._rawHeight / 2;
            case RelationType.Bottom_Top:
                v = _owner.y + _owner._rawHeight - targetY;
                if (info.percent)
                    v = v / _targetHeight * _target._height;
                _owner.y = targetY + v - _owner._rawHeight;
            case RelationType.Bottom_Middle:
                v = _owner.y + _owner._rawHeight - (targetY + _targetHeight / 2);
                if (info.percent)
                    v = v / _targetHeight * _target._height;
                _owner.y = targetY + _target._height / 2 + v - _owner._rawHeight;
            case RelationType.Bottom_Bottom:
                v = _owner.y + _owner._rawHeight - (targetY + _targetHeight);
                if (info.percent)
                    v = v / _targetHeight * _target._height;
                _owner.y = targetY + _target._height + v - _owner._rawHeight;

            case RelationType.Width:
                if (_owner._underConstruct && _owner == _target.parent)
                    v = _owner.sourceWidth - _target.initWidth;
                else
                    v = _owner._rawWidth - _targetWidth;
                if (info.percent)
                    v = v / _targetWidth * _target._width;
                if (_target == _owner.parent)
                    _owner.setSize(_target._width + v, _owner._rawHeight, true);
                else
                    _owner.width = _target._width + v;
            case RelationType.Height:
                if (_owner._underConstruct && _owner == _target.parent)
                    v = _owner.sourceHeight - _target.initHeight;
                else
                    v = _owner._rawHeight - _targetHeight;
                if (info.percent)
                    v = v / _targetHeight * _target._height;
                if (_target == _owner.parent)
                    _owner.setSize(_owner._rawWidth, _target._height + v, true)
                else
                    _owner.height = _target._height + v;

            case RelationType.LeftExt_Left:

            case RelationType.LeftExt_Right:
                v = _owner.x - (targetX + _targetWidth);
                if (info.percent)
                    v = v / _targetWidth * _target._width;
                tmp = _owner.x;
                _owner.x = targetX + _target._width + v;
                _owner.width = _owner._rawWidth - (_owner.x - tmp);
            case RelationType.RightExt_Left:

            case RelationType.RightExt_Right:
                if (_owner._underConstruct && _owner == _target.parent)
                    v = _owner.sourceWidth - (targetX + _target.initWidth);
                else
                    v = _owner._rawWidth - (targetX + _targetWidth);
                if (_owner != _target.parent)
                    v += _owner.x;
                if (info.percent)
                    v = v / _targetWidth * _target._width;
                if (_owner != _target.parent)
                    _owner.width = targetX + _target._width + v - _owner.x;
                else
                    _owner.width = targetX + _target._width + v;
            case RelationType.TopExt_Top:

            case RelationType.TopExt_Bottom:
                v = _owner.y - (targetY + _targetHeight);
                if (info.percent)
                    v = v / _targetHeight * _target._height;
                tmp = _owner.y;
                _owner.y = targetY + _target._height + v;
                _owner.height = _owner._rawHeight - (_owner.y - tmp);
            case RelationType.BottomExt_Top:

            case RelationType.BottomExt_Bottom:
                if (_owner._underConstruct && _owner == _target.parent)
                    v = _owner.sourceHeight - (targetY + _target.initHeight);
                else
                    v = _owner._rawHeight - (targetY + _targetHeight);
                if (_owner != _target.parent)
                    v += _owner.y;
                if (info.percent)
                    v = v / _targetHeight * _target._height;
                if (_owner != _target.parent)
                    _owner.height = targetY + _target._height + v - _owner.y;
                else
                    _owner.height = targetY + _target._height + v;
        }
    }

    private function addRefTarget(target:GObject):Void
    {
        if (target != _owner.parent)
            target.addXYChangeCallback(__targetXYChanged);
        target.addSizeChangeCallback(__targetSizeChanged);
        target.addSizeDelayChangeCallback(__targetSizeWillChange);
        _targetX = _target.x;
        _targetY = _target.y;
        _targetWidth = _target._width;
        _targetHeight = _target._height;
    }

    private function releaseRefTarget(target:GObject):Void
    {
        target.removeXYChangeCallback(__targetXYChanged);
        target.removeSizeChangeCallback(__targetSizeChanged);
        target.removeSizeDelayChangeCallback(__targetSizeWillChange);
    }

    private function __targetXYChanged(target:GObject):Void
    {
        if (_owner.relations.handling != null || _owner.group != null && _owner.group._updating > 0)
        {
            _targetX = _target.x;
            _targetY = _target.y;
            return;
        }

        _owner.relations.handling = target;

        var ox:Float = _owner.x;
        var oy:Float = _owner.y;
        var dx:Float = _target.x - _targetX;
        var dy:Float = _target.y - _targetY;
        for (info in _defs)
        {
            applyOnXYChanged(info, dx, dy);
        }
        _targetX = _target.x;
        _targetY = _target.y;

        if (ox != _owner.x || oy != _owner.y)
        {
            ox = _owner.x - ox;
            oy = _owner.y - oy;

            _owner.updateGearFromRelations(1, ox, oy);

            if (_owner.parent != null && _owner.parent._transitions.length > 0)
            {
                for (trans in _owner.parent._transitions.iterator())
                {
                    trans.updateFromRelations(_owner.id, ox, oy);
                }
            }
        }

        _owner.relations.handling = null;
    }

    private function __targetSizeChanged(target:GObject):Void
    {
        if (_owner.relations.handling != null)
        {
            _targetWidth = _target._width;
            _targetHeight = _target._height;
            return;
        }

        _owner.relations.handling = target;

        var ox:Float = _owner.x;
        var oy:Float = _owner.y;
        var ow:Float = _owner._rawWidth;
        var oh:Float = _owner._rawHeight;
        for (info in _defs)
        {
            applyOnSizeChanged(info);
        }
        _targetWidth = _target._width;
        _targetHeight = _target._height;

        if (ox != _owner.x || oy != _owner.y)
        {
            ox = _owner.x - ox;
            oy = _owner.y - oy;

            _owner.updateGearFromRelations(1, ox, oy);

            if (_owner.parent != null && _owner.parent._transitions.length > 0)
            {
                for (trans in _owner.parent._transitions.iterator())
                {
                    trans.updateFromRelations(_owner.id, ox, oy);
                }
            }
        }

        if (ow != _owner._rawWidth || oh != _owner._rawHeight)
        {
            ow = _owner._rawWidth - ow;
            oh = _owner._rawHeight - oh;

            _owner.updateGearFromRelations(2, ow, oh);
        }

        _owner.relations.handling = null;
    }

    private function __targetSizeWillChange(target:GObject):Void
    {
        _owner.relations.sizeDirty = true;
    }
}


class RelationDef
{
    public var percent:Bool = false;
    public var type:Int = 0;

    public function new()
    {
    }

    public function copyFrom(source:RelationDef):Void
    {
        this.percent = source.percent;
        this.type = source.type;
    }
}
