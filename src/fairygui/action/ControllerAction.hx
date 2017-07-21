package fairygui.action;
class ControllerAction
{
    public var fromPage:Array<String>;
    public var toPage:Array<String>;

    public static function createAction(type:String):ControllerAction
    {
        switch(type)
        {
            case "play_transition":
                return new PlayTransitionAction();

            case "change_page":
                return new ChangePageAction();
        }
        return null;
    }

    public function new()
    {

    }

    public function run(controller:Controller, prevPage:String, curPage:String):Void
    {
        if ((fromPage == null || fromPage.length == 0 || fromPage.indexOf(prevPage) != -1)
            && (toPage == null || toPage.length == 0 || toPage.indexOf(curPage) != -1))
            enter(controller);
        else
            leave(controller);
    }

    @:Allow(fairygui)
    private function enter(controller:Controller):Void
    {

    }

    @:Allow(fairygui)
    private function leave(controller:Controller):Void
    {

    }

    public function setup(xml:FastXML):Void
    {
        var str:String;

        str = xml.att.fromPage;
        if (str != null)
            fromPage = str.split(",");

        str = xml.att.toPage;
        if (str != null)
            toPage = str.split(",");
    }
}
