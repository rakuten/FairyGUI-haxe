package fairygui;

import fairygui.event.ItemEvent;
import fairygui.utils.CompatUtil;
import fairygui.utils.GTimers;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.ui.Mouse;

class PopupMenu
{
    private var _contentPane:GComponent;
    private var _list:GList;
    public var itemCount(get, never):Int;
    public var contentPane(get, never):GComponent;

    public var list(get, never):GList;

    private var _expandingItem:GObject;

    private var _parentMenu:PopupMenu;

    public var visibleItemCount:Int = CompatUtil.INT_MAX_VALUE;
    public var hideOnClickItem:Bool = true;

    public function new(resourceURL:String = null)
    {
        if (resourceURL == null)
        {
            resourceURL = UIConfig.popupMenu;
            if (resourceURL == null)
                throw new Error("UIConfig.popupMenu not defined");
        }

        _contentPane = cast(UIPackage.createObjectFromURL(resourceURL), GComponent);
        _contentPane.addEventListener(Event.ADDED_TO_STAGE, __addedToStage);
        _contentPane.addEventListener(Event.REMOVED_FROM_STAGE, __removeFromStage);

        _list = cast(_contentPane.getChild("list"), GList);
        _list.removeChildrenToPool();

        _list.addRelation(_contentPane, RelationType.Width);
        _list.removeRelation(_contentPane, RelationType.Height);
        _contentPane.addRelation(_list, RelationType.Height);

        _list.addEventListener(ItemEvent.CLICK, __clickItem);
    }

    public function dispose():Void
    {
        _contentPane.dispose();
    }

    public function addItem(caption:String, callback:Dynamic = null):GButton
    {
        var item:GButton = _list.addItemFromPool().asButton;
        item.title = caption;
        item.data = callback;
        item.grayed = false;
        item.useHandCursor = false;
        var c:Controller = item.getController("checked");
        if (c != null)
            c.selectedIndex = 0;
        if (Mouse.supportsCursor)
        {
            item.addEventListener(MouseEvent.ROLL_OVER, __rollOver);
            item.addEventListener(MouseEvent.ROLL_OUT, __rollOut);
        }
        return item;
    }

    public function addItemAt(caption:String, index:Int, callback:Dynamic = null):GButton
    {
        var item:GButton = _list.getFromPool().asButton;
        _list.addChildAt(item, index);
        item.title = caption;
        item.data = callback;
        item.grayed = false;
        item.useHandCursor = false;
        var c:Controller = item.getController("checked");
        if (c != null)
            c.selectedIndex = 0;
        if (Mouse.supportsCursor)
        {
            item.addEventListener(MouseEvent.ROLL_OVER, __rollOver);
            item.addEventListener(MouseEvent.ROLL_OUT, __rollOut);
        }
        return item;
    }

    public function addSeperator():Void
    {
        if (UIConfig.popupMenu_seperator == null)
            throw new Error("UIConfig.popupMenu_seperator not defined");

        var item:GObject = list.addItemFromPool(UIConfig.popupMenu_seperator);
        if (Mouse.supportsCursor)
        {
            item.addEventListener(MouseEvent.ROLL_OVER, __rollOver);
            item.addEventListener(MouseEvent.ROLL_OUT, __rollOut);
        }
    }

    public function getItemName(index:Int):String
    {
        var item:GButton = cast(_list.getChildAt(index), GButton);
        return item.name;
    }

    public function setItemText(name:String, caption:String):Void
    {
        var item:GButton = _list.getChild(name).asButton;
        item.title = caption;
    }

    public function setItemVisible(name:String, visible:Bool):Void
    {
        var item:GButton = _list.getChild(name).asButton;
        if (item.visible != visible)
        {
            item.visible = visible;
            _list.setBoundsChangedFlag();
        }
    }

    public function setItemGrayed(name:String, grayed:Bool):Void
    {
        var item:GButton = _list.getChild(name).asButton;
        item.grayed = grayed;
    }

    public function setItemCheckable(name:String, checkable:Bool):Void
    {
        var item:GButton = _list.getChild(name).asButton;
        var c:Controller = item.getController("checked");
        if (c != null)
        {
            if (checkable)
            {
                if (c.selectedIndex == 0)
                    c.selectedIndex = 1;
            }
            else
                c.selectedIndex = 0;
        }
    }

    public function setItemChecked(name:String, checked:Bool):Void
    {
        var item:GButton = _list.getChild(name).asButton;
        var c:Controller = item.getController("checked");
        if (c != null)
            c.selectedIndex = (checked) ? 2 : 1;
    }

