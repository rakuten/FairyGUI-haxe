package fairygui;

import fairygui.GComponent;
import fairygui.GObject;
import fairygui.PackageItem;
import fairygui.PageOption;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.media.Sound;

import fairygui.event.GTouchEvent;
import fairygui.event.StateChangeEvent;
import fairygui.utils.GTimers;
import fairygui.utils.ToolSet;

@:meta(Event(name="stateChanged",type="fairygui.event.StateChangeEvent"))

class GButton extends GComponent
{
    public var selectedIcon(get, set) : String;
    public var title(get, set) : String;
    public var selectedTitle(get, set) : String;
    public var titleColor(get, set) : Int;
    public var sound(get, set) : String;
    public var soundVolumeScale(get, set) : Float;
    public var selected(get, set) : Bool;
    public var mode(get, set) : Int;
    public var useHandCursor(get, set) : Bool;
    public var relatedController(get, set) : Controller;
    public var pageOption(get, never) : PageOption;
    public var changeStateOnClick(get, set) : Bool;
    public var linkedPopup(get, set) : GObject;

    private var _titleObject : GObject;
    private var _iconObject : GObject;
    private var _relatedController : Controller;
    
    private var _mode : Int;
    private var _selected : Bool = false;
    private var _title : String;
    private var _selectedTitle : String;
    private var _icon : String;
    private var _selectedIcon : String;
    private var _sound : String;
    private var _soundVolumeScale : Float;
    private var _pageOption : PageOption;
    private var _buttonController : Controller;
    private var _changeStateOnClick : Bool;
    private var _linkedPopup : GObject;
    private var _hasDisabledPage : Bool = false;
    private var _downEffect : Int = 0;
    private var _downEffectValue : Float;
    private var _useHandCursor : Bool;
    
    private var _over : Bool = false;
    
    public static inline var UP : String = "up";
    public static inline var DOWN : String = "down";
    public static inline var OVER : String = "over";
    public static inline var SELECTED_OVER : String = "selectedOver";
    public static inline var DISABLED : String = "disabled";
    public static inline var SELECTED_DISABLED : String = "selectedDisabled";
    
    public function new()
    {
        super();

        _mode = ButtonMode.Common;
        _title = "";
        _icon = "";
        _sound = UIConfig.buttonSound;
        _soundVolumeScale = UIConfig.buttonSoundVolumeScale;
        _pageOption = new PageOption();
        _changeStateOnClick = true;
        _downEffectValue = 0.8;
        _useHandCursor = UIConfig.buttonUseHandCursor;
        if (_useHandCursor) 
        {
            cast(this.displayObject, Sprite).buttonMode = true;
            cast(this.displayObject, Sprite).useHandCursor = true;
        }
    }
    
    override private function get_icon() : String
    {
        return _icon;
    }
    
    override private function set_icon(value : String) : String
    {
        _icon = value;
        value = (_selected && _selectedIcon != null) ? _selectedIcon : _icon;
        if (_iconObject != null) 
            _iconObject.icon = value;
        updateGear(7);
        return value;
    }
    
    @:final private function get_selectedIcon() : String
    {
        return _selectedIcon;
    }
    
    private function set_selectedIcon(value : String) : String
    {
        _selectedIcon = value;
        value = ((_selected && _selectedIcon != null)) ? _selectedIcon : _icon;
        if (_iconObject != null) 
            _iconObject.icon = value;
        return value;
    }
    
    @:final private function get_title() : String
    {
        return _title;
    }
    
    private function set_title(value : String) : String
    {
        _title = value;
        if (_titleObject != null) 
            _titleObject.text = ((_selected && _selectedTitle != null)) ? _selectedTitle : _title;
        updateGear(6);
        return value;
    }
    
    @:final override private function get_text() : String
    {
        return this.title;
    }
    
    override private function set_text(value : String) : String
    {
        this.title = value;
        return value;
    }
    
