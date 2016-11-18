package fairygui;


class ListSelectionMode
{
    public static inline var Single : Int = 0;
    public static inline var Multiple : Int = 1;
    public static inline var Multiple_SingleClick : Int = 2;
    public static inline var None : Int = 3;
    
    public function new()
    {
    }
    
    public static function parse(value : String) : Int
    {
        switch (value)
        {
            case "single":
                return Single;
            case "multiple":
                return Multiple;
            case "multipleSingleClick":
                return Multiple_SingleClick;
            case "none":
                return None;
            default:
                return Single;
        }
    }
}