    public function isItemChecked(name:String):Bool
    {
        var item:GButton = _list.getChild(name).asButton;
        var c:Controller = item.getController("checked");
        if (c != null)
            return c.selectedIndex == 2;
        else
            return false;
    }

    public function removeItem(name:String):Bool
    {
        var item:GButton = cast(_list.getChild(name), GButton);
        if (item != null)
        {
            var index:Int = _list.getChildIndex(item);
            _list.removeChildToPoolAt(index);
            return true;
        }
        else
            return false;
    }

    public function clearItems():Void
    {
        _list.removeChildrenToPool();
    }

    private function get_itemCount():Int
    {
        return _list.numChildren;
    }

    private function get_contentPane():GComponent
    {
        return _contentPane;
    }

    private function get_list():GList
    {
        return _list;
    }

    public function show(target:GObject = null, downward:Dynamic = null, parentMenu:PopupMenu = null):Void
    {
        var r:GRoot = (target != null) ? target.root : GRoot.inst;
        r.showPopup(this.contentPane, Std.is(target, GRoot) ? null : target, downward);
        _parentMenu = parentMenu;
    }

    public function hide():Void
    {
        if (contentPane.parent != null)
            cast(contentPane.parent, GRoot).hidePopup(contentPane);
    }

    private function showSecondLevelMenu(item:GObject):Void
    {
        _expandingItem = item;

        var popup:PopupMenu = cast(item.data, PopupMenu);
        if (Std.is(item, GButton))
            cast(item, GButton).selected = true;
        popup.show(item, null, this);

        var pt:Point = contentPane.localToRoot(item.x + item.width - 5, item.y - 5);
        popup.contentPane.setXY(pt.x, pt.y);
    }

    private function closeSecondLevelMenu():Void
    {
        if (Std.is(_expandingItem, GButton))
            cast(_expandingItem, GButton).selected = false;
        var popup:PopupMenu = cast(_expandingItem.data, PopupMenu);
        _expandingItem = null;
        popup.hide();
    }

    private function __clickItem(evt:ItemEvent):Void
    {
        var item:GButton = evt.itemObject.asButton;
        if (item == null)
            return;

        if (item.grayed)
        {
            _list.selectedIndex = -1;
            return;
        }

        var c:Controller = item.getController("checked");
        if (c != null && c.selectedIndex != 0)
        {
            if (c.selectedIndex == 1)
                c.selectedIndex = 2;
            else
                c.selectedIndex = 1;
        }

        if (hideOnClickItem)
        {
            if (_parentMenu != null)
                _parentMenu.hide();
            hide();
        }

        if ((item.data != null) && !Std.is(item.data, PopupMenu))
        {
            if (item.data.length == 1)
                item.data(evt);
            else
                item.data();
        }
    }

    private function __addedToStage(evt:Event):Void
    {
        _list.selectedIndex = -1;
        _list.resizeToFit(visibleItemCount, 10);
    }

    private function __removeFromStage(evt:Event):Void
    {
        _parentMenu = null;

        if (_expandingItem != null)
            closeSecondLevelMenu();
    }

    private function __rollOver(evt:MouseEvent):Void
    {
        var item:GObject = cast(evt.currentTarget, GObject);
        if (Std.is(item.data, PopupMenu) || _expandingItem != null)
            GTimers.inst.callDelay(100, __showSubMenu, item);
    }

    private function __showSubMenu(item:GObject):Void
    {
        var r:GRoot = contentPane.root;
        if (r == null)
            return;

        if (_expandingItem != null)
        {
            if (_expandingItem == item)
                return;

            closeSecondLevelMenu();
        }

        var popup:PopupMenu = cast(item.data, PopupMenu);
        if (popup == null)
            return;

        showSecondLevelMenu(item);
    }

    private function __rollOut(evt:MouseEvent):Void
    {
        if (_expandingItem == null)
            return;

        GTimers.inst.remove(__showSubMenu);
        var r:GRoot = contentPane.root;
        if (r != null)
        {
            var popup:PopupMenu = cast(_expandingItem.data, PopupMenu);
            var pt:Point = popup.contentPane.globalToLocal(r.nativeStage.mouseX, r.nativeStage.mouseY);
            if (pt.x >= 0 && pt.y >= 0 && pt.x < popup.contentPane.width && pt.y < popup.contentPane.height)
                return;
        }

        closeSecondLevelMenu();
    }
}
