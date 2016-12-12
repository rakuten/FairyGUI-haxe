package fairygui.utils;


import Reflect;
class SimpleDispatcher
{
    private var _elements : Array<Dynamic>;
    private var _dispatching:Int = 0;

    public function new()
    {
        _elements = [];
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
            if(i!=-1)
                arr[i] = null;
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
        if (arr == null || arr.length == 0)
            return;

        var hasDeleted:Bool = false;
        var i:Int = 0;
        _dispatching++;
        var e:Dynamic;
        while(i<arr.length)
        {
            e = arr[i];
            if(e!=null)
            {
                if(Reflect.field(e,"length")==1)
                    e(source);
                else
                    e();
            }
            else
                hasDeleted = true;
            i++;
        }
        _dispatching--;

        if(hasDeleted && _dispatching==0)
        {
            i = 0;
            while(i<arr.length)
            {
                e = arr[i];
                if(e==null)
                    arr.splice(i, 1);
                else
                    i++;
            }
        }
    }
    
    public function clear() : Void{
        _elements.splice(0, -1);
    }

}
