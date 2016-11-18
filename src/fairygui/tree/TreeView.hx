package fairygui.tree;


import openfl.events.Event;

import fairygui.GButton;
import fairygui.GList;
import fairygui.GObject;
import fairygui.event.ItemEvent;

class TreeView
{
    public var list(get, never) : GList;
    public var root(get, never) : TreeNode;
    public var indent(get, set) : Int;
    public var listener(get, set) : ITreeListener;

    private var _list : GList;
    private var _root : TreeNode;
    private var _listener : ITreeListener;
    private var _indent : Int;
    
    public function new(list : GList)
    {
        _list = list;
        _list.addEventListener(ItemEvent.CLICK, __clickItem);
        
        _root = new TreeNode(true);
        _root.setTree(this);
        _root.setCell(_list);
        _root.expanded = true;
        
        _indent = 15;
    }
    
    @:final private function get_list() : GList
    {
        return _list;
    }
    
    @:final private function get_root() : TreeNode
    {
        return _root;
    }
    
    @:final private function get_indent() : Int
    {
        return _indent;
    }
    
    @:final private function set_indent(value : Int) : Int
    {
        _indent = value;
        return value;
    }
    
    @:final private function get_listener() : ITreeListener
    {
        return _listener;
    }
    
    @:final private function set_listener(value : ITreeListener) : ITreeListener
    {
        _listener = value;
        return value;
    }
    
    public function getSelectedNode() : TreeNode
    {
        if (_list.selectedIndex != -1) 
            return cast((_list.getChildAt(_list.selectedIndex).data), TreeNode)
        else 
        return null;
    }
    
    public function getSelection() : Array<TreeNode>
    {
        var sels : Array<Int> = _list.getSelection();
        var cnt : Int = sels.length;
        var ret : Array<TreeNode> = new Array<TreeNode>();
        for (i in 0...cnt){
            var node : TreeNode = cast((_list.getChildAt(sels[i]).data), TreeNode);
            ret.push(node);
        }
        return ret;
    }
    
    public function addSelection(node : TreeNode, scrollItToView : Bool = false) : Void
    {
        var parentNode : TreeNode = node.parent;
        while (parentNode != null && parentNode != _root)
        {
            parentNode.expanded = true;
            parentNode = parentNode.parent;
        }
        _list.addSelection(_list.getChildIndex(node.cell), scrollItToView);
    }
    
    public function removeSelection(node : TreeNode) : Void
    {
        _list.removeSelection(_list.getChildIndex(node.cell));
    }
    
    public function clearSelection() : Void
    {
        _list.clearSelection();
    }
    
    public function getNodeIndex(node : TreeNode) : Int
    {
        return _list.getChildIndex(node.cell);
    }
    
    public function updateNode(node : TreeNode) : Void
    {
        if (node.cell == null) 
            return;
        
        _listener.treeNodeRender(node, node.cell);
    }
    
    public function updateNodes(nodes : Array<TreeNode>) : Void
    {
        var cnt : Int = nodes.length;
        for (i in 0...cnt){
            var node : TreeNode = nodes[i];
            if (node.cell == null) 
                return;
            
            _listener.treeNodeRender(node, node.cell);
        }
    }
    
    public function expandAll(folderNode : TreeNode) : Void
    {
        folderNode.expanded = true;
        var cnt : Int = folderNode.numChildren;
        for (i in 0...cnt){
            var node : TreeNode = folderNode.getChildAt(i);
            if (node.isFolder) 
                expandAll(node);
        }
    }
    
    public function collapseAll(folderNode : TreeNode) : Void
    {
        if (folderNode != _root) 
            folderNode.expanded = false;
        var cnt : Int = folderNode.numChildren;
        for (i in 0...cnt){
            var node : TreeNode = folderNode.getChildAt(i);
            if (node.isFolder) 
                collapseAll(node);
        }
    }
    
    private function createCell(node : TreeNode) : Void
    {
        node.setCell(_listener.treeNodeCreateCell(node));
        node.cell.data = node;
        
        var indentObj : GObject = node.cell.getChild("indent");
        if (indentObj != null) 
            indentObj.width = (node.level - 1) * _indent;
        
        var expandButton : GButton = cast((node.cell.getChild("expandButton")), GButton);
        if (expandButton != null) 
        {
            if (node.isFolder) 
            {
                expandButton.visible = true;
                expandButton.addClickListener(__clickExpandButton);
                expandButton.data = node;
                expandButton.selected = node.expanded;
            }
            else 
            expandButton.visible = false;
        }
        
        _listener.treeNodeRender(node, node.cell);
    }
    
    @:allow(fairygui.tree)
    private function afterInserted(node : TreeNode) : Void
    {
        createCell(node);
        
        var index : Int = getInsertIndexForNode(node);
        _list.addChildAt(node.cell, index);
        _listener.treeNodeRender(node, node.cell);
        
        if (node.isFolder && node.expanded) 
            checkChildren(node, index);
    }
    
