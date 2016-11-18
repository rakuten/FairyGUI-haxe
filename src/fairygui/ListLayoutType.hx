package fairygui;


class ListLayoutType
{
    public static inline var SingleColumn : Int = 0;
    public static inline var SingleRow : Int = 1;
    public static inline var FlowHorizontal : Int = 2;
    public static inline var FlowVertical : Int = 3;
    public static inline var Pagination : Int = 4;
    
    public function new()
    {
    }
    
    public static function parse(value : String) : Int
    {
        switch (value)
        {
            case "column":
                return SingleColumn;
            case "row":
                return SingleRow;
            case "flow_hz":
                return FlowHorizontal;
            case "flow_vt":
                return FlowVertical;
            case "pagination":
                return Pagination;
            default:
                return SingleColumn;
        }
    }
}
