package fairygui.event;


import openfl.events.Event;

class DragEvent extends Event
{
    public var stageX : Float;
    public var stageY : Float;
    public var touchPointID : Int;
    
    public static inline var DRAG_START : String = "startDrag";
    public static inline var DRAG_END : String = "endDrag";
    public static inline var DRAG_MOVING : String = "dragMoving";
    
    public function new(type : String, stageX : Float = 0, stageY : Float = 0, touchPointID : Int = -1)
    {
        super(type, false, true);
        
        this.stageX = stageX;
        this.stageY = stageY;
        this.touchPointID = touchPointID;
    }
    
    override public function clone() : Event{
        return new DragEvent(type, stageX, stageY, touchPointID);
    }
}
