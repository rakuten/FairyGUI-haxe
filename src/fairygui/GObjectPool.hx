package fairygui;


class GObjectPool
{
    public var initCallback(get, set) : Dynamic;
    public var count(get, never) : Int;

    private var _pool : Map<String, Array<GObject>>;
    private var _count : Int = 0;
    private var _initCallback : Dynamic;
    
    public function new()
    {
        _pool = new Map<String, Array<GObject>>();
    }
    
    private function get_initCallback() : Dynamic
    {
        return _initCallback;
    }
    
    private function set_initCallback(value : Dynamic) : Dynamic
    {
        _initCallback = value;
        return value;
    }
    
    public function clear() : Void
    {
        for (url in _pool.keys())
        {
            var arr:Array<GObject> = _pool.get(url);
            var cnt : Int = arr.length;
            for (i in 0...cnt){
                arr[i].dispose();
            }
        }
        _pool = new Map<String, Array<GObject>>();
        _count = 0;
    }
    
    private function get_count() : Int
    {
        return _count;
    }
    
    public function getObject(url:String):GObject
    {
        var arr : Array<GObject> = _pool[url];
        if (arr == null) 
        {
            arr = new Array<GObject>();
            _pool[url] = arr;
        }
        
        if (arr.length > 0)
        {
            _count--;
            return arr.shift();
        }
        
        var child : GObject = UIPackage.createObjectFromURL(url);
        if (child != null) 
        {
            if (_initCallback != null) 
                _initCallback(child);
        }
        
        return child;
    }
    
    public function returnObject(obj : GObject) : Void
    {
        var url : String = obj.resourceURL;
        if (url == null) 
            return;
        
        var arr : Array<GObject> = _pool[url];
        if (arr == null) 
            return;
        
        _count++;
        arr.push(obj);
    }
}
