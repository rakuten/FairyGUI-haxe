package fairygui;

import fairygui.GGroup;
import fairygui.GObject;
import fairygui.Margin;
import fairygui.ScrollPane;
import fairygui.Transition;
import fairygui.utils.CompatUtil;
import openfl.errors.ArgumentError;
import openfl.errors.Error;
import openfl.errors.RangeError;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Graphics;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Point;

import fairygui.display.UISprite;
import fairygui.utils.GTimers;

@:meta(Event(name="dropEvent",type="fairygui.event.DropEvent"))

class GComponent extends GObject
{
    public var displayListContainer(get, never) : DisplayObjectContainer;
    public var numChildren(get, never) : Int;
    public var controllers(get, never) : Array<Controller>;
    public var scrollPane(get, never) : ScrollPane;
    public var opaque(get, set) : Bool;
    public var margin(get, set) : Margin;
    public var childrenRenderOrder(get, set) : Int;
    public var apexIndex(get, set) : Int;
    public var mask(get, set) : DisplayObject;
    public var viewWidth(get, set) : Int;
    public var viewHeight(get, set) : Int;

    private var _sortingChildCount : Int;
    private var _opaque : Bool;
    
    private var _margin : Margin;
    private var _trackBounds : Bool;
    private var _clipMask : Shape;
    private var _boundsChanged : Bool;
    
    @:allow(fairygui)
    private var _buildingDisplayList : Bool;
    @:allow(fairygui)
    private var _children : Array<GObject>;
    @:allow(fairygui)
    private var _controllers : Array<Controller>;
    @:allow(fairygui)
    private var _transitions : Array<Transition>;
    @:allow(fairygui)
    private var _rootContainer : Sprite;
    @:allow(fairygui)
    private var _container : Sprite;
    @:allow(fairygui)
    private var _scrollPane : ScrollPane;
    @:allow(fairygui)
    private var _alignOffset : Point;
    
    private var _childrenRenderOrder : Int;
    private var _apexIndex : Int;
    
    public function new()
    {
        super();
        _children = new Array<GObject>();
        _controllers = new Array<Controller>();
        _transitions = new Array<Transition>();
        _margin = new Margin();
        _alignOffset = new Point();
    }
    
    override private function createDisplayObject() : Void
    {
        _rootContainer = new UISprite(this);
        _rootContainer.mouseEnabled = false;
        setDisplayObject(_rootContainer);
        _container = _rootContainer;
    }
    
    override public function dispose() : Void
    {
        var i : Int;
        
        var transCnt : Int = _transitions.length;
        for (i in 0...transCnt){
            var trans : Transition = _transitions[i];
            trans.dispose();
        }
        
        var numChildren : Int = _children.length;
        i = numChildren - 1;
        while (i >= 0){
            var obj : GObject = _children[i];
            obj.parent = null;  //avoid removeFromParent call  
            obj.dispose();
            --i;
        }
        
        _boundsChanged = false;
        super.dispose();
    }
    
    @:final private function get_displayListContainer() : DisplayObjectContainer
    {
        return _container;
    }
    
    public function addChild(child : GObject) : GObject
    {
        addChildAt(child, _children.length);
        return child;
    }
    
    public function addChildAt(child : GObject, index : Int) : GObject
    {
        if (child == null) 
            throw new Error("child is null");
        
        var numChildren : Int = _children.length;
        
        if (index >= 0 && index <= numChildren) 
        {
            if (child.parent == this) 
            {
                setChildIndex(child, index);
            }
            else 
            {
                child.removeFromParent();
                child.parent = this;
                
                var cnt : Int = _children.length;
                if (child.sortingOrder != 0) 
                {
                    _sortingChildCount++;
                    index = getInsertPosForSortingChild(child);
                }
                else if (_sortingChildCount > 0) 
                {
                    if (index > (cnt - _sortingChildCount)) 
                        index = cnt - _sortingChildCount;
                }
                
                if (index == cnt)
                    _children.push(child);
                else
                    _children.insert(index+1, child);
                
                childStateChanged(child);
                setBoundsChangedFlag();
            }
            
            return child;
        }
        else 
        {
            throw new RangeError("Invalid child index");
        }
    }
    
