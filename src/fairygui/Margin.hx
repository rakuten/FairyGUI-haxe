package fairygui;


class Margin
{
    public var left : Int;
    public var right : Int;
    public var top : Int;
    public var bottom : Int;
    
    public function new()
    {
    }
    
    public function parse(str : String) : Void
    {
        var arr : Array<Dynamic> = str.split(",");
        if (arr.length == 1) 
        {
            var k : Int = Std.parseInt(arr[0]);
            top = k;
            bottom = k;
            left = k;
            right = k;
        }
        else 
        {
            top = Std.parseInt(arr[0]);
            bottom = Std.parseInt(arr[1]);
            left = Std.parseInt(arr[2]);
            right = Std.parseInt(arr[3]);
        }
    }
    
    public function copy(source : Margin) : Void
    {
        top = source.top;
        bottom = source.bottom;
        left = source.left;
        right = source.right;
    }
}
