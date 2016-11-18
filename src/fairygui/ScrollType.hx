package fairygui;


class ScrollType
{
    public static inline var Horizontal : Int = 0;
    public static inline var Vertical : Int = 1;
    public static inline var Both : Int = 2;
    
    public function new()
    {
    }
    
    public static function parse(value : String) : Int
    {
        switch (value)
        {
            case "horizontal":
                return Horizontal;
            case "vertical":
                return Vertical;
            case "both":
                return Both;
            default:
                return Vertical;
        }
    }
}
