package fairygui;


class AutoSizeType
{
    public static inline var None : Int = 0;
    public static inline var Both : Int = 1;
    public static inline var Height : Int = 2;
    public static inline var Shrink : Int = 3;
    
    public function new()
    {
    }
    
    public static function parse(value : String) : Int
    {
        switch (value)
        {
            case "none":
                return None;
            case "both":
                return Both;
            case "height":
                return Height;
            case "shrink":
                return Shrink;
            default:
                return None;
        }
    }
}
