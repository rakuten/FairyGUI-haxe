package ;


import openfl.Assets;
import fairygui.GRoot;
import fairygui.UIConfig;
import fairygui.UIPackage;
import openfl.utils.ByteArray;
import openfl.events.Event;
import openfl.net.URLRequest;
import openfl.net.URLLoader;
import openfl.display.StageAlign;
import openfl.net.URLLoaderDataFormat;


import openfl.display.Sprite;

class Main extends Sprite {

    private var uiLoader:URLLoader;
    private var path:String = "assets/demo.zip";
    public function new() {
        super();
        stage.color=0;
        stage.frameRate=24;

        stage.align=StageAlign.TOP_LEFT;
//        stage.scaleMode=StageScaleMode.NO_SCALE;


//        uiLoader=new URLLoader();
//        uiLoader.dataFormat=URLLoaderDataFormat.BINARY;
//        uiLoader.addEventListener(Event.COMPLETE, uiLoader_completeHandler);
//        uiLoader.load(new URLRequest(path));
        uiLoader_completeHandler();
    }

    private function uiLoader_completeHandler(event:Event=null):Void
    {
//        UIPackage.addPackage(cast(uiLoader.data), null);
        UIPackage.addPackage(Assets.getBytes(path), null);

        UIConfig.defaultFont="Tahoma";
        UIConfig.verticalScrollBar=UIPackage.getItemURL("Basic", "ScrollBar_VT");
        UIConfig.horizontalScrollBar=UIPackage.getItemURL("Basic", "ScrollBar_HZ");
        UIConfig.popupMenu=UIPackage.getItemURL("Basic", "PopupMenu");
        UIConfig.defaultScrollBounceEffect=false;
        UIConfig.defaultScrollTouchEffect=false;

        //等待图片资源全部解码，也可以选择不等待，这样图片会在用到的时候才解码
        UIPackage.waitToLoadCompleted(continueInit);
//        continueInit();
    }

    private var _mainPanel:MainPanel;
    private function continueInit():Void
    {
        stage.addChild(new GRoot().displayObject);
        GRoot.inst.setFlashContextMenuDisabled(true);

        _mainPanel=new MainPanel();
    }



}
