package fairygui;

import openfl.errors.Error;

class Relations
{
    public var empty(get, never) : Bool;

    private var _owner : GObject;
    private var _items : Array<RelationItem>;

    public var handling : GObject;
    @:allow(fairygui)
    private var sizeDirty : Bool = false;
    
    private static var RELATION_NAMES : Array<Dynamic> = 
        [
        "left-left",   //0  
        "left-center", 
        "left-right", 
        "center-center", 
        "right-left", 
        "right-center", 
        "right-right", 
        "top-top",   //7  
        "top-middle", 
        "top-bottom", 
        "middle-middle", 
        "bottom-top", 
        "bottom-middle", 
        "bottom-bottom", 
        "width-width",   //14  
        "height-height",   //15  
        "leftext-left",   //16  
        "leftext-right", 
        "rightext-left", 
        "rightext-right", 
        "topext-top",   //20  
        "topext-bottom", 
        "bottomext-top", 
        "bottomext-bottom"  //23
      ];
    
    public function new(owner : GObject)
    {
        _owner = owner;
        _items = new Array<RelationItem>();
    }
    
    public function add(target : GObject, relationType : Int, usePercent : Bool = false) : Void
    {
        for (item in _items)
        {
            if (item.target == target) 
            {
                item.add(relationType, usePercent);
                return;
            }
        }
        var newItem : RelationItem = new RelationItem(_owner);
        newItem.target = target;
        newItem.add(relationType, usePercent);
        _items.push(newItem);
    }
    
    private function addItems(target : GObject, sidePairs : String) : Void
    {
        var arr : Array<Dynamic> = sidePairs.split(",");
        var s : String;
        var usePercent : Bool;
        var i : Int;
        var tid : Int;
        
        var newItem : RelationItem = new RelationItem(_owner);
        newItem.target = target;
        
        for (i in 0...2){
            s = arr[i];
            if (s == null) 
                continue;
            
            if (s.charAt(s.length - 1) == "%") 
            {
                s = s.substr(0, s.length - 1);
                usePercent = true;
            }
            else 
            usePercent = false;
            var j : Int = s.indexOf("-");
            if (j == -1) 
                s = s + "-" + s;
            
            tid = Lambda.indexOf(RELATION_NAMES, s);
            if (tid == -1) 
                throw new Error("invalid relation type");
            
            newItem.internalAdd(tid, usePercent);
        }
        
        _items.push(newItem);
    }
    
    public function remove(target : GObject, relationType : Int) : Void
    {
        var cnt : Int = _items.length;
        var i : Int = 0;
        while (i < cnt)
        {
            var item : RelationItem = _items[i];
            if (item.target == target) 
            {
                item.remove(relationType);
                if (item.isEmpty) 
                {
                    item.dispose();
                    _items.splice(i, 1);
                    cnt--;
                }
                else 
                i++;
            }
            else 
            i++;
        }
    }
    
    public function contains(target : GObject) : Bool
    {
        for (item in _items)
        {
            if (item.target == target) 
                return true;
        }
        return false;
    }
    
    public function clearFor(target : GObject) : Void
    {
        var cnt : Int = _items.length;
        var i : Int = 0;
        while (i < cnt)
        {
            var item : RelationItem = _items[i];
            if (item.target == target) 
            {
                item.dispose();
                _items.splice(i, 1);
                cnt--;
            }
            else 
            i++;
        }
    }
    
    public function clearAll() : Void
    {
        for (item in _items)
        {
            item.dispose();
        }
        _items.splice(0, -1);
    }
    
    public function copyFrom(source : Relations) : Void
    {
        clearAll();
        
        var arr : Array<RelationItem> = source._items;
        for (ri in arr)
        {
            var item : RelationItem = new RelationItem(_owner);
            item.copyFrom(ri);
            _items.push(item);
        }
    }
    
    public function dispose() : Void
    {
        clearAll();
    }
    
    public function onOwnerSizeChanged(dWidth : Float, dHeight : Float) : Void
    {
        if (_items.length == 0) 
            return;
        
        for (item in _items)
        {
            item.applyOnSelfResized(dWidth, dHeight);
        }
    }
    
    public function ensureRelationsSizeCorrect() : Void
    {
        if (_items.length == 0) 
            return;
        
        sizeDirty = false;
        for (item in _items)
        {
            item.target.ensureSizeCorrect();
        }
    }
    
    @:final private function get_empty() : Bool
    {
        return _items.length == 0;
    }
    
    public function setup(xml : FastXML) : Void
    {
        var col : FastXMLList = xml.descendants("relation");
        var targetId : String;
        var target : GObject;
        for (cxml in col.iterator())
        {
            targetId = cxml.att.target;
            if (_owner.parent != null)
            {
                if (targetId != null && targetId != "")
                    target = _owner.parent.getChildById(targetId);
                else 
                    target = _owner.parent;
            }
            else 
            {
                //call from component construction
                target = cast(_owner, GComponent).getChildById(targetId);
            }
            if (target != null) 
                addItems(target, cxml.att.sidePair);
        }
    }
}