    private function getInsertPosForSortingChild(target : GObject) : Int
    {
        var cnt : Int = _children.length;
        var i : Int = 0;
        for (i in 0...cnt){
            var child : GObject = _children[i];
            if (child == target) 
                continue;
            
            if (target.sortingOrder < child.sortingOrder) 
                break;
        }
        return i;
    }
    
    public function removeChild(child : GObject, dispose : Bool = false) : GObject
    {
        var childIndex : Int = Lambda.indexOf(_children, child);
        if (childIndex != -1) 
        {
            removeChildAt(childIndex, dispose);
        }
        return child;
    }
    
    public function removeChildAt(index : Int, dispose : Bool = false) : GObject
    {
        if (index >= 0 && index < numChildren) 
        {
            var child : GObject = _children[index];
            child.parent = null;
            
            if (child.sortingOrder != 0) 
                _sortingChildCount--;
            
            _children.splice(index, 1);
            if (child.inContainer) 
            {
                _container.removeChild(child.displayObject);
                
                if (_childrenRenderOrder == ChildrenRenderOrder.Arch) 
                    GTimers.inst.callLater(buildNativeDisplayList);
            }
            
            if (dispose) 
                child.dispose();
            
            setBoundsChangedFlag();
            
            return child;
        }
        else 
        {
            throw new RangeError("Invalid child index");
        }
    }
    
    public function removeChildren(beginIndex : Int = 0, endIndex : Int = -1, dispose : Bool = false) : Void
    {
        if (endIndex < 0 || endIndex >= numChildren) 
            endIndex = numChildren - 1;
        
        for (i in beginIndex...endIndex + 1)
        {
            removeChildAt(beginIndex, dispose);
        }
    }
    
    public function getChildAt(index : Int) : GObject
    {
        if (index >= 0 && index < numChildren) 
            return _children[index]
        else 
        throw new RangeError("Invalid child index");
    }
    
    public function getChild(name : String) : GObject
    {
        var cnt : Int = _children.length;
        for (i in 0...cnt){
            if (_children[i].name == name) 
                return _children[i];
        }
        
        return null;
    }
    
    public function getVisibleChild(name : String) : GObject
    {
        var cnt : Int = _children.length;
        for (i in 0...cnt){
            var child : GObject = _children[i];
            if (child.finalVisible && child.name == name) 
                return child;
        }
        
        return null;
    }
    
    public function getChildInGroup(name : String, group : GGroup) : GObject
    {
        var cnt : Int = _children.length;
        for (i in 0...cnt){
            var child : GObject = _children[i];
            if (child.group == group && child.name == name) 
                return child;
        }
        
        return null;
    }
    
    @:allow(fairygui)
    private function getChildById(id : String) : GObject
    {
        var cnt : Int = _children.length;
        for (i in 0...cnt){
            if (_children[i]._id == id) 
                return _children[i];
        }
        
        return null;
    }
    
    public function getChildIndex(child : GObject) : Int
    {
        return Lambda.indexOf(_children, child);
    }
    
    public function setChildIndex(child : GObject, index : Int) : Void
    {
        var oldIndex : Int = Lambda.indexOf(_children, child);
        if (oldIndex == -1) 
            throw new ArgumentError("Not a child of this container");
        
        if (child.sortingOrder != 0)               //no effect  
        return;
        
        var cnt : Int = _children.length;
        if (_sortingChildCount > 0) 
        {
            if (index > (cnt - _sortingChildCount - 1)) 
                index = cnt - _sortingChildCount - 1;
        }
        
        _setChildIndex(child, oldIndex, index);
    }
    
