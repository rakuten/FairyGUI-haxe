package fairygui;

import fairygui.display.UIDisplayObject;
import fairygui.event.FocusChangeEvent;
import fairygui.utils.ToolSet;
import fairygui.Window;
import openfl.display.DisplayObject;
import openfl.display.Stage;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.events.EventPhase;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.media.Sound;
import openfl.media.SoundTransform;
import openfl.system.Capabilities;
import openfl.system.TouchscreenType;
import openfl.text.TextField;
import openfl.ui.Multitouch;
import openfl.ui.MultitouchInputMode;

@:meta(Event(name = "focusChanged", type = "fairygui.event.FocusChangeEvent"))

class GRoot extends GComponent
{
    public static var inst(get, never):GRoot;
    public var nativeStage(get, never):Stage;
    public var hasModalWindow(get, never):Bool;
    public var modalWaiting(get, never):Bool;
    public var hasAnyPopup(get, never):Bool;
    public var focus(get, set):GObject;
    public var volumeScale(get, set):Float;

    private var _nativeStage:Stage;
    private var _modalLayer:GGraph;
    private var _popupStack:Array<GObject>;
    private var _justClosedPopups:Array<GObject>;
    private var _modalWaitPane:GObject;
    private var _focusedObject:GObject;
    private var _tooltipWin:GObject;
    private var _defaultTooltipWin:GObject;
    private var _hitUI:Bool = false;
    private var _contextMenuDisabled:Bool = false;
    private var _volumeScale:Float;
    private var _designResolutionX:Int = 0;
    private var _designResolutionY:Int = 0;
    private var _screenMatchMode:Int = 0;

    private static var _inst:GRoot;

    public var buttonDown:Bool = false;
    public var ctrlKeyDown:Bool = false;
    public var shiftKeyDown:Bool = false;

    public static var touchScreen:Bool = false;
    public static var touchPointInput:Bool = false;
    public static var eatUIEvents:Bool = false;
    public static var contentScaleFactor:Float = 1;

    private static function get_inst():GRoot
    {
        if (_inst == null)
        {
            new GRoot();
        }
        return _inst;
    }

    public function new()
    {
        super();
        if (_inst == null)
            _inst = this;

        _volumeScale = 1;
        _contextMenuDisabled = Capabilities.playerType == "Desktop";
        _popupStack = new Array<GObject>();
        _justClosedPopups = new Array<GObject>();
        displayObject.addEventListener(Event.ADDED_TO_STAGE, __addedToStage);
    }

    private function get_nativeStage():Stage
    {
        return _nativeStage;
    }

    public function setContentScaleFactor(designResolutionX:Int, designResolutionY:Int,
                                          screenMatchMode:Int = ScreenMatchMode.MatchWidthOrHeight):Void
    {
        _designResolutionX = designResolutionX;
        _designResolutionY = designResolutionY;
        _screenMatchMode = screenMatchMode;

        if (_designResolutionX == 0)
        {
            //backward compability
            _screenMatchMode = ScreenMatchMode.MatchWidth;
        }
        else if (_designResolutionY == 0)
        {
            //backward compability
            _screenMatchMode = ScreenMatchMode.MatchHeight;
        }

        applyScaleFactor();
    }

    private function applyScaleFactor():Void
    {
        var screenWidth:Int = _nativeStage.stageWidth;
        var screenHeight:Int = _nativeStage.stageHeight;

        if (_designResolutionX == 0 || _designResolutionY == 0)
        {
            this.setSize(screenWidth, screenHeight);
            return;
        }

        var dx:Int = _designResolutionX;
        var dy:Int = _designResolutionY;
        if (screenWidth > screenHeight && dx < dy || screenWidth < screenHeight && dx > dy)
        {
            //scale should not change when orientation change
            var tmp:Int = dx;
            dx = dy;
            dy = tmp;
        }

        if (_screenMatchMode == ScreenMatchMode.MatchWidthOrHeight)
        {
            var s1:Float = screenWidth / dx;
            var s2:Float = screenHeight / dy;
            contentScaleFactor = Math.min(s1, s2);
        }
        else if (_screenMatchMode == ScreenMatchMode.MatchWidth)
            contentScaleFactor = screenWidth / dx;
        else
            contentScaleFactor = screenHeight / dy;

        this.setSize(Math.round(screenWidth / contentScaleFactor), Math.round(screenHeight / contentScaleFactor));
        this.scaleX = contentScaleFactor;
        this.scaleY = contentScaleFactor;
    }

