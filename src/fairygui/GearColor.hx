package fairygui;

import fairygui.GObject;
import fairygui.ITextColorGear;
import fairygui.IColorGear;

import fairygui.utils.ToolSet;

class GearColor extends GearBase
{
    private var _storage : Map<String, GearColorValue>;
    private var _default : GearColorValue;
    
    public function new(owner : GObject)
    {
        super(owner);
    }
    
    override private function init() : Void
    {
        if(Std.is(_owner, ITextColorGear))
            _default = new GearColorValue(cast(_owner, IColorGear).color, cast(_owner, ITextColorGear).strokeColor);
        else
            _default = new GearColorValue(cast(_owner, IColorGear).color);
        _storage = new Map<String, GearColorValue>();
    }
    
    override private function addStatus(pageId : String, value : String) : Void
    {
        if (value == "-") 
            return;

        var pos:Int = value.indexOf(",");
        var col1:UInt;
        var col2:UInt;
        if(pos==-1)
        {
            col1 = ToolSet.convertFromHtmlColor(value);
            col2 = 0xFF000000; //为兼容旧版本，用这个值表示不设置
        }
        else
        {
            col1 = ToolSet.convertFromHtmlColor(value.substr(0,pos));
            col2 = ToolSet.convertFromHtmlColor(value.substr(pos+1));
        }
        if(pageId==null)
        {
            _default.color = col1;
            _default.strokeColor = col2;
        }
        else
            _storage[pageId] = new GearColorValue(col1, col2);
    }
    
    override public function apply() : Void
    {
        _owner._gearLocked = true;

        var gv:GearColorValue = _storage[_controller.selectedPageId];
        if(gv == null)
            gv = _default;

        cast(_owner, IColorGear).color = gv.color;
        if(Std.is(_owner, ITextColorGear) && gv.strokeColor!=0xFF000000)
            cast(_owner, ITextColorGear).strokeColor = gv.strokeColor;
        
        _owner._gearLocked = false;
    }
    
    override public function updateState() : Void
    {
        var gv:GearColorValue = _storage[_controller.selectedPageId];
        if(gv == null)
        {
            gv = new GearColorValue();
            _storage[_controller.selectedPageId] = gv;
        }

        gv.color = cast(_owner, IColorGear).color;
        if(Std.is(_owner, ITextColorGear))
        gv.strokeColor = cast(_owner, ITextColorGear).strokeColor;
    }
}

class GearColorValue
{
    public var color:UInt;
    public var strokeColor:UInt;

    public function new(color:UInt=0, strokeColor:UInt=0)
    {
        this.color = color;
        this.strokeColor = strokeColor;
    }
}