    public function setChildIndexBefore(child : GObject, index : Int) : Int
    {
        var oldIndex : Int = Lambda.indexOf(_children, child);
        if (oldIndex == -1) 
            throw new ArgumentError("Not a child of this container");
        
        if (child.sortingOrder != 0)               //no effect  
        return oldIndex;
        
        var cnt : Int = _children.length;
        if (_sortingChildCount > 0) 
        {
            if (index > (cnt - _sortingChildCount - 1)) 
                index = cnt - _sortingChildCount - 1;
        }
        
        if (oldIndex < index) 
            return _setChildIndex(child, oldIndex, index - 1)
        else 
        return _setChildIndex(child, oldIndex, index);
    }
    
    private function _setChildIndex(child : GObject, oldIndex : Int, index : Int) : Int
    {
        var cnt : Int = _children.length;
        if (index > cnt) 
            index = cnt;
        
        if (oldIndex == index) 
            return index;
        
        _children.splice(oldIndex, 1);
        _children.insert(index+1, child);

        if (child.inContainer) 
        {
            var displayIndex : Int = 0;
            var g : GObject;
            var i : Int;
            
            if (_childrenRenderOrder == ChildrenRenderOrder.Ascent) 
            {
                for (i in 0...index){
                    g = _children[i];
                    if (g.inContainer) 
                        displayIndex++;
                }
                if (displayIndex == _container.numChildren) 
                    displayIndex--;
                _container.setChildIndex(child.displayObject, displayIndex);
            }
            else if (_childrenRenderOrder == ChildrenRenderOrder.Descent) 
            {
                i = cnt - 1;
                while (i > index){
                    g = _children[i];
                    if (g.inContainer) 
                        displayIndex++;
                    i--;
                }
                if (displayIndex == _container.numChildren) 
                    displayIndex--;
                _container.setChildIndex(child.displayObject, displayIndex);
            }
            else 
            {
                GTimers.inst.callLater(buildNativeDisplayList);
            }
            
            setBoundsChangedFlag();
        }
        
        return index;
    }
    
    public function swapChildren(child1 : GObject, child2 : GObject) : Void
    {
        var index1 : Int = Lambda.indexOf(_children, child1);
        var index2 : Int = Lambda.indexOf(_children, child2);
        if (index1 == -1 || index2 == -1) 
            throw new ArgumentError("Not a child of this container");
        swapChildrenAt(index1, index2);
    }
    
    public function swapChildrenAt(index1 : Int, index2 : Int) : Void
    {
        var child1 : GObject = _children[index1];
        var child2 : GObject = _children[index2];
        
        setChildIndex(child1, index2);
        setChildIndex(child2, index1);
    }
    
    @:final private function get_numChildren() : Int
    {
        return _children.length;
    }
    
    public function isAncestorOf(child : GObject) : Bool
    {
        if (child == null) 
            return false;
        
        var p : GComponent = child.parent;
        while (p != null)
        {
            if (p == this) 
                return true;
            
            p = p.parent;
        }
        return false;
    }
    
    public function addController(controller : Controller) : Void
    {
        _controllers.push(controller);
        controller._parent = this;
        applyController(controller);
    }
    
    public function getControllerAt(index : Int) : Controller
    {
        return _controllers[index];
    }
    
    public function getController(name : String) : Controller
    {
        var cnt : Int = _controllers.length;
        for (i in 0...cnt){
            var c : Controller = _controllers[i];
            if (c.name == name) 
                return c;
        }
        
        return null;
    }
    
    public function removeController(c : Controller) : Void
    {
        var index : Int = Lambda.indexOf(_controllers, c);
        if (index == -1) 
            throw new Error("controller not exists");
        
        c._parent = null;
        _controllers.splice(index, 1);
        
        for (child in _children)
        child.handleControllerChanged(c);
    }
    
    @:final private function get_controllers() : Array<Controller>
    {
        return _controllers;
    }
    
