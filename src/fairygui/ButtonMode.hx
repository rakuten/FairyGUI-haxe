package fairygui;


class ButtonMode
{
    public static inline var Common : Int = 0;
    public static inline var Check : Int = 1;
    public static inline var Radio : Int = 2;
    
    public function new()
    {
    }
    
    public static function parse(value : String) : Int
    {
        switch (value)
        {
            case "Common":
                return Common;
            case "Check":
                return Check;
            case "Radio":
                return Radio;
            default:
                return Common;
        }
    }
}
