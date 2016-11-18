package fairygui;

import fairygui.GObject;

import fairygui.utils.ToolSet;

class GearColor extends GearBase
{
    private var _storage : Map<String, Int>;
    private var _default : Int;
    
    public function new(owner : GObject)
    {
        super(owner);
    }
    
    override private function init() : Void
    {
        _default = cast((_owner), IColorGear).color;
        _storage = new Map<String, Int>();
    }
    
    override private function addStatus(pageId : String, value : String) : Void
    {
        if (value == "-") 
            return;
        
        var col : Int = ToolSet.convertFromHtmlColor(value);
        if (pageId == null) 
            _default = col
        else 
        _storage[pageId] = col;
    }
    
    override public function apply() : Void
    {
        _owner._gearLocked = true;
        
        var data : Dynamic = _storage[_controller.selectedPageId];
        if (data != null) 
            cast((_owner), IColorGear).color = Std.parseInt(data)
        else 
        cast((_owner), IColorGear).color = _default;
        
        _owner._gearLocked = false;
    }
    
    override public function updateState() : Void
    {
        if (_controller == null || _owner._gearLocked || _owner._underConstruct) 
            return;
        
        _storage[_controller.selectedPageId] = cast(_owner, IColorGear).color;
    }
}