    @:allow(fairygui)
    private function childStateChanged(child : GObject) : Void
    {
        if (_buildingDisplayList) 
            return;
        
        var cnt : Int = _children.length;
        var g : GObject;
        var i : Int;
        
        if (Std.is(child, GGroup)) 
        {
            for (i in 0...cnt){
                g = _children[i];
                if (g.group == child) 
                    childStateChanged(g);
            }
            return;
        }
        
        if (child.displayObject == null)
            return;
        
        if (child.finalVisible) 
        {
            if (child.displayObject.parent == null)
            {
                var index : Int = 0;
                if (_childrenRenderOrder == ChildrenRenderOrder.Ascent) 
                {
                    for (i in 0...cnt){
                        g = _children[i];
                        if (g == child) 
                            break;
                        
                        if (g.displayObject != null && g.displayObject.parent != null) 
                            index++;
                    }
                    _container.addChildAt(child.displayObject, index);
                }
                else if (_childrenRenderOrder == ChildrenRenderOrder.Descent) 
                {
                    i = cnt - 1;
                    while (i >= 0){
                        g = _children[i];
                        if (g == child) 
                            break;
                        
                        if (g.displayObject != null && g.displayObject.parent != null) 
                            index++;
                        i--;
                    }
                    _container.addChildAt(child.displayObject, index);
                }
                else 
                {
                    _container.addChild(child.displayObject);
                    
                    GTimers.inst.callLater(buildNativeDisplayList);
                }
            }
        }
        else 
        {
            if (child.displayObject.parent != null)
            {
                _container.removeChild(child.displayObject);
                if (_childrenRenderOrder == ChildrenRenderOrder.Arch) 
                {
                    GTimers.inst.callLater(buildNativeDisplayList);
                }
            }
        }
    }
    
    private function buildNativeDisplayList() : Void
    {
        var cnt : Int = _children.length;
        if (cnt == 0) 
            return;
        
        var i : Int;
        var child : GObject;
        switch (_childrenRenderOrder)
        {
            case ChildrenRenderOrder.Ascent:
            {
                for (i in 0...cnt){
                    child = _children[i];
                    if (child.displayObject != null && child.finalVisible) 
                        _container.addChild(child.displayObject);
                }
            }
            case ChildrenRenderOrder.Descent:
            {
                i = cnt - 1;
                while (i >= 0){
                    child = _children[i];
                    if (child.displayObject != null && child.finalVisible) 
                        _container.addChild(child.displayObject);
                    i--;
                }
            }
            
            case ChildrenRenderOrder.Arch:
            {
                for (i in 0..._apexIndex){
                    child = _children[i];
                    if (child.displayObject != null && child.finalVisible) 
                        _container.addChild(child.displayObject);
                }
                i = cnt - 1;
                while (i >= _apexIndex){
                    child = _children[i];
                    if (child.displayObject != null && child.finalVisible) 
                        _container.addChild(child.displayObject);
                    i--;
                }
            }
        }
    }
    
    @:allow(fairygui)
    private function applyController(c : Controller) : Void
    {
        for (child in _children)
        {
            child.handleControllerChanged(c);
        }
    }
    
    @:allow(fairygui)
    private function applyAllControllers() : Void
    {
        var cnt : Int = _controllers.length;
        for (i in 0...cnt){
            applyController(_controllers[i]);
        }
    }
    
    @:allow(fairygui)
    private function adjustRadioGroupDepth(obj : GObject, c : Controller) : Void
    {
        var cnt : Int = _children.length;
        var i : Int;
        var child : GObject;
        var myIndex : Int = -1;
        var maxIndex : Int = -1;
        for (i in 0...cnt){
            child = _children[i];
            if (child == obj) 
            {
                myIndex = i;
            }
            else if ((Std.is(child, GButton))
                && cast((child), GButton).relatedController == c) 
            {
                if (i > maxIndex) 
                    maxIndex = i;
            }
        }
        if (myIndex < maxIndex) 
            this.swapChildrenAt(myIndex, maxIndex);
    }
    
    public function getTransitionAt(index : Int) : Transition
    {
        return _transitions[index];
    }
    
    public function getTransition(transName : String) : Transition
    {
        var cnt : Int = _transitions.length;
        for (i in 0...cnt){
            var trans : Transition = _transitions[i];
            if (trans.name == transName) 
                return trans;
        }
        
        return null;
    }
    
