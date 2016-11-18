package fairygui;


class PackageItemType
{
    public static inline var Image : Int = 0;
    public static inline var Swf : Int = 1;
    public static inline var MovieClip : Int = 2;
    public static inline var Sound : Int = 3;
    public static inline var Component : Int = 4;
    public static inline var Misc : Int = 5;
    public static inline var Font : Int = 6;
    
    public function new()
    {
    }
    
    public static function parseType(value : String) : Int
    {
        switch (value)
        {
            case "image":
                return Image;
            case "movieclip":
                return MovieClip;
            case "sound":
                return Sound;
            case "component":
                return Component;
            case "swf":
                return Swf;
            case "font":
                return Font;
        }
        return 0;
    }
}

