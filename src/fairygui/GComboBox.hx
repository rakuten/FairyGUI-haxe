package fairygui;

import fairygui.GComponent;
import fairygui.GList;
import fairygui.GObject;

import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFieldType;

import fairygui.event.GTouchEvent;
import fairygui.event.ItemEvent;
import fairygui.event.StateChangeEvent;
import fairygui.utils.ToolSet;
import fairygui.utils.CompatUtil;

@:meta(Event(name="stateChanged",type="fairygui.event.StateChangeEvent"))

class GComboBox extends GComponent
{
    public var titleColor(get, set) : Int;
    public var visibleItemCount(get, set) : Int;
    public var popupDownward(get, set) : Dynamic;
    public var items(get, set) : Array<String>;
    public var icons(get, set) : Array<String>;
    public var values(get, set) : Array<String>;
    public var selectedIndex(get, set) : Int;
    public var value(get, set) : String;

    public var dropdown : GComponent;
    
    private var _titleObject : GObject;
    private var _iconObject : GObject;
    private var _list : GList;
    
    private var _items : Array<String>;
    private var _icons : Array<String>;
    private var _values : Array<String>;
    private var _popupDownward : Dynamic;
    
    private var _visibleItemCount : Int = 0;
    private var _itemsUpdated : Bool = false;
    private var _selectedIndex : Int = 0;
    private var _buttonController : Controller;
    private var _over : Bool = false;
    
    public function new()
    {
        super();
        _visibleItemCount = UIConfig.defaultComboBoxVisibleItemCount;
        _itemsUpdated = true;
        _selectedIndex = -1;
        _items = [];
        _values = [];
        _popupDownward = true;
    }
    
    @:final override private function get_text() : String
    {
        if (_titleObject != null) 
            return _titleObject.text
        else 
        return null;
    }
    
    override private function set_text(value : String) : String
    {
        if (_titleObject != null) 
            _titleObject.text = value;
        updateGear(6);
        return value;
    }
    
    @:final private function get_titleColor() : Int
    {
        if (Std.is(_titleObject, GTextField)) 
            return cast((_titleObject), GTextField).color
        else if (Std.is(_titleObject, GLabel)) 
            return cast((_titleObject), GLabel).titleColor
        else if (Std.is(_titleObject, GButton)) 
            return cast((_titleObject), GButton).titleColor
        else 
        return 0;
    }
    
    private function set_titleColor(value : Int) : Int
    {
        if (Std.is(_titleObject, GTextField)) 
            cast((_titleObject), GTextField).color = value
        else if (Std.is(_titleObject, GLabel)) 
            cast((_titleObject), GLabel).titleColor = value
        else if (Std.is(_titleObject, GButton)) 
            cast((_titleObject), GButton).titleColor = value;
        return value;
    }
    
    @:final override private function get_icon() : String
    {
        if (_iconObject != null) 
            return _iconObject.icon
        else 
        return null;
    }
    
    override private function set_icon(value : String) : String
    {
        if (_iconObject != null) 
            _iconObject.icon = value;
        updateGear(7);
        return value;
    }
    
    @:final private function get_visibleItemCount() : Int
    {
        return _visibleItemCount;
    }
    
    private function set_visibleItemCount(value : Int) : Int
    {
        _visibleItemCount = value;
        return value;
    }
    
    private function get_popupDownward() : Dynamic
    {
        return _popupDownward;
    }
    
    private function set_popupDownward(value : Dynamic) : Dynamic
    {
        _popupDownward = value;
        return value;
    }
    
    @:final private function get_items() : Array<String>
    {
        return _items;
    }
    