    @:final private function get_scrollPane() : ScrollPane
    {
        return _scrollPane;
    }
    
    public function isChildInView(child : GObject) : Bool
    {
        if (_scrollPane != null) 
        {
            return _scrollPane.isChildInView(child);
        }
        else if (_clipMask != null) 
        {
            return child.x + child.width >= 0 && child.x <= this.width && child.y + child.height >= 0 && child.y <= this.height;
        }
        else 
        return true;
    }
    
    public function getFirstChildInView() : Int
    {
        var cnt : Int = _children.length;
        for (i in 0...cnt){
            var child : GObject = _children[i];
            if (isChildInView(child)) 
                return i;
        }
        return -1;
    }
    
    @:final private function get_opaque() : Bool
    {
        return _opaque;
    }
    
    private function set_opaque(value : Bool) : Bool
    {
        if (_opaque != value) 
        {
            _opaque = value;
            if (_opaque) {
                cast(this.displayObject, Sprite).mouseEnabled = this.touchable;
                updateOpaque();
            }
            else {
                cast(this.displayObject, Sprite).mouseEnabled = false;
                _rootContainer.graphics.clear();
            }
        }
        return value;
    }
    
    private function get_margin() : Margin
    {
        return _margin;
    }
    
    private function set_margin(value : Margin) : Margin
    {
        _margin.copy(value);
        if (_clipMask != null) 
        {
            _container.x = _margin.left + _alignOffset.x;
            _container.y = _margin.top + _alignOffset.y;
        }
        handleSizeChanged();
        return value;
    }
    
    private function get_childrenRenderOrder() : Int
    {
        return _childrenRenderOrder;
    }
    
    private function set_childrenRenderOrder(value : Int) : Int
    {
        if (_childrenRenderOrder != value) 
        {
            _childrenRenderOrder = value;
            buildNativeDisplayList();
        }
        return value;
    }
    
    private function get_apexIndex() : Int
    {
        return _apexIndex;
    }
    
    private function set_apexIndex(value : Int) : Int
    {
        if (_apexIndex != value) 
        {
            _apexIndex = value;
            
            if (_childrenRenderOrder == ChildrenRenderOrder.Arch) 
                buildNativeDisplayList();
        }
        return value;
    }
    
    private function get_mask() : DisplayObject
    {
        return _container.mask;
    }
    
    private function set_mask(value : DisplayObject) : DisplayObject
    {
        _container.mask = value;
        if (value == null && _clipMask != null) 
            _container.mask = _clipMask;
        return value;
    }
    
    private function updateOpaque() : Void
    {
        var w : Float = this.width;
        var h : Float = this.height;
        if (w == 0) 
            w = 1;
        if (h == 0) 
            h = 1;
        
        var g : Graphics = _rootContainer.graphics;
        g.clear();
        g.lineStyle(0, 0, 0);
        g.beginFill(0, 0);
        g.drawRect(0, 0, w, h);
        g.endFill();
    }
    
    private function updateMask() : Void
    {
        var left : Float = _margin.left;
        var top : Float = _margin.top;
        var w : Float = this.width - (_margin.left + _margin.right);
        var h : Float = this.height - (_margin.top + _margin.bottom);
        if (w <= 0) 
            w = 1;
        if (h <= 0) 
            h = 1;
        
        var g : Graphics = _clipMask.graphics;
        g.clear();
        g.lineStyle(0, 0, 0);
        g.beginFill(0, 0);
        g.drawRect(left, top, w, h);
        g.endFill();
    }
    
    private function setupScroll(scrollBarMargin : Margin,
            scroll : Int,
            scrollBarDisplay : Int,
            flags : Int,
            vtScrollBarRes : String,
            hzScrollBarRes : String) : Void
    {
        if (_rootContainer == _container) 
        {
            _container = new Sprite();
            _rootContainer.addChild(_container);
        }
        _scrollPane = new ScrollPane(this, scroll, scrollBarMargin, scrollBarDisplay, flags, 
                vtScrollBarRes, hzScrollBarRes);
    }
    