    @:final private function get_selectedTitle() : String
    {
        return _selectedTitle;
    }
    
    private function set_selectedTitle(value : String) : String
    {
        _selectedTitle = value;
        if (_titleObject != null) 
            _titleObject.text = ((_selected && _selectedTitle != null)) ? _selectedTitle : _title;
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
    
    @:final private function get_sound() : String
    {
        return _sound;
    }
    
    private function set_sound(val : String) : String
    {
        _sound = val;
        return val;
    }
    
    private function get_soundVolumeScale() : Float
    {
        return _soundVolumeScale;
    }
    
    private function set_soundVolumeScale(value : Float) : Float
    {
        _soundVolumeScale = value;
        return value;
    }
    
    private function set_selected(val : Bool) : Bool
    {
        if (_mode == ButtonMode.Common) 
            return false;
        
        if (_selected != val) 
        {
            _selected = val;
            setCurrentState();
            if (_selectedTitle != null && _titleObject != null) 
                _titleObject.text = (_selected) ? _selectedTitle : _title;
            if (_selectedIcon != null) 
            {
                var str : String = (_selected) ? _selectedIcon : _icon;
                if (_iconObject != null) 
                    _iconObject.icon = str;
            }
            if (_relatedController != null
                && _parent != null
                && !_parent._buildingDisplayList) 
            {
                if (_selected) 
                {
                    _relatedController.selectedPageId = _pageOption.id;
                    if (_relatedController._autoRadioGroupDepth) 
                        _parent.adjustRadioGroupDepth(this, _relatedController);
                }
                else if (_mode == ButtonMode.Check && _relatedController.selectedPageId == _pageOption.id) 
                    _relatedController.oppositePageId = _pageOption.id;
            }
        }
        return val;
    }
    
    @:final private function get_selected() : Bool
    {
        return _selected;
    }
    
    @:final private function get_mode() : Int
    {
        return _mode;
    }
    
    private function set_mode(value : Int) : Int
    {
        if (_mode != value) 
        {
            if (value == ButtonMode.Common) 
                this.selected = false;
            _mode = value;
        }
        return value;
    }
    
    @:final private function get_useHandCursor() : Bool
    {
        return _useHandCursor;
    }
    
    private function set_useHandCursor(value : Bool) : Bool
    {
        _useHandCursor = value;
        cast(this.displayObject, Sprite).buttonMode = _useHandCursor;
        cast(this.displayObject, Sprite).useHandCursor = _useHandCursor;
        return value;
    }
    
    @:final private function get_relatedController() : Controller
    {
        return _relatedController;
    }
    
    private function set_relatedController(val : Controller) : Controller
    {
        if (val != _relatedController) 
        {
            _relatedController = val;
            _pageOption.controller = val;
            _pageOption.clear();
        }
        return val;
    }
    
    @:final private function get_pageOption() : PageOption
    {
        return _pageOption;
    }
    
    @:final private function get_changeStateOnClick() : Bool
    {
        return _changeStateOnClick;
    }
    
    @:final private function set_changeStateOnClick(value : Bool) : Bool
    {
        _changeStateOnClick = value;
        return value;
    }
    
    @:final private function get_linkedPopup() : GObject
    {
        return _linkedPopup;
    }
    
    @:final private function set_linkedPopup(value : GObject) : GObject
    {
        _linkedPopup = value;
        return value;
    }
    
    public function addStateListener(listener:Dynamic) : Void
    {
        addEventListener(StateChangeEvent.CHANGED, listener);
    }
    
    public function removeStateListener(listener:Dynamic) : Void
    {
        removeEventListener(StateChangeEvent.CHANGED, listener);
    }
    
    public function fireClick(downEffect : Bool = true) : Void
    {
        if (downEffect && _mode == ButtonMode.Common) 
        {
            setState(OVER);
            GTimers.inst.add(100, 1, setState, DOWN);
            GTimers.inst.add(200, 1, setState, UP);
        }
        __click(null);
    }
    
    private function setState(val : String) : Void
    {
        if (_buttonController != null) 
            _buttonController.selectedPage = val;
        
        if (_downEffect == 1) 
        {
            var cnt : Int = this.numChildren;
            var obj : GObject;
            if (val == DOWN || val == SELECTED_OVER || val == SELECTED_DISABLED) 
            {
                var r : Int = Std.int(_downEffectValue * 255);
                var color : Int = (r << 16) + (r << 8) + r;
                for (i in 0...cnt){
                    obj = this.getChildAt(i);
                    if ((Std.is(obj, IColorGear)) && !(Std.is(obj, GTextField))) 
                        cast(obj, IColorGear).color = color;
                }
            }
            else 
            {
                for (i in 0...cnt){
                    obj = this.getChildAt(i);
                    if ((Std.is(obj, IColorGear)) && !(Std.is(obj, GTextField))) 
                        cast(obj, IColorGear).color = 0xFFFFFF;
                }
            }
        }
        else if (_downEffect == 2) 
        {
            if (val == DOWN || val == SELECTED_OVER || val == SELECTED_DISABLED) 
                setScale(_downEffectValue, _downEffectValue)
            else 
            setScale(1, 1);
        }
    }
    
    private function setCurrentState() : Void
    {
        if (this.grayed && _buttonController != null && _buttonController.hasPage(DISABLED)) 
        {
            if (_selected) 
                setState(SELECTED_DISABLED)
            else 
            setState(DISABLED);
        }
        else 
        {
            if (_selected) 
                setState((_over) ? SELECTED_OVER : DOWN)
            else 
            setState((_over) ? OVER : UP);
        }
    }
    
    override public function handleControllerChanged(c : Controller) : Void
    {
        super.handleControllerChanged(c);
        
        if (_relatedController == c) 
            this.selected = _pageOption.id == c.selectedPageId;
    }
    
    override private function handleGrayedChanged() : Void
    {
        if (_buttonController != null && _buttonController.hasPage(DISABLED)) 
        {
            if (this.grayed) {
                if (_selected) 
                    setState(SELECTED_DISABLED)
                else 
                setState(DISABLED);
            }
            else 
            {
                if (_selected) 
                    setState(DOWN)
                else 
                setState(UP);
            }
        }
        else 
        super.handleGrayedChanged();
    }
    
    override private function constructFromXML(xml : FastXML) : Void
    {
        super.constructFromXML(xml);
        
        xml = xml.nodes.Button.get(0);
        
        var str : String;
        str = xml.att.mode;
        if (str != null) 
            _mode = ButtonMode.parse(str);
        
        _sound = xml.att.sound;
        str = xml.att.volume;
        if (str != null) 
            _soundVolumeScale = Std.parseInt(str) / 100;
        
        str = xml.att.downEffect;
        if (str != null) 
        {
            _downEffect = (str == "dark") ? 1 : ((str == "scale") ? 2 : 0);
            str = xml.att.downEffectValue;
            _downEffectValue = Std.parseFloat(str);
        }
        
        _buttonController = getController("button");
        _titleObject = getChild("title");
        _iconObject = getChild("icon");
        if (_titleObject != null) 
            _title = _titleObject.text;
        if (_iconObject != null) 
            _icon = _iconObject.icon;
        
        if (_mode == ButtonMode.Common) 
            setState(UP);
        
        this.opaque = true;
        
        if (!GRoot.touchScreen) 
        {
            displayObject.addEventListener(MouseEvent.ROLL_OVER, __rollover);
            displayObject.addEventListener(MouseEvent.ROLL_OUT, __rollout);
        }
        this.addEventListener(GTouchEvent.BEGIN, __mousedown);
        this.addEventListener(GTouchEvent.END, __mouseup);
        this.addEventListener(GTouchEvent.CLICK, __click, false, 1000);
    }
    
    override public function setup_afterAdd(xml : FastXML) : Void
    {
        super.setup_afterAdd(xml);
        
        if (_downEffect == 2) 
            this.setPivot(0.5, 0.5);
        
        xml = xml.nodes.Button.get(0);
        if (xml != null) 
        {
            var str : String;
            str = xml.att.title;
            if (str != null) 
                this.title = str;
            str = xml.att.icon;
            if (str != null) 
                this.icon = str;
            str = xml.att.selectedTitle;
            if (str != null) 
                this.selectedTitle = str;
            str = xml.att.selectedIcon;
            if (str != null) 
                this.selectedIcon = str;
            
            str = xml.att.titleColor;
            if (str != null) 
                this.titleColor = ToolSet.convertFromHtmlColor(str);
            
            if (xml.att.sound != null) 
                _sound = xml.att.sound;
            str = xml.att.volume;
            if (str != null) 
                _soundVolumeScale = Std.parseInt(str) / 100;
            
            str = xml.att.controller;
            if (str != null) 
                _relatedController = _parent.getController(xml.att.controller)
            else 
            _relatedController = null;
            _pageOption.id = xml.att.page;
            this.selected = xml.att.checked == "true";
        }
    }
    
    private function __rollover(evt : Event) : Void
    {
        if (_buttonController == null || !_buttonController.hasPage(OVER)) 
            return;
        
        _over = true;
        if (this.isDown) 
            return;
        
        if (this.grayed && _buttonController.hasPage(DISABLED)) 
            return;
        
        setState((_selected) ? SELECTED_OVER : OVER);
    }
    
    private function __rollout(evt : Event) : Void
    {
        if (_buttonController == null || !_buttonController.hasPage(OVER)) 
            return;
        
        _over = false;
        if (this.isDown) 
            return;
        
        if (this.grayed && _buttonController.hasPage(DISABLED)) 
            return;
        
        setState((_selected) ? DOWN : UP);
    }
    
    private function __mousedown(evt : Event) : Void
    {
        if (_mode == ButtonMode.Common) 
        {
            if (this.grayed && _buttonController != null && _buttonController.hasPage(DISABLED)) 
                setState(SELECTED_DISABLED)
            else 
            setState(DOWN);
        }
        
        if (_linkedPopup != null) 
        {
            if (Std.is(_linkedPopup, Window)) 
                cast((_linkedPopup), Window).toggleStatus()
            else 
            this.root.togglePopup(_linkedPopup, this);
        }
    }
    
    private function __mouseup(evt : Event) : Void
    {
        if (_mode == ButtonMode.Common) 
        {
            if (this.grayed && _buttonController != null && _buttonController.hasPage(DISABLED)) 
                setState(DISABLED)
            else if (_over) 
                setState(OVER)
            else 
            setState(UP);
        }
        else 
        {
            if (!_over
                && _buttonController != null
                && (_buttonController.selectedPage == OVER || _buttonController.selectedPage == SELECTED_OVER)) 
            {
                setCurrentState();
            }
        }
    }
    
    private function __click(evt : Event) : Void
    {
        if (_sound != null) 
        {
            var pi : PackageItem = UIPackage.getItemByURL(_sound);
            if (pi != null) 
            {
                var sound : Sound = pi.owner.getSound(pi);
                if (sound != null) 
                    GRoot.inst.playOneShotSound(sound, _soundVolumeScale);
            }
        }
        
        if (!_changeStateOnClick) 
            return;
        
        if (_mode == ButtonMode.Check) 
        {
            this.selected = !_selected;
            dispatchEvent(new StateChangeEvent(StateChangeEvent.CHANGED));
        }
        else if (_mode == ButtonMode.Radio) 
        {
            if (!_selected) 
            {
                this.selected = true;
                dispatchEvent(new StateChangeEvent(StateChangeEvent.CHANGED));
            }
        }
    }
}
