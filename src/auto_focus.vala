public class AutoFocus : Object {
    void set_camfocus (double pos) {
        PipeTap.instance.focus = (int) (pos * 10);
    }

    private double best_score { get; set; default = 0; }
    private double best_lens_pos { get; set; default = 0; }
    public double prev_pos { get; private set; default = 0; }
    private double step { get; set; default = 10; }
    private double max_pos { get; set; default = 100; }
    private bool focus_in_process { get; set; default = false; }
    private int fc { get; set; default = 0; }

    public void reset_focus () {
        best_score = 0;
        best_lens_pos = 0;
        prev_pos = 0;
        step = 10;
        max_pos = 100;
        focus_in_process = true;
        fc = 0;
        set_camfocus (0);
    }

    void set_diff (double diff) {
        max_pos = double.min (best_lens_pos + diff, 100);
        prev_pos = double.max (best_lens_pos - diff, 0);
    }

    public void adjust_step (double prev_score) {
        // message ("%lf < %lf < %lf : %lf %lf / %lf", best_lens_pos, prev_pos, max_pos, step, prev_score, best_score);
        if (fc < EyeNeko.Env.get_variable_or ("FRAME_DELAY", "3").to_int ()) {
            fc++;
            return;
        } else
            fc = 0;
        if (prev_pos >= max_pos) {
            message ("Best focus %lf", best_lens_pos);
            switch ((int) (step * 10)) {
            case 100:
                message ("meow on 10");
                step = 5;
                set_diff (10);
                set_camfocus (prev_pos);
                break;
            case 50:
                message ("meow on 5");
                step = 2;
                set_diff (5);
                set_camfocus (prev_pos);
                break;
            case 20:
                message ("meow on 2");
                step = 0.5;
                set_diff (2);
                set_camfocus (prev_pos);
                break;
            case 5:
                message ("meow on 0.5");
                step = 0.1;
                set_diff (1);
                set_camfocus (prev_pos);
                break;
            case 1:
                message ("meow on 0.1");
                step = 10;
                max_pos = 100;
                focus_in_process = false;
                if (prev_pos != best_lens_pos) {
                    prev_pos = best_lens_pos;
                    set_camfocus (best_lens_pos);
                }
                break;
            default:
                message ("meow on def?");
                step = 10;
                break;
            }
            message ("min %lf max %lf step %lf", prev_pos, max_pos, step);
            return;
        }

        if (!focus_in_process)
            return;
        if (prev_score > best_score) {
            best_score = prev_score;
            best_lens_pos = prev_pos;
            message ("%lf better than %lf", prev_pos, best_lens_pos);
        }
        prev_pos += step;
        set_camfocus (prev_pos);
    }

    private static AutoFocus _instance = null;
    public static AutoFocus instance {
        get {
            if (_instance == null)
                _instance = new AutoFocus ();
            return _instance;
        }
    }
}