    private function getInsertIndexForNode(node : TreeNode) : Int
    {
        var prevNode : TreeNode = node.getPrevSibling();
        if (prevNode == null) 
            prevNode = node.parent;
        var insertIndex : Int = _list.getChildIndex(prevNode.cell) + 1;
        var myLevel : Int = node.level;
        var cnt : Int = _list.numChildren;
        for (i in insertIndex...cnt){
            var testNode : TreeNode = cast((_list.getChildAt(i).data), TreeNode);
            if (testNode.level <= myLevel) 
                break;
            
            insertIndex++;
        }
        
        return insertIndex;
    }
    
    @:allow(fairygui.tree)
    private function afterRemoved(node : TreeNode) : Void
    {
        removeNode(node);
    }
    
    @:allow(fairygui.tree)
    private function afterExpanded(node : TreeNode) : Void
    {
        if (node != _root) 
            _listener.treeNodeWillExpand(node, true);
        
        if (node.cell == null) 
            return;
        
        if (node != _root) 
        {
            _listener.treeNodeRender(node, node.cell);
            
            var expandButton : GButton = cast((node.cell.getChild("expandButton")), GButton);
            if (expandButton != null) 
                expandButton.selected = true;
        }
        
        if (node.cell.parent != null) 
            checkChildren(node, _list.getChildIndex(node.cell));
    }
    
    @:allow(fairygui.tree)
    private function afterCollapsed(node : TreeNode) : Void
    {
        if (node != _root) 
            _listener.treeNodeWillExpand(node, false);
        
        if (node.cell == null) 
            return;
        
        if (node != _root) 
        {
            _listener.treeNodeRender(node, node.cell);
            
            var expandButton : GButton = cast((node.cell.getChild("expandButton")), GButton);
            if (expandButton != null) 
                expandButton.selected = false;
        }
        
        if (node.cell.parent != null) 
            hideFolderNode(node);
    }
    
    @:allow(fairygui.tree)
    private function afterMoved(node : TreeNode) : Void
    {
        if (!node.isFolder) 
            _list.removeChild(node.cell)
        else 
        hideFolderNode(node);
        
        var index : Int = getInsertIndexForNode(node);
        _list.addChildAt(node.cell, index);
        
        if (node.isFolder && node.expanded) 
            checkChildren(node, index);
    }
    
    private function checkChildren(folderNode : TreeNode, index : Int) : Int
    {
        var cnt : Int = folderNode.numChildren;
        for (i in 0...cnt){
            index++;
            var node : TreeNode = folderNode.getChildAt(i);
            if (node.cell == null) 
                createCell(node);
            
            if (!node.cell.parent) 
                _list.addChildAt(node.cell, index);
            
            if (node.isFolder && node.expanded) 
                index = checkChildren(node, index);
        }
        
        return index;
    }
    
    private function hideFolderNode(folderNode : TreeNode) : Void
    {
        var cnt : Int = folderNode.numChildren;
        for (i in 0...cnt){
            var node : TreeNode = folderNode.getChildAt(i);
            if (node.cell && node.cell.parent != null) 
                _list.removeChild(node.cell);
            if (node.isFolder && node.expanded) 
                hideFolderNode(node);
        }
    }
    
    private function removeNode(node : TreeNode) : Void
    {
        if (node.cell != null) 
        {
            if (node.cell.parent != null) 
                _list.removeChild(node.cell);
            _list.returnToPool(node.cell);
            node.cell.data = null;
            node.setCell(null);
        }
        
        if (node.isFolder) 
        {
            var cnt : Int = node.numChildren;
            for (i in 0...cnt){
                var node2 : TreeNode = node.getChildAt(i);
                removeNode(node2);
            }
        }
    }
    
    private function __clickExpandButton(evt : Event) : Void
    {
        var expandButton : GButton = cast((evt.currentTarget), GButton);
        var node : TreeNode = cast((expandButton.parent.data), TreeNode);
        if (_list.scrollPane != null) 
        {
            var posY : Float = _list.scrollPane.posY;
            if (expandButton.selected) 
                node.expanded = true
            else 
            node.expanded = false;
            _list.scrollPane.posY = posY;
            _list.scrollPane.scrollToView(node.cell);
        }
        else 
        {
            if (expandButton.selected) 
                node.expanded = true
            else 
            node.expanded = false;
        }
    }
    
    private function __clickItem(evt : ItemEvent) : Void
    {
        if (_list.scrollPane != null) 
            var posY : Float = _list.scrollPane.posY;
        
        var node : TreeNode = cast((evt.itemObject.data), TreeNode);
        _listener.treeNodeClick(node, evt);
        
        if (_list.scrollPane != null) 
        {
            _list.scrollPane.posY = posY;
            _list.scrollPane.scrollToView(node.cell);
        }
    }
}

