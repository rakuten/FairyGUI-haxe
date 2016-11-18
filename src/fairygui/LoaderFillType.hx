package fairygui;


class LoaderFillType
{
    public static inline var None : Int = 0;
    public static inline var Scale : Int = 1;
    public static inline var ScaleMatchHeight : Int = 2;
    public static inline var ScaleMatchWidth : Int = 3;
    public static inline var ScaleFree : Int = 4;
    
    public function new()
    {
    }
    
    public static function parse(value : String) : Int
    {
        switch (value)
        {
            case "none":
                return None;
            case "scale":
                return Scale;
            case "scaleMatchHeight":
                return ScaleMatchHeight;
            case "scaleMatchWidth":
                return ScaleMatchWidth;
            case "scaleFree":
                return ScaleFree;
            default:
                return None;
        }
    }
}
