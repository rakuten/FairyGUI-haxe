package fairygui;


class VertAlignType
{
    public static inline var Top : Int = 0;
    public static inline var Middle : Int = 1;
    public static inline var Bottom : Int = 2;
    
    public function new()
    {
    }
    
    public static function parse(value : String) : Int
    {
        switch (value)
        {
            case "top":
                return Top;
            case "middle":
                return Middle;
            case "bottom":
                return Bottom;
            default:
                return Top;
        }
    }
}
