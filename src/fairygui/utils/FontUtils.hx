package fairygui.utils;


import openfl.text.Font;
import openfl.text.FontStyle;
import openfl.text.TextFormat;

class FontUtils
{
    private static var sEmbeddedFonts:Array<Font> = null;

    public function new()
    {
    }

    public static function registerFont(fontName:String, path:String):Void
    {
        var font:Font = Font.fromFile(path);
//        font.fontName = fontName;
        Font.enumerateFonts().push(font);
    }

    public static function updateEmbeddedFonts():Void
    {
        sEmbeddedFonts = null;
    }

    //from starling
    public static function isEmbeddedFont(format:TextFormat):Bool
    {
        if (sEmbeddedFonts == null)
            sEmbeddedFonts = Font.enumerateFonts(false);

        for (font in sEmbeddedFonts)
        {
            var style:String = font.fontStyle;
            var isBold:Bool = style == FontStyle.BOLD || style == FontStyle.BOLD_ITALIC;
            var isItalic:Bool = style == FontStyle.ITALIC || style == FontStyle.BOLD_ITALIC;
            var fBold:Bool = format.bold == null ? false : format.bold;
            var fItalic:Bool = format.italic == null ? false : format.italic;


            if (format.font == font.fontName && fItalic == isItalic && fBold == isBold)
                return true;
        }

        return false;
    }
}
