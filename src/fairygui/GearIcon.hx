package fairygui;

import fairygui.GObject;


class GearIcon extends GearBase
{
    private var _storage : Map<String, String>;
    private var _default : String;
    
    public function new(owner : GObject)
    {
        super(owner);
    }
    
    override private function init() : Void
    {
        _default = _owner.icon;
        _storage = new Map<String, String>();
    }
    
    override private function addStatus(pageId : String, value : String) : Void
    {
        if (pageId == null) 
            _default = value
        else 
        _storage[pageId] = value;
    }
    
    override public function apply() : Void
    {
        _owner._gearLocked = true;
        
        var data : Dynamic = _storage[_controller.selectedPageId];
        if (data != null) 
            _owner.icon = Std.string(data)
        else 
        _owner.icon = _default;
        
        _owner._gearLocked = false;
    }
    
    override public function updateState() : Void
    {
        _storage[_controller.selectedPageId] = _owner.icon;
    }
}
