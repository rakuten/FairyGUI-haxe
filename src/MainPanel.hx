import fairygui.GProgressBar;
import fairygui.GGraph;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import WindowA;
import WindowB;

import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.TextEvent;

import fairygui.Controller;
import fairygui.DragDropManager;
import fairygui.GButton;
import fairygui.GComponent;
import fairygui.GObject;
import fairygui.GRichTextField;
import fairygui.GRoot;
import fairygui.PopupMenu;
import fairygui.UIPackage;
import fairygui.Window;
import fairygui.event.DragEvent;
import fairygui.event.DropEvent;
import fairygui.utils.CompatUtil;

class MainPanel
{
    private var _view : GComponent;
    private var _backBtn : GObject;
    private var _demoContainer : GComponent;
    private var _cc : Controller;
    
    private var _demoObjects : Dynamic;
    
    public function new()
    {
        _view = UIPackage.createObject("Basic", "Main").asCom;
        GRoot.inst.addChild(_view);
        
        _backBtn = _view.getChild("btn_Back");
        _backBtn.visible = false;
        _backBtn.addClickListener(onClickBack);
        
        _demoContainer = _view.getChild("container").asCom;
        _cc = _view.getController("c1");
        
        var cnt : Int = _view.numChildren;
        for (i in 0...cnt){
            var obj : GObject = _view.getChildAt(i);
            if (obj.group != null && obj.group.name == "btns") 
                obj.addClickListener(runDemo);
        }
        
        _demoObjects = { };
    }
    
    private function runDemo(evt : Event) : Void
    {
        var type : String = cast((evt.currentTarget), GObject).name.substr(4);
        var obj : GComponent = Reflect.field(_demoObjects, type);
        if (obj == null) 
        {
            obj = UIPackage.createObject("Basic", "Demo_" + type).asCom;
            Reflect.setField(_demoObjects, type, obj);
        }
        
        _demoContainer.removeChildren();
        _demoContainer.addChild(obj);
        _cc.selectedIndex = 1;
        _backBtn.visible = true;
        trace("btnType:"+type);
        switch (type)
        {
            case "Button":
                playButton();
            
            case "Text":
                playText();
            
            case "Transition":
                playTransition();
            
            case "Window":
                playWindow();

            case "PopupMenu":
                playPopupMenu();
            
            case "Drag&Drop":
                playDragDrop();

            case "Depth":
                this.playDepth();

            case "Grid":
                this.playGrid();

            case "ProgressBar":
                this.playProgressBar();
        }
    }
    
    private function onClickBack(evt : Event) : Void
    {
        _cc.selectedIndex = 0;
        _backBtn.visible = false;
    }
    
    //------------------------------
    private function playButton() : Void
    {
        var obj : GComponent = Reflect.field(_demoObjects, "Button");
        obj.getChild("n34").addClickListener(__clickButton);
    }
    
    private function __clickButton(evt : Event) : Void
    {
        trace("click button");
    }
    
    //------------------------------
    private function playText() : Void
    {
        var obj : GComponent = Reflect.field(_demoObjects, "Text");
        obj.getChild("n12").asRichTextField.addEventListener(TextEvent.LINK, __clickLink);
        obj.getChild("n22").addClickListener(__clickGetInput);
    }
    
    private function __clickLink(evt : TextEvent) : Void
    {
        var obj : GRichTextField = try cast(evt.currentTarget, GRichTextField) catch(e:Dynamic) null;
        obj.text = "[img]ui://9leh0eyft9fj5f[/img][color=#FF0000]你点击了链接[/color]：" + evt.text;
    }

    private function __clickGetInput(evt:Event):Void
    {
        var obj:GComponent = Reflect.field(_demoObjects, "Text");
        obj.getChild("n21").text = obj.getChild("n19").text;
    }
    
