package fairygui;


import openfl.text.TextFormatAlign;

class AlignType
{
    public static inline var Left : Int = 0;
    public static inline var Center : Int = 1;
    public static inline var Right : Int = 2;
    
    public function new()
    {
    }
    
    public static function parse(value : String) : Int
    {
        switch (value)
        {
            case "left":
                return Left;
            case "center":
                return Center;
            case "right":
                return Right;
            default:
                return Left;
        }
    }
    
    public static function toString(type : Int) : String
    {
        return (type == Left) ? TextFormatAlign.LEFT : 
        ((type == Center) ? TextFormatAlign.CENTER : TextFormatAlign.RIGHT);
    }
}
