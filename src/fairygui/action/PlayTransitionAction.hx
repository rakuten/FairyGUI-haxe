package fairygui.action;
class PlayTransitionAction extends ControllerAction
{

    public var transitionName:String;
    public var repeat:Int;
    public var delay:Float;
    public var stopOnExit:Bool;

    private var _currentTransition:Transition;

    public function new()
    {
        super();
        repeat = 1;
        delay = 0;
    }

    override private function enter(controller:Controller):Void
    {
        var trans:Transition = controller.parent.getTransition(transitionName);
        if (trans != null)
        {
            if (_currentTransition != null && _currentTransition.playing)
                trans.changeRepeat(repeat);
            else
                trans.play(null, null, repeat, delay);
            _currentTransition = trans;
        }
    }

    override private function leave(controller:Controller):Void
    {
        if (stopOnExit && _currentTransition != null)
        {
            _currentTransition.stop();
            _currentTransition = null;
        }
    }

    override public function setup(xml:FastXML):Void
    {
        super.setup(xml);

        transitionName = xml.att.transition;

        var str:String;

        str = xml.att.repeat;
        if (str != null)
            repeat = Std.parseInt(str);

        str = xml.att.delay;
        if (str != null)
            delay = Std.parseFloat(str);

        str = xml.att.stopOnExit;
        stopOnExit = str == "true";
    }


}