    private function setupOverflow(overflow : Int) : Void
    {
        if (overflow == OverflowType.Hidden) 
        {
            if (_rootContainer == _container) 
            {
                _container = new Sprite();
                _rootContainer.addChild(_container);
            }
            
            _clipMask = new Shape();
            _rootContainer.addChild(_clipMask);
            updateMask();
            
            _container.mask = _clipMask;
            _container.x = _margin.left;
            _container.y = _margin.top;
        }
        else if (_margin.left != 0 || _margin.top != 0) 
        {
            if (_rootContainer == _container) 
            {
                _container = new Sprite();
                _rootContainer.addChild(_container);
            }
            
            _container.x = _margin.left;
            _container.y = _margin.top;
        }
    }
    
    override private function handleSizeChanged() : Void
    {
        if (_scrollPane != null) 
            _scrollPane.onOwnerSizeChanged();
        if (_clipMask != null) 
            updateMask();
        
        if (_opaque) 
            updateOpaque();
    }
    
    override private function handleGrayedChanged() : Void
    {
        var c : Controller = getController("grayed");
        if (c != null) 
        {
            c.selectedIndex = (this.grayed) ? 1 : 0;
            return;
        }
        
        var v : Bool = this.grayed;
        var cnt : Int = _children.length;
        for (i in 0...cnt){
            _children[i].grayed = v;
        }
    }
    
    public function setBoundsChangedFlag() : Void
    {
        if (_scrollPane == null && !_trackBounds) 
            return;
        
        if (!_boundsChanged) 
        {
            _boundsChanged = true;
            GTimers.inst.add(0, 1, __render);
        }
    }
    
    private function __render() : Void
    {
        if (_boundsChanged) 
            updateBounds();
    }
    
    public function ensureBoundsCorrect() : Void
    {
        if (_boundsChanged) 
            updateBounds();
    }
    
    private function updateBounds() : Void
    {
        var ax : Int;
        var ay : Int;
        var aw : Int;
        var ah : Int;
        if (_children.length > 0) 
        {
            ax = CompatUtil.INT_MAX_VALUE;
            ay = CompatUtil.INT_MAX_VALUE;
            var ar : Int = CompatUtil.INT_MIN_VALUE;
            var ab : Int = CompatUtil.INT_MIN_VALUE;
            var tmp : Int;
            
            for (child in _children)
            {
                child.ensureSizeCorrect();
            }
            
            for (child in _children)
            {
                tmp = Std.int(child.x);
                if (tmp < ax) 
                    ax = tmp;
                tmp = Std.int(child.y);
                if (tmp < ay) 
                    ay = tmp;
                tmp = Std.int(child.x + child.actualWidth);
                if (tmp > ar) 
                    ar = tmp;
                tmp = Std.int(child.y + child.actualHeight);
                if (tmp > ab) 
                    ab = tmp;
            }
            aw = ar - ax;
            ah = ab - ay;
        }
        else 
        {
            ax = 0;
            ay = 0;
            aw = 0;
            ah = 0;
        }
        
        setBounds(ax, ay, aw, ah);
    }
    
    private function setBounds(ax : Int, ay : Int, aw : Int, ah : Int) : Void
    {
        _boundsChanged = false;
        
        if (_scrollPane != null) 
            _scrollPane.setContentSize(Math.round(ax + aw), Math.round(ay + ah));
    }
    
    private function get_viewWidth() : Int
    {
        if (_scrollPane != null) 
            return _scrollPane.viewWidth
        else 
            return Std.int(this.width - _margin.left - _margin.right);
    }
    
    private function set_viewWidth(value : Int) : Int
    {
        if (_scrollPane != null) 
            _scrollPane.viewWidth = value
        else
            this.width = value + _margin.left + _margin.right;

        return value;
    }
    
    private function get_viewHeight() : Int
    {
        if (_scrollPane != null) 
            return _scrollPane.viewHeight
        else 
            return Std.int(this.height - _margin.top - _margin.bottom);
    }
    