    public function setFlashContextMenuDisabled(value:Bool):Void
    {
        _contextMenuDisabled = value;
        if (_nativeStage != null)
        {
            if (_contextMenuDisabled)
            {
                _nativeStage.addEventListener("rightMouseDown" /*MouseEvent.RIGHT_MOUSE_DOWN*/, __stageMouseDownCapture, true);
                _nativeStage.addEventListener("rightMouseUp" /*MouseEvent.RIGHT_MOUSE_UP*/, __stageMouseUpCapture, true);
            }
            else
            {
                _nativeStage.removeEventListener("rightMouseDown" /*MouseEvent.RIGHT_MOUSE_DOWN*/, __stageMouseDownCapture, true);
                _nativeStage.removeEventListener("rightMouseUp" /*MouseEvent.RIGHT_MOUSE_UP*/, __stageMouseUpCapture, true);
            }
        }
    }

    public function showWindow(win:Window):Void
    {
        addChild(win);
        win.requestFocus();

        if (win.x > this.width)
            win.x = this.width - win.width;
        else if (win.x + win.width < 0)
            win.x = 0;

        if (win.y > this.height)
            win.y = this.height - win.height;
        else if (win.y + win.height < 0)
            win.y = 0;

        adjustModalLayer();
    }

    public function hideWindow(win:Window):Void
    {
        win.hide();
    }

    public function hideWindowImmediately(win:Window):Void
    {
        if (win.parent == this)
            removeChild(win);

        adjustModalLayer();
    }

    public function bringToFront(win:Window):Void
    {
        var cnt:Int = this.numChildren;
        var i:Int;
        if (this._modalLayer.parent != null && !win.modal)
            i = this.getChildIndex(this._modalLayer) - 1;
        else
            i = cnt - 1;

        while (i >= 0)
        {
            var g:GObject = this.getChildAt(i);
            if (g == win)
                return;
            if (Std.is(g, Window))
                break;
            i--;
        }

        if (i >= 0)
            this.setChildIndex(win, i);
    }

    public function showModalWait(msg:String = null):Void
    {
        if (UIConfig.globalModalWaiting != null)
        {
            if (_modalWaitPane == null)
                _modalWaitPane = UIPackage.createObjectFromURL(UIConfig.globalModalWaiting);
            _modalWaitPane.setSize(this.width, this.height);
            _modalWaitPane.addRelation(this, RelationType.Size);

            addChild(_modalWaitPane);
            _modalWaitPane.text = msg;
        }
    }

    public function closeModalWait():Void
    {
        if (_modalWaitPane != null && _modalWaitPane.parent != null)
            removeChild(_modalWaitPane);
    }

    public function closeAllExceptModals():Void
    {
        var arr:Array<GObject> = _children.copy();
        var cnt:Int = arr.length;
        for (i in 0...cnt)
        {
            var g:GObject = arr[i];
            if (Std.is(g, Window) && !(try cast(g, Window)catch (e:Dynamic) null).modal)
                cast(g, Window).hide();
        }
    }

    public function closeAllWindows():Void
    {
        var arr:Array<GObject> = _children.copy();
        var cnt:Int = arr.length;
        for (i in 0...cnt)
        {
            var g:GObject = arr[i];
            if (Std.is(g, Window))
                cast(g, Window).hide();
        }
    }

    public function getTopWindow():Window
    {
        var cnt:Int = this.numChildren;
        var i:Int = cnt - 1;
        while (i >= 0)
        {
            var g:GObject = this.getChildAt(i);
            if (Std.is(g, Window))
            {
                return cast((g), Window);
            }
            i--;
        }

        return null;
    }

