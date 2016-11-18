package fairygui.utils;


import openfl.text.Font;
import openfl.text.FontStyle;
import openfl.text.TextFormat;

class FontUtils
{
    private static var sEmbeddedFonts : Array<Dynamic> = null;
    
    public function new()
    {
    }
    
    public static function updateEmbeddedFonts() : Void
    {
        sEmbeddedFonts = null;
    }
    
    //from starling
    public static function isEmbeddedFont(format : TextFormat) : Bool
    {
        if (sEmbeddedFonts == null) 
            sEmbeddedFonts = Font.enumerateFonts(false);
        
        for (font in sEmbeddedFonts)
        {
            var style : String = font.fontStyle;
            var isBold : Bool = style == FontStyle.BOLD || style == FontStyle.BOLD_ITALIC;
            var isItalic : Bool = style == FontStyle.ITALIC || style == FontStyle.BOLD_ITALIC;
            
            if (format.font == font.fontName && format.italic == isItalic && format.bold == isBold) 
                return true;
        }
        
        return false;
    }
}
