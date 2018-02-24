package fairygui.utils;

import openfl.filters.BitmapFilter;
import fairygui.utils.UBBParser;

import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Stage;
import openfl.filters.ColorMatrixFilter;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

import fairygui.GObject;
import fairygui.display.UIDisplayObject;

class ToolSet
{
    public static var GRAY_FILTERS : Array<BitmapFilter> = [new ColorMatrixFilter(
        [0.299, 0.587, 0.114, 0, 0, 
        0.299, 0.587, 0.114, 0, 0, 
        0.299, 0.587, 0.114, 0, 0, 
        0, 0, 0, 1, 0])];
    
    public static var RAD_TO_DEG : Float = 180 / Math.PI;
    public static var DEG_TO_RAD : Float = Math.PI / 180;
    
    public function new()
    {
    }
    
    public static function startsWith(source : String, str : String, ignoreCase : Bool = false) : Bool
    {
        if (source == null) 
            return false;
        else if (source.length < str.length) 
            return false;
        else {
            source = source.substring(0, str.length);
            if (!ignoreCase) 
                return source == str;
            else 
                return source.toLowerCase() == str.toLowerCase();
        }
    }
    
    public static function endsWith(source : String, str : String, ignoreCase : Bool = false) : Bool{
        if (source == null) 
            return false;
        else if (source.length < str.length) 
            return false;
        else {
            source = source.substring(source.length - str.length);
            if (!ignoreCase) 
                return source == str;
            else 
                return source.toLowerCase() == str.toLowerCase();
        }
    }
    
    public static function trim(targetString : String) : String{
        return trimLeft(trimRight(targetString));
    }
    
    public static function trimLeft(targetString : String) : String{
        var tempChar : String = "";
        var i = 0;
        for (i in 0...targetString.length){
            tempChar = targetString.charAt(i);
            if (tempChar != " " && tempChar != "\n" && tempChar != "\r") {
                break;
            }
        }
        return targetString.substr(i);
    }
    
    public static function trimRight(targetString : String) : String{
        var tempChar : String = "";
        var i : Int = targetString.length - 1;
        while (i >= 0){
            tempChar = targetString.charAt(i);
            if (tempChar != " " && tempChar != "\n" && tempChar != "\r") {
                break;
            }
            i--;
        }
        return targetString.substring(0, i + 1);
    }
    
    
    public static function convertToHtmlColor(argb : Int, hasAlpha : Bool = false) : String{
        var alpha : String;
        if (hasAlpha) 
            alpha = Std.string((argb >> 24 & 0xFF));
        else 
            alpha = "";
        var red : String = Std.string((argb >> 16 & 0xFF));
        var green : String = Std.string((argb >> 8 & 0xFF));
        var blue : String = Std.string((argb & 0xFF));
        if (alpha.length == 1) 
            alpha = "0" + alpha;
        if (red.length == 1) 
            red = "0" + red;
        if (green.length == 1) 
            green = "0" + green;
        if (blue.length == 1) 
            blue = "0" + blue;
        return "#" + alpha + red + green + blue;
    }
    
    public static function convertFromHtmlColor(str : String, hasAlpha : Bool = false) : Int{
        if (str.length < 1) 
            return 0;
        
        if (str.charAt(0) == "#") 
            str = str.substr(1);
        
        if (str.length == 8)
        {
            return (Std.parseInt("0x"+str.substr(0, 2)) << 24) + Std.parseInt("0x"+str.substr(2));
        }
        else if (hasAlpha) 
            return 0xFF000000 + Std.parseInt("0x"+str);
        else 
            return Std.parseInt("0x"+str);

        return 0;
    }
    
    public static function encodeHTML(str : String) : String{
        if (str == null) 
            str = "";
        else
        {
            str = StringTools.replace(str, "&", "&amp;");
            str = StringTools.replace(str, "<", "&lt;");
            str = StringTools.replace(str, ">", "&gt;");
            str = StringTools.replace(str, "'", "&apos;");
        }
        return str;
    }
    
    public static var defaultUBBParser : UBBParser = new UBBParser();
    public static function parseUBB(text : String) : String{
        return defaultUBBParser.parse(text);
    }
    
