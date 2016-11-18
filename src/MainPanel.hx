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
        _view = UIPackage.createObject("Basic", "Demo").asCom;
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
        _pm.show(cast((evt.currentTarget), GObject), true);
    }
    
    private function __rightClick(evt : MouseEvent) : Void
    {
        _pm.show();
    }
    
    //------------------------------
    private function playDragDrop() : Void
    {
        var obj : GComponent = Reflect.field(_demoObjects, "Drag&Drop");
        obj.getChild("n0").draggable = true;
        
        var btn1 : GButton = obj.getChild("n1").asButton;
        btn1.draggable = true;
        btn1.addEventListener(DragEvent.DRAG_START, __dragStart);
        
        var btn2 : GButton = obj.getChild("n2").asButton;
        btn2.icon = null;
        btn2.addEventListener(DropEvent.DROP, __drop);
    }
    
    private function __dragStart(evt : DragEvent) : Void
    {
        //取消对原目标的拖动，换成一个替代品
        evt.preventDefault();
        
        var btn : GButton = cast((evt.currentTarget), GButton);
        DragDropManager.inst.startDrag(btn, btn.icon, btn.icon, evt.touchPointID);
    }
    
    private function __drop(evt : DropEvent) : Void
    {
        cast((evt.currentTarget), GButton).icon = Std.string(evt.source);
    }
}
