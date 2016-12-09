package fairygui.tree;

import fairygui.tree.TreeView;
import openfl.errors.ArgumentError;
import openfl.errors.Error;
import openfl.errors.RangeError;

import fairygui.GComponent;

class TreeNode
{
    public var expanded(get, set) : Bool;
    public var isFolder(get, never) : Bool;
    public var parent(get, never) : TreeNode;
    public var data(get, set) : Dynamic;
    public var text(get, never) : String;
    public var cell(get, never) : GComponent;
    public var level(get, never) : Int;
    public var numChildren(get, never) : Int;

    private var _data : Dynamic;
    
    private var _parent : TreeNode;
    private var _children : Array<TreeNode>;
    private var _expanded : Bool = false;
    private var _tree : TreeView;
    private var _cell : GComponent;
    private var _level : Int = 0;
    
    public function new(hasChild : Bool)
    {
        if (hasChild) 
            _children = new Array<TreeNode>();
    }
    
    @:final private function set_expanded(value : Bool) : Bool
    {
        if (_children == null) 
            return;
        
        if (_expanded != value) 
        {
            _expanded = value;
            if (_tree != null) 
            {
                if (_expanded) 
                    _tree.afterExpanded(this)
                else 
                _tree.afterCollapsed(this);
            }
        }
        return value;
    }
    
    @:final private function get_expanded() : Bool
    {
        return _expanded;
    }
    
    @:final private function get_isFolder() : Bool
    {
        return _children != null;
    }
    
    @:final private function get_parent() : TreeNode
    {
        return _parent;
    }
    
    @:final private function set_data(value : Dynamic) : Dynamic
    {
        _data = value;
        return value;
    }
    
    @:final private function get_data() : Dynamic
    {
        return _data;
    }
    
    @:final private function get_text() : String
    {
        if (_cell != null) 
            return _cell.text
        else 
        return null;
    }
    
    @:final private function get_cell() : GComponent
    {
        return _cell;
    }
    
    @:allow(fairygui.tree)
    private function setCell(value : GComponent) : Void
    {
        _cell = value;
    }
    
    @:final private function get_level() : Int
    {
        return _level;
    }
    
    @:allow(fairygui.tree)
    private function setLevel(value : Int) : Void
    {
        _level = value;
    }
    
    public function addChild(child : TreeNode) : TreeNode
    {
        addChildAt(child, _children.length);
        return child;
    }
    
    public function addChildAt(child : TreeNode, index : Int) : TreeNode
    {
        if (child == null) 
            throw new Error("child is null");
        
        var numChildren : Int = _children.length;
        
        if (index >= 0 && index <= numChildren) 
        {
            if (child._parent == this) 
            {
                setChildIndex(child, index);
            }
            else 
            {
                if (child._parent) 
                    child._parent.removeChild(child);
                
                var cnt : Int = _children.length;
                if (index == cnt) 
                    _children.push(child)
                else 
                _children.splice(index, 0, child);
                
                child._parent = this;
                child._level = this._level + 1;
                child.setTree(_tree);
                if (this._cell != null && this._cell.parent != null && _expanded) 
                    _tree.afterInserted(child);
            }
            
            return child;
        }
        else 
        {
            throw new RangeError("Invalid child index");
        }
    }
    
    public function removeChild(child : TreeNode) : TreeNode
    {
        var childIndex : Int = Lambda.indexOf(_children, child);
        if (childIndex != -1) 
        {
            removeChildAt(childIndex);
        }
        return child;
    }
    
    public function removeChildAt(index : Int) : TreeNode
    {
        if (index >= 0 && index < numChildren) 
        {
            var child : TreeNode = _children[index];
            _children.splice(index, 1);
            
            child._parent = null;
            if (_tree != null) 
            {
                child.setTree(null);
                _tree.afterRemoved(child);
            }
            
            return child;
        }
        else 
        {
            throw new RangeError("Invalid child index");
        }
    }
    
    public function removeChildren(beginIndex : Int = 0, endIndex : Int = -1) : Void
    {
        if (endIndex < 0 || endIndex >= numChildren) 
            endIndex = numChildren - 1;
        
        for (i in beginIndex...endIndex + 1){removeChildAt(beginIndex);
        }
    }
    
    public function getChildAt(index : Int) : TreeNode
    {
        if (index >= 0 && index < numChildren) 
            return _children[index]
        else 
        throw new RangeError("Invalid child index");
    }
    
    public function getChildIndex(child : TreeNode) : Int
    {
        return Lambda.indexOf(_children, child);
    }
    
    public function getPrevSibling() : TreeNode
    {
        if (_parent == null) 
            return null;
        
        var i : Int = _parent._children.indexOf(this);
        if (i <= 0) 
            return null;
        
        return _parent._children[i - 1];
    }
    
    public function getNextSibling() : TreeNode
    {
        if (_parent == null) 
            return null;
        
        var i : Int = _parent._children.indexOf(this);
        if (i < 0 || i >= _parent._children.length - 1) 
            return null;
        
        return _parent._children[i + 1];
    }
    
    public function setChildIndex(child : TreeNode, index : Int) : Void
    {
        var oldIndex : Int = Lambda.indexOf(_children, child);
        if (oldIndex == -1) 
            throw new ArgumentError("Not a child of this container");
        
        var cnt : Int = _children.length;
        if (index < 0) 
            index = 0
        else if (index > cnt) 
            index = cnt;
        
        if (oldIndex == index) 
            return;
        
        _children.splice(oldIndex, 1);
        _children.splice(index, 0, child);
        if (this._cell != null && this._cell.parent != null && _expanded) 
            _tree.afterMoved(child);
    }
    
    public function swapChildren(child1 : TreeNode, child2 : TreeNode) : Void
    {
        var index1 : Int = Lambda.indexOf(_children, child1);
        var index2 : Int = Lambda.indexOf(_children, child2);
        if (index1 == -1 || index2 == -1) 
            throw new ArgumentError("Not a child of this container");
        swapChildrenAt(index1, index2);
    }
    
    public function swapChildrenAt(index1 : Int, index2 : Int) : Void
    {
        var child1 : TreeNode = _children[index1];
        var child2 : TreeNode = _children[index2];
        
        setChildIndex(child1, index2);
        setChildIndex(child2, index1);
    }
    
    @:final private function get_numChildren() : Int
    {
        return _children.length;
    }
    
    @:allow(fairygui.tree)
    private function setTree(value : TreeView) : Void
    {
        _tree = value;
        if (_tree != null && _tree.listener != null && _expanded) 
            _tree.listener.treeNodeWillExpand(this, true);
        
        if (_children != null) 
        {
            var cnt : Int = _children.length;
            for (i in 0...cnt){
                var node : TreeNode = _children[i];
                node._level = _level + 1;
                node.setTree(value);
            }
        }
    }
}