    //------------------------------
    private function playTransition() : Void
    {
        var obj : GComponent = Reflect.field(_demoObjects, "Transition");
        obj.getChild("n2").asCom.getTransition("t0").play(null, null, CompatUtil.INT_MAX_VALUE);
        obj.getChild("n3").asCom.getTransition("peng").play(null, null, CompatUtil.INT_MAX_VALUE);
        
        obj.addEventListener(Event.REMOVED_FROM_STAGE, __removeFromStage);
    }
    
    private function __removeFromStage(evt : Event) : Void
    {
        var obj : GComponent = Reflect.field(_demoObjects, "Transition");
        obj.getChild("n2").asCom.getTransition("t0").stop();
        obj.getChild("n3").asCom.getTransition("peng").stop();
    }
    
    //------------------------------
    private var _winA : Window;
    private var _winB : Window;
    private function playWindow() : Void
    {
        var obj : GComponent = Reflect.field(_demoObjects, "Window");
        obj.getChild("n0").addClickListener(__showWinA);
        obj.getChild("n1").addClickListener(__showWinB);
    }
    
    private function __showWinA(evt : Event) : Void
    {
        if (_winA == null) 
            _winA = new WindowA();
        _winA.show();
    }
    
    private function __showWinB(evt : Event) : Void
    {
        if (_winB == null) 
            _winB = new WindowB();
        _winB.show();
    }
    
    //------------------------------
    private var _pm : PopupMenu;
    private function playPopupMenu() : Void
    {
        if (_pm == null) 
        {
            _pm = new PopupMenu();
            _pm.addItem("Item 1");
            _pm.addItem("Item 2");
            _pm.addItem("Item 3");
            _pm.addItem("Item 4");
        }
        
        var obj : GComponent = Reflect.field(_demoObjects, "PopupMenu");
        var btn : GObject = obj.getChild("n0");
        btn.addClickListener(__clickMenuBtn);
        obj.addEventListener(MouseEvent.RIGHT_CLICK, __rightClick);
    }
    
    private function __clickMenuBtn(evt : Event) : Void
    {
        _pm.show(cast(evt.currentTarget, GObject), true);
    }
    
    private function __rightClick(evt : MouseEvent) : Void
    {
        _pm.show();
    }
    
    //------------------------------
    private function playDragDrop() : Void
    {
        var obj : GComponent = Reflect.field(_demoObjects, "Drag&Drop");
        obj.getChild("a").draggable = true;
        
        var btn1 : GButton = obj.getChild("b").asButton;
        btn1.draggable = true;
        btn1.addEventListener(DragEvent.DRAG_START, __dragStart);
        
        var btn2 : GButton = obj.getChild("c").asButton;
        btn2.icon = null;
        btn2.addEventListener(DropEvent.DROP, __drop);


        var btnD: fairygui.GObject = obj.getChild("d");
        btnD.draggable = true;
        var bounds: fairygui.GObject = obj.getChild("bounds");
        var rect:Rectangle = new Rectangle();
        bounds.localToGlobalRect(0,0,bounds.width,bounds.height,rect);
        GRoot.inst.globalToLocalRect(rect.x,rect.y,rect.width,rect.height,rect);

        //因为这时候面板还在从右往左动，所以rect不准确，需要用相对位置算出最终停下来的范围
        rect.x -= obj.parent.x;

        btnD.dragBounds = rect;
    }
    
    private function __dragStart(evt : DragEvent) : Void
    {
        //取消对原目标的拖动，换成一个替代品
        evt.preventDefault();
        
        var btn : GButton = cast(evt.currentTarget, GButton);
        DragDropManager.inst.startDrag(btn, btn.icon, btn.icon, evt.touchPointID);
    }
    
    private function __drop(evt : DropEvent) : Void
    {
        cast(evt.currentTarget, GButton).icon = Std.string(evt.source);
    }