    private function set_items(value : Array<String>) : Array<String>
    {
        if (value == null)
            _items.splice(0, _items.length);
        else
            _items = value.concat([]);
        if (_items.length > 0) 
        {
            if (_selectedIndex >= _items.length) 
                _selectedIndex = _items.length - 1
            else if (_selectedIndex == -1) 
                _selectedIndex = 0;
            
            this.text = _items[_selectedIndex];
            if (_icons != null && _selectedIndex < _icons.length) 
                this.icon = _icons[_selectedIndex];
        }
        else 
        {
            this.text = "";
            if (_icons != null) 
                this.icon = null;
            _selectedIndex = -1;
        }
        _itemsUpdated = true;
        return value;
    }
    
    @:final private function get_icons() : Array<String>
    {
        return _icons;
    }
    
    private function set_icons(value : Array<String>) : Array<String>
    {
        _icons = value;
        if (_icons != null && _selectedIndex != -1 && _selectedIndex < _icons.length) 
            this.icon = _icons[_selectedIndex];
        return value;
    }
    
    @:final private function get_values() : Array<String>
    {
        return _values;
    }
    
    private function set_values(value : Array<String>) : Array<String>
    {
        if (value == null)
            _values.splice(0, _values.length);
        else 
        _values = value.concat([]);
        return value;
    }
    
    @:final private function get_selectedIndex() : Int
    {
        return _selectedIndex;
    }
    
    private function set_selectedIndex(val : Int) : Int
    {
        if (_selectedIndex == val) 
            return 0;
        
        _selectedIndex = val;
        if (_selectedIndex >= 0 && _selectedIndex < _items.length) 
        {
            this.text = _items[_selectedIndex];
            if (_icons != null && _selectedIndex < _icons.length) 
                this.icon = _icons[_selectedIndex];
        }
        else 
        {
            this.text = "";
            if (_icons != null) 
                this.icon = null;
        }
        return val;
    }
    
    private function get_value() : String
    {
        return _values[_selectedIndex];
    }
    
    private function set_value(val : String) : String
    {
        this.selectedIndex = Lambda.indexOf(_values, val);
        return val;
    }
    
    private function setState(val : String) : Void
    {
        if (_buttonController != null) 
            _buttonController.selectedPage = val;
    }
    
    private function setCurrentState() : Void
    {
        if (this.grayed && _buttonController != null && _buttonController.hasPage(GButton.DISABLED)) 
            setState(GButton.DISABLED)
        else 
        setState((_over) ? GButton.OVER : GButton.UP);
    }
    
    override private function handleGrayedChanged() : Void
    {
        if (_buttonController != null && _buttonController.hasPage(GButton.DISABLED)) 
        {
            if (this.grayed) 
                setState(GButton.DISABLED)
            else 
            setState(GButton.UP);
        }
        else 
        super.handleGrayedChanged();
    }
    
    override public function dispose() : Void
    {
        if (dropdown != null) 
        {
            dropdown.dispose();
            dropdown = null;
        }
        
        super.dispose();
    }
    
    override private function constructFromXML(xml : FastXML) : Void
    {
        super.constructFromXML(xml);
        
        xml = xml.nodes.ComboBox.get(0);
        
        var str : String;
        
        _buttonController = getController("button");
        _titleObject = getChild("title");
        _iconObject = getChild("icon");
        
        str = xml.att.dropdown;
        if (str != null) 
        {
            dropdown = try cast(UIPackage.createObjectFromURL(str), GComponent) catch(e:Dynamic) null;
            if (dropdown == null) 
            {
                trace("下拉框必须为元件");
                return;
            }
            
            _list = dropdown.getChild("list").asList;
            if (_list == null) 
            {
                trace(this.resourceURL + ": 下拉框的弹出元件里必须包含名为list的列表");
                return;
            }
            _list.addEventListener(ItemEvent.CLICK, __clickItem);
            
            _list.addRelation(dropdown, RelationType.Width);
            _list.removeRelation(dropdown, RelationType.Height);
            
            dropdown.addRelation(_list, RelationType.Height);
            dropdown.removeRelation(_list, RelationType.Width);
            
            dropdown.displayObject.addEventListener(Event.REMOVED_FROM_STAGE, __popupWinClosed);
        }
        
        this.opaque = true;
        
        if (!GRoot.touchScreen) 
        {
            displayObject.addEventListener(MouseEvent.ROLL_OVER, __rollover);
            displayObject.addEventListener(MouseEvent.ROLL_OUT, __rollout);
        }
        
        this.addEventListener(GTouchEvent.BEGIN, __mousedown);
        this.addEventListener(GTouchEvent.END, __mouseup);
    }
    
