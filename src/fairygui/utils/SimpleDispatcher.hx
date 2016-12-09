package fairygui.utils;


class SimpleDispatcher
{
    private var _elements : Array<Dynamic>;
    private var _enumI : Int = 0;
    
    public var _dispatchingType : Int = 0;
    
    public function new()
    {
        _elements = [];
        _dispatchingType = -1;
    }
    
    public function addListener(type : Int, e : Dynamic) : Void{
        var arr : Array<Dynamic> = _elements[type];
        if (arr == null) {
            arr = [];
            _elements[type] = arr;
            arr.push(e);
        }
        else if (Lambda.indexOf(arr, e) == -1) {
            arr.push(e);
        }
    }
    
    public function removeListener(type : Int, e : Dynamic) : Void{
        var arr : Array<Dynamic> = _elements[type];
        if (arr != null) {
            var i : Int = Lambda.indexOf(arr, e);
            if (i != -1) {
                arr.splice(i, 1);
                if (type == _dispatchingType && i <= _enumI) 
                    _enumI--;
            }
        }
    }
    
    public function hasListener(type : Int) : Bool{
        var arr : Array<Dynamic> = _elements[type];
        if (arr != null && arr.length > 0) 
            return true
        else 
        return false;
    }
    
    public function dispatch(source : Dynamic, type : Int) : Void{
        var arr : Array<Dynamic> = _elements[type];
        if (arr == null || arr.length == 0 || _dispatchingType == type) 
            return;
        
        _enumI = 0;
        _dispatchingType = type;
        while (_enumI < arr.length){
            var e : Dynamic = arr[_enumI];
            if (e.length == 1) 
                e(source)
            else 
            e();
            _enumI++;
        }
        _dispatchingType = -1;
    }
    
    public function clear() : Void{
        _elements.splice(0, -1);
    }
    
    public function copy(source : SimpleDispatcher) : Void{
        _elements = source._elements.concat([]);
    }
}
