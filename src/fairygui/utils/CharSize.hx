package fairygui.utils;


import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;

class CharSize
{
    private static var testTextField : TextField;
    private static var testTextFormat : TextFormat;
    private static var results : Dynamic;
    private static var boldResults : Dynamic;
    
    public static function getWidth(size : Int, font : String = null, bold : Bool = false) : Int{
        return calculateSize(size, font, bold).width;
    }
    
    public static function getHeight(size : Int, font : String = null, bold : Bool = false) : Int{
        return calculateSize(size, font, bold).height;
    }
    
    private static function calculateSize(size : Int, font : String, bold : Bool) : Dynamic{
        if (testTextField == null) {
            testTextField = new TextField();
            testTextField.autoSize = TextFieldAutoSize.LEFT;
            testTextField.text = "　";
            testTextFormat = new TextFormat();
            results = { };
            boldResults = { };
        }
        var col : Dynamic = (bold) ? Reflect.field(boldResults, font) : Reflect.field(results, font);
        if (col == null) 
        {
            col = { };
            if (bold) 
                Reflect.setField(boldResults, font, col)
            else 
            Reflect.setField(results, font, col);
        }
        var ret : Dynamic = col[size];
        if (ret != null) 
            return ret;
        
        ret = { };
        col[size] = ret;
        
        testTextFormat.font = font;
        testTextFormat.size = size;
        testTextFormat.bold = bold;
        testTextField.setTextFormat(testTextFormat);
        ret.width = testTextField.textWidth;
        ret.height = testTextField.textHeight;
        return ret;
    }

    public function new()
    {
    }
}
