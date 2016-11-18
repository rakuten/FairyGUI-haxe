package fairygui;

import fairygui.GObject;


class GearDisplay extends GearBase
{
    public var pages : Array<String>;
    
    public function new(owner : GObject)
    {
        super(owner);
    }
    
    override private function init() : Void
    {
        pages = null;
    }
    
    override public function apply() : Void
    {
        if (_controller == null || pages == null || pages.length == 0 || Lambda.indexOf(pages, _controller.selectedPageId) != -1) 
            _owner.internalVisible++
        else 
        _owner.internalVisible = 0;
    }
}
