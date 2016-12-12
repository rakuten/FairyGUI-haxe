package fairygui;


class UIConfig
{
    public function new()
    {
    }
    
    //Default font name
    public static var defaultFont : String = "";
    
    //Resource using in Window.ShowModalWait for locking the window.
    public static var windowModalWaiting : String;
    //Resource using in GRoot.ShowModalWait for locking the screen.
    public static var globalModalWaiting : String;  //全局锁定时使用的资源, see GStage.showModalWait  
    
    //When a modal window is in front, the background becomes dark.
    public static var modalLayerColor : Int = 0x333333;
    public static var modalLayerAlpha : Float = 0.2;
    
    //Default button click sound
    public static var buttonSound : String;
    public static var buttonSoundVolumeScale : Float = 1;
    
    public static var buttonUseHandCursor : Bool = false;
    
    //Resources for scrollbars
    public static var horizontalScrollBar : String;
    public static var verticalScrollBar : String;
    //Scrolling step in pixels
    public static var defaultScrollSpeed : Int = 25;
    // Speed ratio of scrollpane when its touch dragging.
    public static var defaultTouchScrollSpeedRatio:Float = 1;
    //Default scrollbar display mode. Recommened visible for Desktop and Auto for mobile.
    public static var defaultScrollBarDisplay : Int = ScrollBarDisplayType.Visible;
    //Allow dragging the content to scroll. Recommeded true for mobile.
    public static var defaultScrollTouchEffect : Bool = false;
    //The "rebound" effect in the scolling container. Recommeded true for mobile.
    public static var defaultScrollBounceEffect : Bool = false;
    
    //Resources for PopupMenu.
    public static var popupMenu : String;
    //Resources for seperator of PopupMenu.
    public static var popupMenu_seperator : String;
    //In case of failure of loading content for GLoader, use this sign to indicate an error.
    public static var loaderErrorSign : String;
    //Resources for tooltips.
    public static var tooltipsWin : String;
    
    //Max items displayed in combobox without scrolling.
    public static var defaultComboBoxVisibleItemCount : Int = 10;
    
    // Pixel offsets of finger to trigger scrolling.
    public static var touchScrollSensitivity : Int = 20;
    
    // Pixel offsets of finger to trigger dragging.
    public static var touchDragSensitivity : Int = 10;
    
    // Pixel offsets of mouse pointer to trigger dragging.
    public static var clickDragSensitivity : Int = 2;
    
    // When click the window, brings to front automatically.
    public static var bringWindowToFrontOnClick : Bool = true;
    
    public static var frameTimeForAsyncUIConstruction : Int = 2;
}

