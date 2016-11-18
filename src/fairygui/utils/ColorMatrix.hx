package fairygui.utils;

abstract ColorMatrix(Array<Float>) from Array<Float> to Array<Float>
{
    
    // identity matrix constant:
    private static var IDENTITY_MATRIX : Array<Dynamic> = [
        1, 0, 0, 0, 0, 
        0, 1, 0, 0, 0, 
        0, 0, 1, 0, 0, 
        0, 0, 0, 1, 0];
    private static var LENGTH : Int = IDENTITY_MATRIX.length;
    
    private static inline var LUMA_R : Float = 0.299;
    private static inline var LUMA_G : Float = 0.587;
    private static inline var LUMA_B : Float = 0.114;
    
    public static function create(p_brightness : Float, p_contrast : Float, p_saturation : Float, p_hue : Float) : ColorMatrix{
        var ret : ColorMatrix = new ColorMatrix();
        ret.adjustColor(p_brightness, p_contrast, p_saturation, p_hue);
        return ret;
    }
    
    // initialization:
    public function new()
    {
//        super();
        this = new Array<Float>();
        reset();
    }
    
    
    // public methods:
    public function reset() : Void{
        for (i in 0...LENGTH){
            this[i] = IDENTITY_MATRIX[i];
        }
    }
    
    public function invert() : Void
    {
        multiplyMatrix([-1, 0, 0, 0, 255, 
                0, -1, 0, 0, 255, 
                0, 0, -1, 0, 255, 
                0, 0, 0, 1, 0]);
    }
    
    public function adjustColor(p_brightness : Float, p_contrast : Float, p_saturation : Float, p_hue : Float) : Void{
        adjustHue(p_hue);
        adjustContrast(p_contrast);
        adjustBrightness(p_brightness);
        adjustSaturation(p_saturation);
    }
    
    public function adjustBrightness(p_val : Float) : Void{
        p_val = cleanValue(p_val, 1) * 255;
        multiplyMatrix([
                1, 0, 0, 0, p_val, 
                0, 1, 0, 0, p_val, 
                0, 0, 1, 0, p_val, 
                0, 0, 0, 1, 0]);
    }
    
    public function adjustContrast(p_val : Float) : Void{
        p_val = cleanValue(p_val, 1);
        var s : Float = p_val + 1;
        var o : Float = 128 * (1 - s);
        multiplyMatrix([
                s, 0, 0, 0, o, 
                0, s, 0, 0, o, 
                0, 0, s, 0, o, 
                0, 0, 0, 1, 0]);
    }
    
    public function adjustSaturation(p_val : Float) : Void{
        p_val = cleanValue(p_val, 1);
        p_val += 1;
        
        var invSat : Float = 1 - p_val;
        var invLumR : Float = invSat * LUMA_R;
        var invLumG : Float = invSat * LUMA_G;
        var invLumB : Float = invSat * LUMA_B;
        
        multiplyMatrix([
                (invLumR + p_val), invLumG, invLumB, 0, 0, 
                invLumR, (invLumG + p_val), invLumB, 0, 0, 
                invLumR, invLumG, (invLumB + p_val), 0, 0, 
                0, 0, 0, 1, 0]);
    }
    
    public function adjustHue(p_val : Float) : Void{
        p_val = cleanValue(p_val, 1);
        p_val *= Math.PI;
        
        var cos : Float = Math.cos(p_val);
        var sin : Float = Math.sin(p_val);
        
        multiplyMatrix([
                ((LUMA_R + (cos * (1 - LUMA_R))) + (sin * -(LUMA_R))), ((LUMA_G + (cos * -(LUMA_G))) + (sin * -(LUMA_G))), ((LUMA_B + (cos * -(LUMA_B))) + (sin * (1 - LUMA_B))), 0, 0, 
                ((LUMA_R + (cos * -(LUMA_R))) + (sin * 0.143)), ((LUMA_G + (cos * (1 - LUMA_G))) + (sin * 0.14)), ((LUMA_B + (cos * -(LUMA_B))) + (sin * -0.283)), 0, 0, 
                ((LUMA_R + (cos * -(LUMA_R))) + (sin * -((1 - LUMA_R)))), ((LUMA_G + (cos * -(LUMA_G))) + (sin * LUMA_G)), ((LUMA_B + (cos * (1 - LUMA_B))) + (sin * LUMA_B)), 0, 0, 
                0, 0, 0, 1, 0]);
    }
    
    public function concat(p_matrix : Array<Dynamic>) : Void{
        if (p_matrix.length != LENGTH) {return;
        }
        multiplyMatrix(p_matrix);
    }
    
    public function clone() : ColorMatrix{
        var result : ColorMatrix = new ColorMatrix();
        result.copyMatrix(this);
        return result;
    }
    
    private function copyMatrix(p_matrix : Array<Dynamic>) : Void{
        var l : Int = LENGTH;
        for (i in 0...l){
            this[i] = p_matrix[i];
        }
    }
    
    private function multiplyMatrix(p_matrix : Array<Dynamic>) : Void{
        var col : Array<Dynamic> = [];
        
        var i : Int = 0;
        
        for (y in 0...4){
            for (x in 0...5){
                col[i + x] = p_matrix[i] * this[x] +
                        p_matrix[i + 1] * this[x + 5] +
                        p_matrix[i + 2] * this[x + 10] +
                        p_matrix[i + 3] * this[x + 15] +
                        ((x == 4) ? p_matrix[i + 4] : 0);
            }
            
            i += 5;
        }
        
        copyMatrix(col);
    }
    
    private function cleanValue(p_val : Float, p_limit : Float) : Float{
        return Math.min(p_limit, Math.max(-p_limit, p_val));
    }
}