    public function getWindowBefore(win:Window):Window
    {
        var cnt:Int = this.numChildren;
        var ok:Bool = false;
        var i:Int = cnt - 1;
        while (i >= 0)
        {
            var g:GObject = this.getChildAt(i);
            if (Std.is(g, Window))
            {
                if (ok)
                    return cast(g, Window);

                if (g == win)
                    ok = true;
            }
            i--;
        }

        return null;
    }

    private function get_hasModalWindow():Bool
    {
        return _modalLayer.parent != null;
    }

    private function get_modalWaiting():Bool
    {
        return (_modalWaitPane != null && _modalWaitPane.inContainer);
    }

    public function showPopup(popup:GObject, target:GObject = null, downward:Dynamic = null):Void
    {
        if (_popupStack.length > 0)
        {
            var k:Int = Lambda.indexOf(_popupStack, popup);
            if (k != -1)
            {
                var i:Int = _popupStack.length - 1;
                while (i >= k)
                {
                    closePopup(_popupStack.pop());
                    i--;
                }
            }
        }
        _popupStack.push(popup);

        addChild(popup);
        adjustModalLayer();

        var pos:Point;
        var sizeW:Int = 0;
        var sizeH:Int = 0;
        if (target != null)
        {
            pos = target.localToRoot();
            sizeW = Std.int(target.width);
            sizeH = Std.int(target.height);
        }
        else
        {
            pos = this.globalToLocal(nativeStage.mouseX, nativeStage.mouseY);
        }
        var xx:Float = pos.x;
        var yy:Float = pos.y + sizeH;
        if (xx + popup.width > this.width)
            xx = xx + sizeW - popup.width;

        if ((downward == null && yy + popup.height > this.height)
            || downward == false)
        {
            yy = pos.y - popup.height - 1;
            if (yy < 0)
            {
                yy = 0;
                xx += sizeW / 2;
            }
        }

        popup.setXY(Std.int(xx), Std.int(yy));
    }

    public function togglePopup(popup:GObject, target:GObject = null, downward:Dynamic = null):Void
    {
        if (Lambda.indexOf(_justClosedPopups, popup) != -1)
            return;

        showPopup(popup, target, downward);
    }

    public function hidePopup(popup:GObject = null):Void
    {
        var i:Int;
        if (popup != null)
        {
            var k:Int = Lambda.indexOf(_popupStack, popup);
            if (k != -1)
            {
                i = _popupStack.length - 1;
                while (i >= k)
                {
                    closePopup(_popupStack.pop());
                    i--;
                }
            }
        }
        else
        {
            var cnt:Int = _popupStack.length;
            i = cnt - 1;
            while (i >= 0)
            {
                closePopup(_popupStack[i]);
                i--;
            }
            _popupStack.splice(0, _popupStack.length);
        }
    }

    private function get_hasAnyPopup():Bool
    {
        return _popupStack.length != 0;
    }

    private function closePopup(target:GObject):Void
    {
        if (target.parent != null)
        {
            if (Std.is(target, Window))
                cast(target, Window).hide();
            else
                removeChild(target);
        }
    }

    public function showTooltips(msg:String):Void
    {
        if (_defaultTooltipWin == null)
        {
            var resourceURL:String = UIConfig.tooltipsWin;
            if (resourceURL == null)
            {
                trace("UIConfig.tooltipsWin not defined");
                return;
            }

            _defaultTooltipWin = UIPackage.createObjectFromURL(resourceURL);
        }

        _defaultTooltipWin.text = msg;
        showTooltipsWin(_defaultTooltipWin);
    }

    public function showTooltipsWin(tooltipWin:GObject, position:Point = null):Void
    {
        hideTooltips();

        _tooltipWin = tooltipWin;

        var xx:Int;
        var yy:Int;
        if (position == null)
        {
            xx = Std.int(_nativeStage.mouseX) + 10;
            yy = Std.int(_nativeStage.mouseY) + 20;
        }
        else
        {
            xx = Std.int(position.x);
            yy = Std.int(position.y);
        }
        var pt:Point = this.globalToLocal(xx, yy);
        xx = Std.int(pt.x);
        yy = Std.int(pt.y);

        if (xx + _tooltipWin.width > this.width)
        {
            xx = xx - Std.int(_tooltipWin.width) - 1;
            if (xx < 0)
                xx = 10;
        }
        if (yy + _tooltipWin.height > this.height)
        {
            yy = yy - Std.int(_tooltipWin.height) - 1;
            if (xx - _tooltipWin.width - 1 > 0)
                xx = xx - Std.int(_tooltipWin.width) - 1;
            if (yy < 0)
                yy = 10;
        }

        _tooltipWin.x = xx;
        _tooltipWin.y = yy;
        addChild(_tooltipWin);
    }