    private function set_viewHeight(value : Int) : Int
    {
        if (_scrollPane != null) 
            _scrollPane.viewHeight = value
        else
            Std.int(this.height = value + _margin.top + _margin.bottom);
        return value;
    }
    
    public function getSnappingPosition(xValue : Float, yValue : Float, resultPoint : Point = null) : Point
    {
        if (resultPoint == null) 
            resultPoint = new Point();
        
        var cnt : Int = _children.length;
        if (cnt == 0) 
        {
            resultPoint.x = xValue;
            resultPoint.y = yValue;
            return resultPoint;
        }
        
        ensureBoundsCorrect();
        
        var obj : GObject = null;
        var prev : GObject;
        
        var i : Int = 0;
        if (yValue != 0) 
        {
                        while (i < cnt){
                obj = _children[i];
                if (yValue < obj.y) 
                {
                    if (i == 0) 
                    {
                        yValue = 0;
                        break;
                    }
                    else 
                    {
                        prev = _children[i - 1];
                        if (yValue < prev.y + prev.height / 2)                               //top half part  
                        yValue = prev.y
                        //bottom half part
                        else 
                        yValue = obj.y;
                        break;
                    }
                }
                i++;
            }
            
            if (i == cnt) 
                yValue = obj.y;
        }
        
        if (xValue != 0) 
        {
            if (i > 0) 
                i--;
                        while (i < cnt){
                obj = _children[i];
                if (xValue < obj.x) 
                {
                    if (i == 0) 
                    {
                        xValue = 0;
                        break;
                    }
                    else 
                    {
                        prev = _children[i - 1];
                        if (xValue < prev.x + prev.width / 2)                               //top half part  
                        xValue = prev.x
                        //bottom half part
                        else 
                        xValue = obj.x;
                        break;
                    }
                }
                i++;
            }
            
            if (i == cnt) 
                xValue = obj.x;
        }
        
        resultPoint.x = xValue;
        resultPoint.y = yValue;
        return resultPoint;
    }
    
    @:allow(fairygui)
    private function childSortingOrderChanged(child : GObject, oldValue : Int, newValue : Int) : Void
    {
        if (newValue == 0) 
        {
            _sortingChildCount--;
            setChildIndex(child, _children.length);
        }
        else 
        {
            if (oldValue == 0) 
                _sortingChildCount++;
            
            var oldIndex : Int = Lambda.indexOf(_children, child);
            var index : Int = getInsertPosForSortingChild(child);
            if (oldIndex < index) 
                _setChildIndex(child, oldIndex, index - 1)
            else 
            _setChildIndex(child, oldIndex, index);
        }
    }
    
    override public function constructFromResource() : Void
    {
        constructFromResource2(null, 0);
    }
    
