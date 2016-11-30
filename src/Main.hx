package ;


import flash.display.StageScaleMode;
import openfl.Assets;
import fairygui.GRoot;
import fairygui.UIConfig;
import fairygui.UIPackage;
import openfl.utils.ByteArray;
import openfl.net.URLLoader;
import openfl.display.StageAlign;

import openfl.display.Sprite;

class Main extends Sprite {

    private var uiLoader:URLLoader;
    private var path:String = "assets/demo.zip";
    public function new() {
        super();
        stage.color=0;
        stage.frameRate=24;

        stage.align=StageAlign.TOP_LEFT;
        stage.scaleMode=StageScaleMode.NO_SCALE;


        Assets.loadBytes(path).onComplete(assetsCompleteHandler);
    }

    private function assetsCompleteHandler(by:ByteArray):Void
    {
        UIPackage.addPackage(by, null);

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
