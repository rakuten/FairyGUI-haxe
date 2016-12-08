package fairygui;

import openfl.Lib;
import fairygui.DisplayListItem;
import fairygui.GObject;
import fairygui.PackageItem;
import fairygui.UIPackage;
import openfl.errors.Error;



import fairygui.utils.GTimers;

class AsyncOperation
{
    /**
		 * callback(obj:GObject)
		 */
    public var callback : Dynamic;
    
    private var _itemList : Array<DisplayListItem>;
    private var _objectPool : Array<GObject>;
    private var _index : Int;
    
    public function new()
    {
        _itemList = new Array<DisplayListItem>();
        _objectPool = new Array<GObject>();
    }

    public function createObject(pkgName : String, resName : String) : Void
    {
        var pkg : UIPackage = UIPackage.getByName(pkgName);
        if (pkg != null) 
        {
            var pi : PackageItem = pkg.getItemByName(resName);
            if (pi == null) 
                throw new Error("resource not found: " + resName);

            internalCreateObject(pi);
        }
        else 
        throw new Error("package not found: " + pkgName);
    }
    
    public function createObjectFromURL(url : String) : Void
    {
        var pi : PackageItem = UIPackage.getItemByURL(url);
        if (pi != null)
            internalCreateObject(pi);
        else 
        throw new Error("resource not found: " + url);
    }
    
    public function cancel() : Void
    {
        GTimers.inst.remove(run);
        _itemList.splice(0, -1);
        if(_objectPool.length>0)
        {
            for (obj in _objectPool)
            {
                obj.dispose();
            }
            _itemList.splice(0, -1);
        }

    }

    private function internalCreateObject(item:PackageItem):Void
    {
        _itemList.splice(0, -1);
        _objectPool.splice(0, -1);
        
        collectComponentChildren(item);
        _itemList.push(new DisplayListItem(item, null));
        
        _index = 0;
        GTimers.inst.add(1, 0, run);
    }
    
    private function collectComponentChildren(item : PackageItem) : Void
    {
        item.owner.getComponentData(item);
        
        var cnt : Int = item.displayList.length;
        for (i in 0...cnt){
            var di : DisplayListItem = item.displayList[i];
            if (di.packageItem != null && di.packageItem.type == PackageItemType.Component) 
                collectComponentChildren(di.packageItem)
            else if (di.type == "list")   //也要收集列表的item  
            {
                var defaultItem : String = null;
                di.listItemCount = 0;
                var col : FastXMLList = di.desc.item;
                for (cxml in col)
                {
                    var url : String = cxml.att.url;
                    if (url == null) 
                    {
                        if (defaultItem == null) 
                            defaultItem = di.desc.att.defaultItem;
                        url = defaultItem;
                        if (url == null) 
                            continue;
                    }
                    
                    var pi : PackageItem = UIPackage.getItemByURL(url);
                    if (pi != null) 
                    {
                        if (pi.type == PackageItemType.Component) 
                            collectComponentChildren(pi);
                        
                        _itemList.push(new DisplayListItem(pi, null));
                        di.listItemCount++;
                    }
                }
            }
            _itemList.push(di);
        }
    }
    
    private function run() : Void
    {
        var obj : GObject;
        var di : DisplayListItem;
        var poolStart : Int;
        var k : Int;
        var t : Int = Lib.getTimer();
        var frameTime : Int = UIConfig.frameTimeForAsyncUIConstruction;
        var totalItems : Int = _itemList.length;
        
        while (_index < totalItems)
        {
            di = _itemList[_index];
            if (di.packageItem != null) 
            {
                obj = UIObjectFactory.newObject(di.packageItem);
                obj.packageItem = di.packageItem;
                _objectPool.push(obj);
                
                UIPackage._constructing++;
                if (di.packageItem.type == PackageItemType.Component) 
                {
                    poolStart = _objectPool.length - di.packageItem.displayList.length - 1;
                    
                    cast((obj), GComponent).constructFromResource2(_objectPool, poolStart);
                    
                    _objectPool.splice(poolStart, di.packageItem.displayList.length);
                }
                else 
                {
                    obj.constructFromResource();
                }
                UIPackage._constructing--;
            }
            else 
            {
                obj = UIObjectFactory.newObject2(di.type);
                _objectPool.push(obj);
                
                if (di.type == "list" && di.listItemCount > 0) 
                {
                    poolStart = _objectPool.length - di.listItemCount - 1;
                    
                    for (k in 0...di.listItemCount){  //把他们都放到pool里，这样GList在创建时就不需要创建对象了  
                        cast((obj), GList).itemPool.returnObject(_objectPool[k + poolStart]);
                    }
                    
                    _objectPool.splice(poolStart, di.listItemCount);
                }
            }
            
            _index++;
            if ((_index % 5 == 0) && Lib.getTimer() - t >= frameTime)
                return;
        }
        
        GTimers.inst.remove(run);
        var result : GObject = _objectPool[0];
        _itemList.splice(0, -1);
        _objectPool.splice(0, -1);
        
        if (callback != null) 
            callback(result);
    }
}
