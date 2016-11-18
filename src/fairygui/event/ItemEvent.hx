package fairygui.event;


import openfl.events.Event;

import fairygui.GObject;

class ItemEvent extends Event
{
    public var itemObject : GObject;
    public var stageX : Float;
    public var stageY : Float;
    public var clickCount : Int;
    public var rightButton : Bool;
    
    public static inline var CLICK : String = "itemClick";
    
    public function new(type : String, itemObject : GObject = null,
            stageX : Float = 0, stageY : Float = 0, clickCount : Int = 1, rightButton : Bool = false)
    {
        super(type, false, false);
        this.itemObject = itemObject;
        this.stageX = stageX;
        this.stageY = stageY;
        this.clickCount = clickCount;
        this.rightButton = rightButton;
    }
    
    override public function clone() : Event{
        return new ItemEvent(type, itemObject, stageX, stageY, clickCount, rightButton);
    }
}

