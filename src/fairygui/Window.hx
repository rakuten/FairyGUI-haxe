package fairygui;


import fairygui.event.DragEvent;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;

class Window extends GComponent
{
    public var contentPane(get, set):GComponent;
    public var frame(get, never):GComponent;
    public var closeButton(get, set):GObject;
    public var dragArea(get, set):GObject;
    public var contentArea(get, set):GObject;
    public var isShowing(get, never):Bool;
    public var isTop(get, never):Bool;
    public var modal(get, set):Bool;
    public var modalWaiting(get, never):Bool;

    private var _contentPane:GComponent;
    private var _modalWaitPane:GObject;
    private var _closeButton:GObject;
    private var _dragArea:GObject;
    private var _contentArea:GObject;
    private var _frame:GComponent;
    private var _modal:Bool = false;

    private var _uiSources:Array<IUISource>;
    private var _inited:Bool = false;
    private var _loading:Bool = false;

    private var _requestingCmd:Int = 0;

    public var bringToFontOnClick:Bool = false;

    public function new()
    {
        super();
        this.focusable = true;
        _uiSources = new Array<IUISource>();
        bringToFontOnClick = UIConfig.bringWindowToFrontOnClick;

        displayObject.addEventListener(Event.ADDED_TO_STAGE, __onShown);
        displayObject.addEventListener(Event.REMOVED_FROM_STAGE, __onHidden);
        displayObject.addEventListener(MouseEvent.MOUSE_DOWN, __mouseDown, true);
    }

    public function addUISource(source:IUISource):Void
    {
        _uiSources.push(source);
    }

    private function set_contentPane(val:GComponent):GComponent
    {
        if (_contentPane != val)
        {
            if (_contentPane != null)
                removeChild(_contentPane);
            _contentPane = val;
            if (_contentPane != null)
            {
                addChild(_contentPane);
                this.setSize(_contentPane.width, _contentPane.height);
                _contentPane.addRelation(this, RelationType.Size);
                _frame = try cast(_contentPane.getChild("frame"), GComponent)catch (e:Dynamic) null;
                if (_frame != null)
                {
                    this.closeButton = _frame.getChild("closeButton");
                    this.dragArea = _frame.getChild("dragArea");
                    this.contentArea = _frame.getChild("contentArea");
                }
            }
        }
        return val;
    }

    private function get_contentPane():GComponent
    {
        return _contentPane;
    }

    private function get_frame():GComponent
    {
        return _frame;
    }

    private function get_closeButton():GObject
    {
        return _closeButton;
    }

    private function set_closeButton(value:GObject):GObject
    {
        if (_closeButton != null)
            _closeButton.removeClickListener(closeEventHandler);
        _closeButton = value;
        if (_closeButton != null)
            _closeButton.addClickListener(closeEventHandler);
        return value;
    }

    private function get_dragArea():GObject
    {
        return _dragArea;
    }

    private function set_dragArea(value:GObject):GObject
    {
        if (_dragArea != value)
        {
            if (_dragArea != null)
            {
                _dragArea.draggable = false;
                _dragArea.removeEventListener(DragEvent.DRAG_START, __dragStart);
            }

            _dragArea = value;
            if (_dragArea != null)
            {
                if ((Std.is(_dragArea, GGraph)) && cast((_dragArea), GGraph).displayObject == null)
                    _dragArea.asGraph.drawRect(0, 0, 0, 0, 0);
                _dragArea.draggable = true;
                _dragArea.addEventListener(DragEvent.DRAG_START, __dragStart);
            }
        }
        return value;
    }

    private function get_contentArea():GObject
    {
        return _contentArea;
    }

    private function set_contentArea(value:GObject):GObject
    {
        _contentArea = value;
        return value;
    }

    public function show():Void
    {
        GRoot.inst.showWindow(this);
    }

    public function showOn(root:GRoot):Void
    {
        root.showWindow(this);
    }

    public function hide():Void
    {
        if (this.isShowing)
            doHideAnimation();
    }

    public function hideImmediately():Void
    {
        var r:GRoot = Std.is(parent, GRoot) ? cast(parent, GRoot) : null;
        if (r == null)
            r = GRoot.inst;
        r.hideWindowImmediately(this);
    }

