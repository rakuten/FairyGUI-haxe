package fairygui.tree;

import fairygui.tree.TreeNode;

import fairygui.GComponent;
import fairygui.event.ItemEvent;

interface ITreeListener
{

    function treeNodeCreateCell(node : TreeNode) : GComponent;
    function treeNodeRender(node : TreeNode, obj : GComponent) : Void;
    function treeNodeWillExpand(node : TreeNode, expand : Bool) : Void;
    function treeNodeClick(node : TreeNode, evt : ItemEvent) : Void;
}
