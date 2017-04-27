package fairygui;

import fairygui.GObject;

import fairygui.utils.ToolSet;

class GLabel extends GComponent implements IColorGear
{
    public var title(get, set) : String;
    public var titleColor(get, set) : Int;
    public var editable(get, set) : Bool;
    public var titleFontSize(get, set): Int;
    public var color(get, set):UInt;

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
        var tf:GTextField = getTextField();
        if(tf!=null)
            return tf.color;
        else 
        return 0;
    }
    
    private function set_titleColor(value : Int) : Int
    {
        var tf:GTextField = getTextField();
        if(tf!=null)
            tf.color = value;
        updateGear(4);
        return value;
    }

    @:final public function get_titleFontSize():Int
    {
        var tf:GTextField = getTextField();
        if(tf != null)
            return tf.fontSize;
        else
            return 0;
    }

    public function set_titleFontSize(value:Int):Int
    {
        var tf:GTextField = getTextField();
        if(tf!=null)
            tf.fontSize = value;
        return value;
    }

    public function get_color():UInt
    {
        return this.titleColor;
    }

    public function set_color(value:UInt):UInt
    {
        this.titleColor = value;
        return value;
    }
    
    private function set_editable(val : Bool) : Bool
    {
        var tf:GTextField = getTextField();
        if(tf!=null && Std.is(tf,GTextInput))
            tf.asTextInput.editable = val;
        return val;
    }
    
    private function get_editable() : Bool
    {
        var tf:GTextField = getTextField();
        if(tf!=null && Std.is(tf, GTextInput))
            return tf.asTextInput.editable;
        else 
            return false;
    }

    public function getTextField():GTextField
    {
        if (Std.is(_titleObject, GTextField))
            return cast(_titleObject, GTextField);
        else if(Std.is(_titleObject, GLabel))
            return cast(_titleObject, GLabel).getTextField();
        else if(Std.is(_titleObject, GButton))
            return cast(_titleObject, GButton).getTextField();
        else
            return null;
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
            str = xml.att.titleFontSize;
            if(str != null)
                this.titleFontSize = Std.parseInt(str);

            var tf:GTextField = getTextField();
            if (Std.is(tf, GTextInput))
            {
                str = xml.att.prompt;
                if (str != null) 
                    cast(tf, GTextInput).promptText = str;
                str = xml.att.maxLength;
                if (str != null) 
                    cast(tf, GTextInput).maxLength = Std.parseInt(str);
                str = xml.att.restrict;
                if (str != null) 
                    cast(tf, GTextInput).restrict = str;
                str = xml.att.password;
                if (str != null) 
                    cast(tf, GTextInput).password = str == "true";
            }
        }
    }
}


