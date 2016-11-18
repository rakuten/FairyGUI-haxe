package fairygui;


class OverflowType
{
    public static inline var Visible : Int = 0;
    public static inline var Hidden : Int = 1;
    public static inline var Scroll : Int = 2;
    public static inline var Scale : Int = 3;
    public static inline var ScaleFree : Int = 4;
    
    public function new()
    {
    }
    
    public static function parse(value : String) : Int
    {
        switch (value)
        {
            case "visible":
                return Visible;
            case "hidden":
                return Hidden;
            case "scroll":
                return Scroll;
            case "scale":
                return Scale;
            case "scaleFree":
                return ScaleFree;
            default:
                return Visible;
        }
    }
}
