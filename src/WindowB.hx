import tweenxcore.Tools.Easing;
import tweenx909.TweenX;
import fairygui.UIPackage;
import fairygui.Window;

class WindowB extends Window
{
    public function new()
    {
        super();
    }
    
    override private function onInit() : Void
    {
        this.contentPane = UIPackage.createObject("Basic", "WindowB").asCom;
        this.center();
        
        //弹出窗口的动效已中心为轴心
        this.setPivot(0.5,0.5);
    }
    
    override private function doShowAnimation() : Void
    {
        this.setScale(0.1, 0.1);
        TweenX.tweenFunc2(setScale,0.1,0.1,1,1).time(0.3).ease(Easing.quadOut).onFinish(onShown);
//        TweenX.to(this, {
//                    scaleX : 1,
//                    scaleY : 1
//        }, 0.3).ease(Easing.quadOut).onFinish(onShown);
    }
    
    override private function doHideAnimation() : Void
    {
        TweenX.tweenFunc2(setScale,1,1,0.1,0.1).time(0.3).ease(Easing.quadOut).onFinish(hideImmediately);
//        TweenX.to(this, {
//                    scaleX : 0.1,
//                    scaleY : 0.1
//                }, 0.3).ease(Easing.quadOut).onFinish(hideImmediately);
    }
    
    override private function onShown() : Void
    {
        contentPane.getTransition("t1").play();
    }
    
    override private function onHide() : Void
    {
        contentPane.getTransition("t1").stop();
    }
}
