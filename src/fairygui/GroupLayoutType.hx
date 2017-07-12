package fairygui;
class GroupLayoutType
{
    public static var None:Int = 0;
    public static var Horizontal:Int = 1;
    public static var Vertical:Int = 2;

    public function new()
    {

    }

    public static function parse(value:String):Int
    {
        switch (value)
        {
            case "none":
                return None;
            case "hz":
                return Horizontal;
            case "vt":
                return Vertical;
            default:
                return None;
        }
    }

}
