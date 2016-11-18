package fairygui;


class ProgressTitleType
{
    public static inline var Percent : Int = 0;
    public static inline var ValueAndMax : Int = 1;
    public static inline var Value : Int = 2;
    public static inline var Max : Int = 3;
    
    public function new()
    {
    }
    
    public static function parse(value : String) : Int
    {
        switch (value)
        {
            case "percent":
                return Percent;
            case "valueAndmax":
                return ValueAndMax;
            case "value":
                return Value;
            case "max":
                return Max;
            default:
                return Percent;
        }
    }
}


