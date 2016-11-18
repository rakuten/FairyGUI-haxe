package fairygui.display;


import fairygui.GObject;
import fairygui.text.RichTextField;

class UIRichTextField extends RichTextField implements UIDisplayObject
{
    public var owner(get, never) : GObject;

    private var _owner : GObject;
    
    public function new(owner : GObject)
    {
        super();
        _owner = owner;
    }
    
    private function get_owner() : GObject
    {
        return _owner;
    }
}

