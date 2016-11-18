package fairygui;


class FlipType
{
    public static inline var None : Int = 0;
    public static inline var Horizontal : Int = 1;
    public static inline var Vertical : Int = 2;
    public static inline var Both : Int = 3;
    
    public function new()
    {
    }
    
    public static function parse(value : String) : Int
    {
        switch (value)
        {
            case "hz":
                return FlipType.Horizontal;
            case "vt":
                return FlipType.Vertical;
            case "both":
                return FlipType.Both;
            default:
                return FlipType.None;
        }
    }
}