    private function playDepth(): Void
    {
        var obj: GComponent = Reflect.field(_demoObjects, "Depth");
        var testContainer: GComponent = obj.getChild("n22").asCom;
        var fixedObj: GObject = testContainer.getChild("n0");
        fixedObj.sortingOrder = 100;
        fixedObj.draggable = true;

        var numChildren: Float = testContainer.numChildren;
        var i: Int = 0;
        while(i < numChildren)
        {
            var child: GObject = testContainer.getChildAt(i);
            if(child != fixedObj)
            {
                testContainer.removeChildAt(i);
                numChildren--;
            }
            else
                i++;
        }
        var startPos: Point = new Point(fixedObj.x,fixedObj.y);

//        obj.getChild("btn0").addEventListener(MouseEvent.CLICK, __click1.bind([MouseEvent.CLICK, obj, startPos]));
//        obj.getChild("btn1").addEventListener(MouseEvent.CLICK, __click2.bind([MouseEvent.CLICK, obj, startPos]));
    }

    private function __click1(obj:GComponent, startPos:Point):Void
    {
        var graph: GGraph = new GGraph();
        startPos.x += 10;
        startPos.y += 10;
        graph.setXY(startPos.x,startPos.y);
        graph.setSize(150,150);
        graph.drawRect(1,0x000000,1,0xFF0000,1);
        obj.getChild("n22").asCom.addChild(graph);
    }

    private function __click2(obj:GComponent, startPos:Point):Void
    {
        var obj: GComponent = Reflect.field(_demoObjects, "Depth");
        var graph: fairygui.GGraph = new GGraph();
        startPos.x += 10;
        startPos.y += 10;
        graph.setXY(startPos.x,startPos.y);
        graph.setSize(150,150);
        graph.drawRect(1,0x000000,1,0x00FF00,1);
        graph.sortingOrder = 200;
        obj.getChild("n22").asCom.addChild(graph);
    }
    //------------------------------
    private function playGrid(): Void
    {
        var obj: GComponent = Reflect.field(_demoObjects, "Grid");
        var list1:fairygui.GList = obj.getChild("list1").asList;
        list1.removeChildrenToPool();
        var testNames: Array<String> = ["苹果手机操作系统","安卓手机操作系统","微软手机操作系统","微软桌面操作系统","苹果桌面操作系统","未知操作系统"];
        var testColors: Array<Int> = [ 0xFFFF00,0xFF0000,0xFFFFFF,0x0000FF ];
        var cnt:Int = testNames.length;
        for(i in 0...cnt)
        {
            var item:fairygui.GButton = list1.addItemFromPool().asButton;
            item.getChild("t0").text = "" + (i + 1);
            item.getChild("t1").text = testNames[i];
            var index:Int = Math.floor(Math.random()*4);
            item.getChild("t2").asTextField.color = testColors[index];
            item.getChild("star").asProgress.value = Std.int((Math.floor(Math.random() * 3)+1) / 3 * 100);
        }

        var list2: fairygui.GList = obj.getChild("list2").asList;
        list2.removeChildrenToPool();
        for(i in 0...cnt)
        {
            var item: fairygui.GButton = list2.addItemFromPool().asButton;
            item.getChild("cb").asButton.selected = false;
            item.getChild("t1").text = testNames[i];
            item.getChild("mc").asMovieClip.playing = i % 2 == 0;
            item.getChild("t3").text = "" + Math.floor(Math.random() * 10000);
        }
    }

    //---------------------------------------------
    private function playProgressBar():Void
    {
        var obj:fairygui.GComponent = Reflect.field(_demoObjects, "ProgressBar");
//        Laya.timer.frameLoop(2, this, this.__playProgress);
//        obj.on(Event.UNDISPLAY, this, this.__removeTimer);
    }

    private function __removeTimer():Void
    {
//        Laya.timer.clear(this, this.__playProgress);
    }

    private function __playProgress():Void
    {
        var obj:fairygui.GComponent = Reflect.field(_demoObjects, "ProgressBar");
        var cnt:Int = obj.numChildren;
        for (i in 0...cnt)
        {
            var child:GProgressBar = cast obj.getChildAt(i);
            if (child != null)
            {
                child.value += 1;
                if (child.value > child.max)
                child.value = 0;
            }
        }
    }
}
