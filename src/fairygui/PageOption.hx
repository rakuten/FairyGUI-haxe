package fairygui;


class PageOption
{
    public var controller(never, set) : Controller;
    public var index(get, set) : Int;
    public var name(get, set) : String;
    public var id(get, set) : String;

    private var _controller : Controller;
    private var _id : String;
    
    public function new()
    {
    }
    
    private function set_controller(val : Controller) : Controller
    {
        _controller = val;
        return val;
    }
    
    private function set_index(pageIndex : Int) : Int
    {
        _id = _controller.getPageId(pageIndex);
        return pageIndex;
    }
    
    private function set_name(pageName : String) : String
    {
        _id = _controller.getPageIdByName(pageName);
        return pageName;
    }
    
    private function get_index() : Int
    {
        if (_id != null) 
            return _controller.getPageIndexById(_id);
        else 
        return -1;
    }
    
    private function get_name() : String
    {
        if (_id != null) 
            return _controller.getPageNameById(_id);
        else 
        return null;
    }
    
    public function clear() : Void
    {
        _id = null;
    }
    
    private function set_id(id : String) : String
    {
        _id = id;
        return id;
    }
    
    private function get_id() : String
    {
        return _id;
    }
}