    public function hideTooltips():Void
    {
        if (_tooltipWin != null)
        {
            if (_tooltipWin.parent != null)
                removeChild(_tooltipWin);
            _tooltipWin = null;
        }
    }

    public function getObjectUnderMouse():GObject
    {
        return getObjectUnderPoint(_nativeStage.mouseX, _nativeStage.mouseY);
    }

    public function getObjectUnderPoint(globalX:Float, globalY:Float):GObject
    {
        var objs:Array<Dynamic> = _nativeStage.getObjectsUnderPoint(new Point(globalX, globalY));
        if (objs == null || objs.length == 0)
            return null;
        else
            return ToolSet.displayObjectToGObject(objs[objs.length - 1]);
    }

    private function get_focus():GObject
    {
        if (_focusedObject != null && !_focusedObject.onStage)
            _focusedObject = null;

        return _focusedObject;
    }

    private function set_focus(value:GObject):GObject
    {
        if (value != null && (!value.focusable || !value.onStage))
            throw new Error("invalid focus target");

        setFocus(value);
        if (Std.is(value, GTextInput))
            _nativeStage.focus = cast((cast((value), GTextInput).displayObject), TextField);
        return value;
    }

    private function setFocus(value:GObject):Void
    {
        if (_focusedObject != value)
        {
            var old:GObject = null;
            if (_focusedObject != null && _focusedObject.onStage)
                old = _focusedObject;
            _focusedObject = value;
            dispatchEvent(new FocusChangeEvent(FocusChangeEvent.CHANGED, old, value));
        }
    }

    private function get_volumeScale():Float
    {
        return _volumeScale;
    }

    private function set_volumeScale(value:Float):Float
    {
        _volumeScale = value;
        return value;
    }

    public function playOneShotSound(sound:Sound, volumeScale:Float = 1):Void
    {
        var vs:Float = _volumeScale * volumeScale;
        if (vs == 1)
            sound.play();
        else
            sound.play(0, 0, new SoundTransform(vs));
    }

    private function adjustModalLayer():Void
    {
        var cnt:Int = this.numChildren;

        if (_modalWaitPane != null && _modalWaitPane.parent != null)
            setChildIndex(_modalWaitPane, cnt - 1);

        var i:Int = cnt - 1;
        while (i >= 0)
        {
            var g:GObject = this.getChildAt(i);
            if ((Std.is(g, Window)) && (try cast(g, Window)
            catch (e:Dynamic) null).modal)
            {
                if (_modalLayer.parent == null)
                    addChildAt(_modalLayer, i);
                else
                    setChildIndexBefore(_modalLayer, i);
                return;
            }
            i--;
        }

        if (_modalLayer.parent != null)
            removeChild(_modalLayer);
    }