    public function centerOn(r:GRoot, restraint:Bool = false):Void
    {
        this.setXY(Std.int((r.width - this.width) / 2), Std.int((r.height - this.height) / 2));
        if (restraint)
        {
            this.addRelation(r, RelationType.Center_Center);
            this.addRelation(r, RelationType.Middle_Middle);
        }
    }

    public function toggleStatus():Void
    {
        if (isTop)
            hide();
        else
            show();
    }

    private function get_isShowing():Bool
    {
        return parent != null;
    }

    private function get_isTop():Bool
    {
        return parent != null && parent.getChildIndex(this) == parent.numChildren - 1;
    }

    private function get_modal():Bool
    {
        return _modal;
    }

    private function set_modal(val:Bool):Bool
    {
        _modal = val;
        return val;
    }

    public function bringToFront():Void
    {
        this.root.bringToFront(this);
    }

    public function showModalWait(requestingCmd:Int = 0):Void
    {
        if (requestingCmd != 0)
            _requestingCmd = requestingCmd;

        if (UIConfig.windowModalWaiting != null)
        {
            if (_modalWaitPane == null)
                _modalWaitPane = UIPackage.createObjectFromURL(UIConfig.windowModalWaiting);

            layoutModalWaitPane();

            addChild(_modalWaitPane);
        }
    }

    private function layoutModalWaitPane():Void
    {
        if (_contentArea != null)
        {
            var pt:Point = _frame.localToGlobal();
            pt = this.globalToLocal(pt.x, pt.y);
            _modalWaitPane.setXY(pt.x + _contentArea.x, pt.y + _contentArea.y);
            _modalWaitPane.setSize(_contentArea.width, _contentArea.height);
        }
        else
            _modalWaitPane.setSize(this.width, this.height);
    }

    public function closeModalWait(requestingCmd:Int = 0):Bool
    {
        if (requestingCmd != 0)
        {
            if (_requestingCmd != requestingCmd)
                return false;
        }
        _requestingCmd = 0;

        if (_modalWaitPane != null && _modalWaitPane.parent != null)
            removeChild(_modalWaitPane);

        return true;
    }

    private function get_modalWaiting():Bool
    {
        return (_modalWaitPane != null && _modalWaitPane.parent != null);
    }

    public function init():Void
    {
        if (_inited || _loading)
            return;

        if (_uiSources.length > 0)
        {
            _loading = false;
            var cnt:Int = _uiSources.length;
            for (i in 0...cnt)
            {
                var lib:IUISource = _uiSources[i];
                if (!lib.loaded)
                {
                    lib.load(__uiLoadComplete);
                    _loading = true;
                }
            }

            if (!_loading)
                _init();
        }
        else
            _init();
    }

    private function onInit():Void
    {
    }

    private function onShown():Void
    {
    }

    private function onHide():Void
    {
    }

    private function doShowAnimation():Void
    {
        onShown();
    }

    private function doHideAnimation():Void
    {
        this.hideImmediately();
    }

    private function __uiLoadComplete():Void
    {
        var cnt:Int = _uiSources.length;
        for (i in 0...cnt)
        {
            var lib:IUISource = _uiSources[i];
            if (!lib.loaded)
                return;
        }

        _loading = false;
        _init();
    }

    private function _init():Void
    {
        _inited = true;
        onInit();

        if (this.isShowing)
            doShowAnimation();
    }

    override public function dispose():Void
    {
        displayObject.removeEventListener(Event.ADDED_TO_STAGE, __onShown);
        displayObject.removeEventListener(Event.REMOVED_FROM_STAGE, __onHidden);
        if (parent != null)
            this.hideImmediately();

        super.dispose();
    }

    private function closeEventHandler(evt:Event):Void
    {
        hide();
    }

    private function __onShown(evt:Event):Void
    {
        if (evt.target == displayObject)
        {
            if (!_inited)
                init();
            else
                doShowAnimation();
        }
    }

    private function __onHidden(evt:Event):Void
    {
        if (evt.target == displayObject)
        {
            closeModalWait();
            onHide();
        }
    }

    private function __mouseDown(evt:Event):Void
    {
        if (this.isShowing && bringToFontOnClick)
        {
            bringToFront();
        }
    }

    private function __dragStart(evt:DragEvent):Void
    {
        evt.preventDefault();

        this.startDrag(evt.touchPointID);
    }
}