    private static var tileIndice : Array<Dynamic> = [-1, 0, -1, 2, 4, 3, -1, 1, -1];
    public static function scaleBitmapWith9Grid(source : BitmapData, scale9Grid : Rectangle,
            wantWidth : Int, wantHeight : Int, smoothing : Bool = false, tileGridIndice : Int = 0) : BitmapData{
        if (wantWidth == 0 || wantHeight == 0) 
        {
            return new BitmapData(1, 1, source.transparent, 0x00000000);
        }
        
        var bmpData : BitmapData = new BitmapData(wantWidth, wantHeight, source.transparent, 0x00000000);
        
        var rows : Array<Dynamic> = [0, scale9Grid.top, scale9Grid.bottom, source.height];
        var cols : Array<Dynamic> = [0, scale9Grid.left, scale9Grid.right, source.width];
        
        var dRows : Array<Dynamic>;
        var dCols : Array<Dynamic>;
        var tmp : Float;
        if (wantHeight >= (source.height - scale9Grid.height)) 
            dRows = [0, scale9Grid.top, wantHeight - (source.height - scale9Grid.bottom), wantHeight];
        else 
        {
            tmp = scale9Grid.top / (source.height - scale9Grid.bottom);
            tmp = wantHeight * tmp / (1 + tmp);
            dRows = [0, tmp, tmp, wantHeight];
        }
        
        if (wantWidth >= (source.width - scale9Grid.width)) 
            dCols = [0, scale9Grid.left, wantWidth - (source.width - scale9Grid.right), wantWidth];
        else 
        {
            tmp = scale9Grid.left / (source.width - scale9Grid.right);
            tmp = wantWidth * tmp / (1 + tmp);
            dCols = [0, tmp, tmp, wantWidth];
        }
        
        var origin : Rectangle;
        var draw : Rectangle;
        var mat : Matrix = new Matrix();
        
        for (cx in 0...3){
            for (cy in 0...3){
                origin = new Rectangle(cols[cx], rows[cy], cols[cx + 1] - cols[cx], rows[cy + 1] - rows[cy]);
                draw = new Rectangle(dCols[cx], dRows[cy], dCols[cx + 1] - dCols[cx], dRows[cy + 1] - dRows[cy]);
                
                var i : Int = tileIndice[cy * 3 + cx];
                if (i != -1 && (tileGridIndice & (1 << i)) != 0) 
                {
                    var tmp2 : BitmapData = tileBitmap(source, origin, Std.int(draw.width), Std.int(draw.height));
                    bmpData.copyPixels(tmp2, tmp2.rect, draw.topLeft);
                    tmp2.dispose();
                }
                else 
                {
                    mat.identity();
                    mat.a = draw.width / origin.width;
                    mat.d = draw.height / origin.height;
                    mat.tx = draw.x - origin.x * mat.a;
                    mat.ty = draw.y - origin.y * mat.d;
                    bmpData.draw(source, mat, null, null, draw, smoothing);
                }
            }
        }
        return bmpData;
    }
    
    public static function tileBitmap(source : BitmapData, sourceRect : Rectangle,
            wantWidth : Int, wantHeight : Int) : BitmapData
    {
        if (wantWidth == 0 || wantHeight == 0) 
        {
            return new BitmapData(1, 1, source.transparent, 0x00000000);
        }
        
        var result : BitmapData = new BitmapData(wantWidth, wantHeight, source.transparent, 0);
        var hc : Int = Math.ceil(wantWidth / sourceRect.width);
        var vc : Int = Math.ceil(wantHeight / sourceRect.height);
        var pt : Point = new Point();
        for (i in 0...hc)
        {
            for (j in 0...vc)
            {
                pt.x = i * sourceRect.width;
                pt.y = j * sourceRect.height;
                result.copyPixels(source, sourceRect, pt);
            }
        }
        
        return result;
    }
    
    public static function displayObjectToGObject(obj : DisplayObject) : GObject
    {
        while (obj != null && !(Std.is(obj, Stage)))
        {
            if (Std.is(obj, UIDisplayObject)) 
                return cast((obj), UIDisplayObject).owner;
            
            obj = obj.parent;
        }
        return null;
    }
    
    public static function clamp(value : Float, min : Float, max : Float) : Float
    {
        if (value < min) 
            value = min;
        else if (value > max) 
            value = max;
        return value;
    }
    
    public static function clamp01(value : Float) : Float
    {
        if (value > 1) 
            value = 1;
        else if (value < 0) 
            value = 0;
        return value;
    }
}
