package fairygui;

import fairygui.GObject;

import fairygui.utils.ToolSet;

class GLabel extends GComponent
{
    public var title(get, set) : String;
    public var titleColor(get, set) : Int;
    public var editable(get, set) : Bool;

    private var _titleObject : GObject;
    private var _iconObject : GObject;
    
    public function new()
    {
        super();
    }
    
    override private function get_icon() : String
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
    
    @:final private function get_title() : String
    {
        if (_titleObject != null) 
            return _titleObject.text
        else 
        return null;
    }
    
    private function set_title(value : String) : String
    {
        if (_titleObject != null) 
            _titleObject.text = value;
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
    
    private function set_editable(val : Bool) : Bool
    {
        if (Std.is(_titleObject, GTextInput)) 
            _titleObject.asTextInput.editable = val;
        return val;
    }
    
    private function get_editable() : Bool
    {
        if (Std.is(_titleObject, GTextInput)) 
            return _titleObject.asTextInput.editable
        else 
        return false;
    }
    
    override private function constructFromXML(xml : FastXML) : Void
    {
        super.constructFromXML(xml);
        
        _titleObject = getChild("title");
        _iconObject = getChild("icon");
    }
    
    override public function setup_afterAdd(xml : FastXML) : Void
    {
        super.setup_afterAdd(xml);
        
        xml = xml.nodes.Label.get(0);
        if (xml != null) 
        {
            var str : String;
            str = xml.att.title;
            if (str != null) 
                this.text = str;
            str = xml.att.icon;
            if (str != null) 
                this.icon = str;
            str = xml.att.titleColor;
            if (str != null) 
                this.titleColor = ToolSet.convertFromHtmlColor(str);
            
            if (Std.is(_titleObject, GTextInput)) 
            {
                str = xml.att.prompt;
                if (str != null) 
                    cast(_titleObject, GTextInput).promptText = str;
                str = xml.att.maxLength;
                if (str != null) 
                    cast(_titleObject, GTextInput).maxLength = Std.parseInt(str);
                str = xml.att.restrict;
                if (str != null) 
                    cast(_titleObject, GTextInput).restrict = str;
                str = xml.att.password;
                if (str != null) 
                    cast(_titleObject, GTextInput).password = str == "true";
            }
        }
    }
}


