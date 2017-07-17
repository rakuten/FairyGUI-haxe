package fairygui;

import fairygui.GObject;


class GearDisplay extends GearBase
{
    public var pages:Array<String>;

    private var _visible:Int = 0;

    public var connected(get, never):Bool;

    public function new(owner:GObject)
    {
        super(owner);
        _displayLockToken = 1;
    }

    override private function init():Void
    {
        pages = null;
    }

    public function addLock():UInt
    {
        _visible++;
        return _displayLockToken;
    }

    public function releaseLock(token:UInt):Void
    {
        if (token == _displayLockToken)
            _visible--;
    }

    private function get_connected():Bool
    {
        return _controller == null || _visible > 0;
    }

    override public function apply():Void
    {
        _displayLockToken++;
        if (_displayLockToken == 0)
            _displayLockToken = 1;

        if (pages == null || pages.length == 0 || pages.indexOf(_controller.selectedPageId) != -1)
            _visible = 1;
        else
            _visible = 0;
    }
}
