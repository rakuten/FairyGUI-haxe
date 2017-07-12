package fairygui;


class ChildrenRenderOrder
{
    public static inline var Ascent : Int = 0;
    public static inline var Descent : Int = 1;
    public static inline var Arch : Int = 2;
    
    public function new()
    {
    }

    public static function parse(value:String):Int
    {
        switch (value)
        {
            case "ascent":
                return Ascent;
            case "descent":
                return Descent;
            case "arch":
                return Arch;
            default:
                return Ascent;
        }
    }

}
