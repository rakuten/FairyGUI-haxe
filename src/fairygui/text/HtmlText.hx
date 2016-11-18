package fairygui.text;


import Xml.XmlType;
import openfl.text.TextField;
import openfl.text.TextFormat;

class HtmlText
{
    public var parsedText : String;
    public var elements : Array<HtmlElement>;
    
    public function new(val : String)
    {
        elements = new Array<HtmlElement>();
        try{

            val = StringTools.replace(val,"\r\n", "\n");
            val = StringTools.replace(val,"\r", "\n");
            var xml : FastXML = FastXML.parse("<dummy>" + val + "</dummy>");
            var list : FastXMLList = xml.descendants();
            parsedText = "";
            parseXML(list);
        }
        catch (e : Dynamic)
        {
            parsedText = val;
            elements.splice(0,-1);
        }
    }
    
    public function appendTo(textField : TextField) : Void
    {
        var pos : Int = textField.text.length;
        textField.replaceText(pos, pos, parsedText);
        var i : Int = elements.length - 1;
        while (i >= 0){
            var e : HtmlElement = elements[i];
            textField.setTextFormat(e.textformat, pos + e.start, pos + e.end + 1);
            i--;
        }
    }
    
    private function parseXML(list : FastXMLList) : Void
    {
        var cnt : Int = list.length();
        var tag : String;
        var attr : FastXMLList;
        var node : FastXML;
        var tf : TextFormat;
        var start : Int;
        var element : HtmlElement;
        for (i in 0...cnt){
            node = list.get(i);
            tag = node.name;
            if (tag == "font") {
                tf = new TextFormat();
                attr = node.nodes.resolve("size");
                if (attr.length() > 0)
                    tf.size = Std.parseInt(attr.get(0).value);
                attr = node.nodes.resolve("color");
                if (attr.length() > 0)
                    tf.color = Std.parseInt("0x"+attr.get(0).value.substr(1));
                attr = node.nodes.resolve("italic");
                if (attr.length() > 0)
                    tf.italic = attr.get(0).value == "true";
                attr = node.nodes.resolve("underline");
                if (attr.length() > 0)
                    tf.underline = attr.get(0).value == "true";
                attr = node.nodes.resolve("face");
                if (attr.length() > 0)
                    tf.font = attr.get(0).value;
                
                start = parsedText.length;
                if (node.descendants().length()==0)
                    parsedText += node.att.text;
                else 
                parseXML(node.descendants());
                if (parsedText.length > start) 
                {
                    element = new HtmlElement();
                    element.start = start;
                    element.end = parsedText.length - 1;
                    element.textformat = tf;
                    elements.push(element);
                }
            }
            else if (tag == "a") {
                tf = new TextFormat();
                tf.underline = true;
                tf.url = "#";
                
                start = parsedText.length;
                if (node.descendants().length()==0)
                    parsedText += node.att.text;
                else 
                parseXML(node.descendants());
                if (parsedText.length > start) 
                {
                    element = new HtmlElement();
                    element.type = 1;
                    element.start = start;
                    element.end = parsedText.length - 1;
                    element.textformat = tf;
                    element.id = Std.string(node.att.id);
                    element.href = Std.string(node.att.href);
                    element.target = Std.string(node.att.target);
                    elements.push(element);
                }
            }
            else if (tag == "img") {
                start = parsedText.length;
                tf = new TextFormat();
                parsedText += "　";
                
                element = new HtmlElement();
                element.type = 2;
                element.id = Std.string(node.att.id);
                element.src = Std.string(node.att.src);
                element.width = Std.parseInt(Std.string(node.att.width));
                element.height = Std.parseInt(Std.string(node.att.height));
                element.start = start;
                element.end = parsedText.length - 1;
                element.textformat = tf;
                elements.push(element);
            }
            else if (tag == "b") {
                tf = new TextFormat();
                tf.bold = true;
                start = parsedText.length;
                if (node.descendants().length()==0)
                    parsedText += node.att.text;
                else 
                parseXML(node.descendants());
                if (parsedText.length > start) 
                {
                    element = new HtmlElement();
                    element.start = start;
                    element.end = parsedText.length - 1;
                    element.textformat = tf;
                    elements.push(element);
                }
            }
            else if (tag == "i") {
                tf = new TextFormat();
                tf.italic = true;
                start = parsedText.length;
                if (node.descendants().length()==0)
                    parsedText += node.att.text;
                else 
                parseXML(node.descendants());
                if (parsedText.length > start) 
                {
                    element = new HtmlElement();
                    element.start = start;
                    element.end = parsedText.length - 1;
                    element.textformat = tf;
                    elements.push(element);
                }
            }
            else if (tag == "u") {
                tf = new TextFormat();
                tf.underline = true;
                start = parsedText.length;
                if (node.descendants().length()==0)
                    parsedText += node.att.text;
                else 
                parseXML(node.descendants());
                if (parsedText.length > start) 
                {
                    element = new HtmlElement();
                    element.start = start;
                    element.end = parsedText.length - 1;
                    element.textformat = tf;
                    elements.push(element);
                }
            }
            else if (tag == "br") {
                parsedText += "\n";
            }
//            else if (node.node.nodeKind.innerData() == "text")
            else if (node.x.nodeType == XmlType.PCData)
            {
                var str : String = Std.string(node);
                
                parsedText += str;
            }
            else {
                parseXML(node.descendants());
            }
        }
    }
}


