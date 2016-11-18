package fairygui;


class ScrollBarDisplayType
{
    public static inline var Default : Int = 0;
    public static inline var Visible : Int = 1;
    public static inline var Auto : Int = 2;
    public static inline var Hidden : Int = 3;
    
    public function new()
    {
    }
    
    public static function parse(value : String) : Int
    {
        switch (value)
        {
            case "default":
                return Default;
            case "visible":
                return Visible;
            case "auto":
                return Auto;
            case "hidden":
                return Hidden;
            default:
                return Default;
        }
    }
}
