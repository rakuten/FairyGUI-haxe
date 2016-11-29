
import fairygui.GButton;
import fairygui.GList;
import fairygui.UIPackage;
import fairygui.Window;

class WindowA extends Window
{
    public function new()
    {
        super();
    }
    
    override private function onInit() : Void
    {
        this.contentPane = UIPackage.createObject("Basic", "WindowA").asCom;
        this.center();
    }
    
    override private function onShown() : Void
    {
        var list : GList = this.contentPane.getChild("n6").asList;
        list.removeChildrenToPool();
        
        for (i in 0...6){
            var item : GButton = list.addItemFromPool().asButton;
            item.title = "" + i;
            item.icon = UIPackage.getItemURL("Basic", "r4");
        }
    }
}
