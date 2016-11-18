package fairygui.event;


import openfl.events.Event;

import fairygui.GObject;

class FocusChangeEvent extends Event
{
    public var oldFocusedObject(get, never) : GObject;
    public var newFocusedObject(get, never) : GObject;

    public static inline var CHANGED : String = "focusChanged";
    
    private var _oldFocusedObject : GObject;
    private var _newFocusedObject : GObject;
    
    public function new(type : String, oldObject : GObject, newObject : GObject)
    {
        super(type, false, false);
        _oldFocusedObject = oldObject;
        _newFocusedObject = newObject;
    }
    
    @:final private function get_oldFocusedObject() : GObject
    {
        return _oldFocusedObject;
    }
    
    @:final private function get_newFocusedObject() : GObject
    {
        return _newFocusedObject;
    }
    
    override public function clone() : Event{
        return new FocusChangeEvent(type, _oldFocusedObject, _newFocusedObject);
    }
}