    private function __addedToStage(evt:Event):Void
    {
        displayObject.removeEventListener(Event.ADDED_TO_STAGE, __addedToStage);

        _nativeStage = displayObject.stage;

        var osStr:String = Capabilities.os.toLowerCase().substr(0, 3);
        touchScreen = (osStr == "ios" || osStr == "and" || osStr == "bla" || osStr == "tiz") && Capabilities.touchscreenType != TouchscreenType.NONE;

        if (touchScreen)
        {
            Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
            touchPointInput = true;
        }

        _nativeStage.addEventListener(MouseEvent.MOUSE_DOWN, __stageMouseDownCapture, true);
        _nativeStage.addEventListener(MouseEvent.MOUSE_DOWN, __stageMouseDown, false, 1);
        _nativeStage.addEventListener(MouseEvent.MOUSE_UP, __stageMouseUpCapture, true);
        _nativeStage.addEventListener(MouseEvent.MOUSE_UP, __stageMouseUp, false, 1);
        if (_contextMenuDisabled)
        {
            _nativeStage.addEventListener("rightMouseDown" /*MouseEvent.RIGHT_MOUSE_DOWN*/, __stageMouseDownCapture, true);
            _nativeStage.addEventListener("rightMouseUp" /*MouseEvent.RIGHT_MOUSE_UP*/, __stageMouseUpCapture, true);
        }

        _modalLayer = new GGraph();
        _modalLayer.setSize(this.width, this.height);
        _modalLayer.drawRect(0, 0, 0, UIConfig.modalLayerColor, UIConfig.modalLayerAlpha);
        _modalLayer.addRelation(this, RelationType.Size);

        var osStr:String = Capabilities.os.toLowerCase().substr(0, 3);
        if (osStr == "ios" || osStr == "and" || osStr == "bla" || osStr == "tiz")
            _nativeStage.addEventListener("orientationChange", __orientationChange);
        else
            _nativeStage.addEventListener(Event.RESIZE, __winResize);
        __winResize(null);
    }

    private function __stageMouseDownCapture(evt:MouseEvent):Void
    {
        ctrlKeyDown = evt.ctrlKey;
        shiftKeyDown = evt.shiftKey;
        buttonDown = true;
        _hitUI = evt.target != _nativeStage;

        var mc:DisplayObject = try cast(evt.target, DisplayObject)
        catch (e:Dynamic) null;
        while (mc != _nativeStage && mc != null)
        {
            if (Std.is(mc, UIDisplayObject))
            {
                var gg:GObject = cast(mc, UIDisplayObject).owner;
                if (gg.touchable && gg.focusable)
                {
                    this.setFocus(gg);
                    break;
                }
            }
            mc = mc.parent;
        }

        if (_tooltipWin != null)
            hideTooltips();

        _justClosedPopups.splice(0, _justClosedPopups.length);
        var popup:GObject;
        var i:Int;
        if (_popupStack.length > 0)
        {
            mc = try cast(evt.target, DisplayObject)
            catch (e:Dynamic) null;
            var handled:Bool = false;
            while (mc != _nativeStage && mc != null)
            {
                if (Std.is(mc, UIDisplayObject))
                {
                    var pindex:Int = Lambda.indexOf(_popupStack, cast(mc, UIDisplayObject).owner);
                    if (pindex != -1)
                    {
                        i = _popupStack.length - 1;
                        while (i > pindex)
                        {
                            popup = _popupStack.pop();
                            closePopup(popup);
                            _justClosedPopups.push(popup);
                            i--;
                        }
                        handled = true;
                        break;
                    }
                }
                mc = mc.parent;
            }

            if (!handled)
            {
                var cnt:Int = _popupStack.length;
                i = cnt - 1;
                while (i >= 0)
                {
                    popup = _popupStack[i];
                    closePopup(popup);
                    _justClosedPopups.push(popup);
                    i--;
                }
                _popupStack.splice(0, _popupStack.length);
            }
        }
    }

    private function __stageMouseDown(evt:MouseEvent):Void
    {
        if (evt.eventPhase == EventPhase.AT_TARGET)
            __stageMouseDownCapture(evt);

        if (eatUIEvents && evt.target != _nativeStage)
            evt.stopImmediatePropagation();
    }

    private function __stageMouseUpCapture(evt:MouseEvent):Void
    {
        buttonDown = false;
    }

    private function __stageMouseUp(evt:MouseEvent):Void
    {
        if (evt.eventPhase == EventPhase.AT_TARGET)
            __stageMouseUpCapture(evt);

        if (eatUIEvents && (_hitUI || evt.target != _nativeStage))
            evt.stopImmediatePropagation();

        _hitUI = false;
    }

    private function __winResize(evt:Event):Void
    {
        applyScaleFactor();
    }

    private function __orientationChange(evt:Event):Void
    {
        applyScaleFactor();
    }
}