    override public function setup_afterAdd(xml : FastXML) : Void
    {
        super.setup_afterAdd(xml);
        
        xml = xml.nodes.ComboBox.get(0);
        if (xml != null) 
        {
            var str : String;
            str = xml.att.titleColor;
            if (str != null) 
                this.titleColor = ToolSet.convertFromHtmlColor(str);
            str = xml.att.visibleItemCount;
            if (str != null) 
                _visibleItemCount = Std.parseInt(str);
            
            var col : FastXMLList = xml.nodes.item;
            var i : Int = 0;
            for (cxml in col.iterator())
            {
                _items.push(Std.string(cxml.att.title));
                _values.push(Std.string(cxml.att.value));
                str = cxml.att.icon;
                if (str != null) 
                {
                    if (_icons == null) 
                        _icons = new Array<String>();
                    _icons[i] = str;
                }
                i++;
            }
            
            str = xml.att.title;
            if (str != null) 
            {
                this.text = str;
                _selectedIndex = Lambda.indexOf(_items, str);
            }
            else if (_items.length > 0) 
            {
                _selectedIndex = 0;
                this.text = _items[0];
            }
            else 
            _selectedIndex = -1;
            
            str = xml.att.icon;
            if (str != null) 
                this.icon = str;
            
            str = xml.att.direction;
            if (str != null) 
            {
                if (str == "up") 
                    _popupDownward = false
                else if (str == "auto") 
                    _popupDownward = null;
            }
        }
    }
    
    private function showDropdown() : Void
    {
        if (_itemsUpdated) 
        {
            _itemsUpdated = false;
            
            _list.removeChildrenToPool();
            var cnt : Int = _items.length;
            for (i in 0...cnt){
                var item : GObject = _list.addItemFromPool();
                item.name = (i < _values.length) ? _values[i] : "";
                item.text = _items[i];
                item.icon = ((_icons != null && i < _icons.length)) ? _icons[i] : null;
            }
            _list.resizeToFit(_visibleItemCount);
        }
        _list.selectedIndex = -1;
        dropdown.width = this.width;

        this.root.togglePopup(dropdown, this, _popupDownward);
        if (dropdown.parent != null)
            setState(GButton.DOWN);
    }
    
    private function __popupWinClosed(evt : Event) : Void
    {
        setCurrentState();
    }
    
    private function __clickItem(evt : ItemEvent) : Void
    {
        if (Std.is(dropdown.parent, GRoot)) 
            cast((dropdown.parent), GRoot).hidePopup(dropdown);
        _selectedIndex = CompatUtil.INT_MIN_VALUE;
        this.selectedIndex = _list.getChildIndex(evt.itemObject);
        dispatchEvent(new StateChangeEvent(StateChangeEvent.CHANGED));
    }
    
    private function __rollover(evt : Event) : Void
    {
        _over = true;
        if (this.isDown || dropdown != null && dropdown.parent != null)
            return;
        
        setCurrentState();
    }
    
    private function __rollout(evt : Event) : Void
    {
        _over = false;
        if (this.isDown || dropdown != null && dropdown.parent != null)
            return;
        
        setCurrentState();
    }

    private function __mousedown(evt : GTouchEvent) : Void
    {
        if (Std.is(evt.realTarget, TextField) && cast(evt.realTarget, TextField).type == TextFieldType.INPUT)
            return;
        
        if (dropdown != null) 
            showDropdown();
    }

    private function __mouseup(evt : Event) : Void
    {
        if (dropdown != null && dropdown.parent == null)
            setCurrentState();
    }
}