    @:allow(fairygui)
    private function constructFromResource2(objectPool : Array<GObject>, poolIndex : Int) : Void
    {
        var xml : FastXML = packageItem.owner.getComponentData(packageItem);
        
        var str : String;
        var arr : Array<Dynamic>;
        
        _underConstruct = true;
        
        str = xml.att.size;
        arr = str.split(",");
        _sourceWidth = Std.parseInt(arr[0]);
        _sourceHeight = Std.parseInt(arr[1]);
        _initWidth = _sourceWidth;
        _initHeight = _sourceHeight;
        
        setSize(_sourceWidth, _sourceHeight);
        
        str = xml.att.pivot;
        if (str != null) 
        {
            arr = str.split(",");
            str = xml.att.anchor;
            internalSetPivot(Std.parseFloat(arr[0]), Std.parseFloat(arr[1]), str == "true");
        }
        
        str = xml.att.opaque;
        if (str != "false") 
            this.opaque = true;
        
        var overflow : Int;
        str = xml.att.overflow;
        if (str != null) 
            overflow = OverflowType.parse(str)
        else 
        overflow = OverflowType.Visible;
        
        str = xml.att.margin;
        if (str != null) 
            _margin.parse(str);
        
        if (overflow == OverflowType.Scroll) 
        {
            var scroll : Int = ScrollType.Both;
            str = xml.att.scroll;
            if (str != null) 
                scroll = ScrollType.parse(str)
            else 
            scroll = ScrollType.Vertical;
            
            var scrollBarDisplay : Int = ScrollBarDisplayType.Default;
            str = xml.att.scrollBar;
            if (str != null) 
                scrollBarDisplay = ScrollBarDisplayType.parse(str)
            else 
            scrollBarDisplay = ScrollBarDisplayType.Default;
            var scrollBarFlags : Int = Std.parseInt(xml.att.scrollBarFlags);
            
            var scrollBarMargin : Margin = new Margin();
            str = xml.att.scrollBarMargin;
            if (str != null) 
                scrollBarMargin.parse(str);
            
            var vtScrollBarRes : String = null;
            var hzScrollBarRes : String = null;
            str = xml.att.scrollBarRes;
            if (str != null) 
            {
                arr = str.split(",");
                vtScrollBarRes = arr[0];
                hzScrollBarRes = arr[1];
            }
            
            setupScroll(scrollBarMargin, scroll, scrollBarDisplay, scrollBarFlags,
                    vtScrollBarRes, hzScrollBarRes);
        }
        else 
        setupOverflow(overflow);
        
        _buildingDisplayList = true;
        var col : FastXMLList = xml.descendants("controller");

        var controller : Controller;
        for (cxml in col.iterator())
        {
            controller = new Controller();
            _controllers.push(controller);
            controller._parent = this;
            controller.setup(cxml);
        }
        
        var child : GObject;
        var displayList : Array<DisplayListItem> = packageItem.displayList;
        var childCount : Int = displayList.length;
        var i : Int;
        for (i in 0...childCount){
            var di : DisplayListItem = displayList[i];
            
            if (objectPool != null) 
            {
                child = objectPool[poolIndex + i];
            }
            else if (di.packageItem != null)
            {
                child = UIObjectFactory.newObject(di.packageItem);
                child.packageItem = di.packageItem;
                child.constructFromResource();
            }
            else 
            child = UIObjectFactory.newObject2(di.type);
            
            child._underConstruct = true;
            child.setup_beforeAdd(di.desc);
            child.parent = this;
            _children.push(child);
        }
        this.relations.setup(xml);
        
        for (i in 0...childCount)
        {
            _children[i].relations.setup(displayList[i].desc);
        }
        
        for (i in 0...childCount){
            child = _children[i];
            child.setup_afterAdd(displayList[i].desc);
            child._underConstruct = false;
        }

        str = xml.att.mask;
        if(str!=null)
        this.mask = getChildById(str).displayObject;
        
        col = xml.descendants("transition");
        var trans : Transition;
        for (cxml in col.iterator())
        {
            trans = new Transition(this);
            _transitions.push(trans);
            trans.setup(cxml);
        }
        
        if (_transitions.length > 0) 
        {
            this.addEventListener(Event.ADDED_TO_STAGE, p__addedToStage);
            this.addEventListener(Event.REMOVED_FROM_STAGE, __removedFromStage);
        }
        
        applyAllControllers();
        
        _buildingDisplayList = false;
        _underConstruct = false;
        
        buildNativeDisplayList();
        setBoundsChangedFlag();
        
        constructFromXML(xml);
    }
    
    private function constructFromXML(xml : FastXML) : Void
    {
    }
    
    @:final private function p__addedToStage(evt : Event) : Void
    {
        var cnt : Int = _transitions.length;
        for (i in 0...cnt){
            var trans : Transition = _transitions[i];
            if (trans.autoPlay) 
                trans.play(null, null, trans.autoPlayRepeat, trans.autoPlayDelay);
        }
    }
    
    private function __removedFromStage(evt : Event) : Void
    {
        var cnt : Int = _transitions.length;
        for (i in 0...cnt){
            var trans : Transition = _transitions[i];
            trans.stop(false, false);
        }
    }
}

