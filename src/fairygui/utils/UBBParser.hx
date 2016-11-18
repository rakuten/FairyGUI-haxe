package fairygui.utils;


class UBBParser
{
    private var _text : String;
    private var _readPos : Int;
    
    private var _handlers : Dynamic;
    
    public var smallFontSize : Int = 12;
    public var normalFontSize : Int = 14;
    public var largeFontSize : Int = 16;
    
    public var defaultImgWidth : Int = 0;
    public var defaultImgHeight : Int = 0;
    
    public static var inst : UBBParser = new UBBParser();
    
    public function new()
    {
        _handlers = { };
        Reflect.setField(_handlers, "url", onTag_URL);
        Reflect.setField(_handlers, "img", onTag_IMG);
        Reflect.setField(_handlers, "b", onTag_Simple);
        Reflect.setField(_handlers, "i", onTag_Simple);
        Reflect.setField(_handlers, "u", onTag_Simple);
        Reflect.setField(_handlers, "sup", onTag_Simple);
        Reflect.setField(_handlers, "sub", onTag_Simple);
        Reflect.setField(_handlers, "color", onTag_COLOR);
        Reflect.setField(_handlers, "font", onTag_FONT);
        Reflect.setField(_handlers, "size", onTag_SIZE);
    }
    
    private function onTag_URL(tagName : String, end : Bool, attr : String) : String{
        if (!end) {
            if (attr != null) 
                return "<a href=\"" + attr + "\" target=\"_blank\">"
            else {
                var href : String = getTagText();
                return "<a href=\"" + href + "\" target=\"_blank\">";
            }
        }
        else 
        return "</a>";
    }
    
    private function onTag_IMG(tagName : String, end : Bool, attr : String) : String{
        if (!end) {
            var src : String = getTagText(true);
            if (src == null) 
                return null;
            
            if (defaultImgWidth != 0) 
                return "<img src=\"" + src + "\" width=\"" + defaultImgWidth + "\" height=\"" + defaultImgHeight + "\"/>"
            else 
            return "<img src=\"" + src + "\"/>";
        }
        else 
        return null;
    }
    
    private function onTag_Simple(tagName : String, end : Bool, attr : String) : String{
        return (end) ? ("</" + tagName + ">") : ("<" + tagName + ">");
    }
    
    private function onTag_COLOR(tagName : String, end : Bool, attr : String) : String{
        if (!end) 
            return "<font color=\"" + attr + "\">"
        else 
        return "</font>";
    }
    
    private function onTag_FONT(tagName : String, end : Bool, attr : String) : String{
        if (!end) 
            return "<font face=\"" + attr + "\">"
        else 
        return "</font>";
    }
    
    private function onTag_SIZE(tagName : String, end : Bool, attr : String) : String{
        if (!end) {
            if (attr == "normal") 
                attr = "" + normalFontSize
            else if (attr == "small") 
                attr = "" + smallFontSize
            else if (attr == "large") 
                attr = "" + largeFontSize
            else if (attr.length > 0 && attr.charAt(0) == "+")
                attr = "" + (smallFontSize + Std.parseInt(attr.substr(1)))
            else if (attr.length > 0 && attr.charAt(0) == "-")
                attr = "" + (smallFontSize - Std.parseInt(attr.substr(1)));
            return "<font size=\"" + attr + "\">";
        }
        else 
        return "</font>";
    }
    
    private function getTagText(remove : Bool = false) : String{
        var pos : Int = _text.indexOf("[", _readPos);
        if (pos == -1) 
            return null;
        
        var ret : String = _text.substring(_readPos, pos);
        if (remove) 
            _readPos = pos;
        return ret;
    }
    
    public function parse(text : String) : String{
        _text = text;
        var pos1 : Int = 0;
        var pos2 : Int;
        var pos3 : Int;
        var end : Bool;
        var tag : String;
        var attr : String;
        var repl : String;
        var func : Dynamic;
        while ((pos2 = _text.indexOf("[", pos1)) != -1){
            pos1 = pos2;
            pos2 = _text.indexOf("]", pos1);
            if (pos2 == -1) 
                break;
            
            end = _text.charAt(pos1 + 1) == "/";
            tag = _text.substring((end) ? pos1 + 2 : pos1 + 1, pos2);
            pos2++;
            _readPos = pos2;
            attr = null;
            repl = null;
            pos3 = tag.indexOf("=");
            if (pos3 != -1) {
                attr = tag.substring(pos3 + 1);
                tag = tag.substring(0, pos3);
            }
            tag = tag.toLowerCase();
            func = Reflect.field(_handlers, tag);
            if (func != null) {
                repl = func(tag, end, attr);
                if (repl == null) 
                    repl = "";
            }
            else {
                pos1 = pos2;
                continue;
            }
            _text = _text.substring(0, pos1) + repl + _text.substring(_readPos);
        }
        return _text;
    }
}
