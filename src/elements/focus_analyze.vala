public class EyeNeko.Elements.FocusAnalyze : BinBase {
    public Gst.Element tee = Gst.ElementFactory.make ("tee");
    public Gst.Element queue_analyze = Gst.ElementFactory.make ("queue");
    public Gst.Element videocrop = Gst.ElementFactory.make ("videocrop");
    public Gst.Element glupload = Gst.ElementFactory.make ("glupload");
    public Gst.Element laplacian = Gst.ElementFactory.make ("gleffects_laplacian");
    public Gst.Element gldownload = Gst.ElementFactory.make ("gldownload");
    public Gst.Element videoconvert = Gst.ElementFactory.make ("videoconvert");
    public Gst.Element videoanalyze = Gst.ElementFactory.make ("videoanalyse");
    public Gst.Element videoconvert2 = Gst.ElementFactory.make ("videoconvert");
    public Gst.Element gtk4paintablesink = Gst.ElementFactory.make ("gtk4paintablesink");

    public Gst.Element queue_passthrough = Gst.ElementFactory.make ("queue");
    public double focus_mark { get; private set; }
    public const int window_h = 256;
    public const int window_w = 256;
    public double window_wpos { get; set; default = 0.1; }
    public double window_hpos { get; set; default = 0.1; }
    public int width = 0;
    public int height = 0;
    public enum Orientation {
        ROTATE0,
        ROTATE90,
        ROTATE180,
        ROTATE270
    }
    Orientation orientation = Orientation.ROTATE0;

    public Gdk.Paintable paintable {
        owned get {
            Gdk.Paintable paintable = null;
            gtk4paintablesink.get ("paintable", out paintable);
            return paintable;
        }
    }

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
        case Gst.MessageType.ELEMENT:
            if (message.get_structure ().get_name () == "GstVideoAnalyse") {
                double val;
                message.get_structure ().get_double ("luma-average", out val);
                focus_mark = val;
                AutoFocus.instance.adjust_step (focus_mark);
            }
            break;
        default:
            break;
        }

        return true;
    }

    static construct {
        set_static_metadata ("focusanalyze",
                             "Filter",
                             "Focus analyze video filter.",
                             "nekocwd@mainlining.org");
    }
    public void set_window () {
        var wpos = window_wpos;
        var hpos = window_hpos;
        switch (orientation) {
        case Orientation.ROTATE90:
            wpos = window_hpos;
            hpos = 1 - window_wpos;
            break;

        case Orientation.ROTATE180:
            wpos = 1 - window_wpos;
            hpos = 1 - window_hpos;
            break;

        case Orientation.ROTATE270:
            wpos = 1 - window_hpos;
            hpos = window_wpos;
            break;
        default:
            break;
        }
        int left = (int) (width * wpos - window_w / 2);
        left = int.min (width - window_w, int.max (left, 0));
        left = int.max (0, left);

        int right = width - left - window_w;
        right = int.max (0, right);

        int top = (int) (height * hpos - window_h / 2);
        top = int.min (height - window_h, int.max (top, 0));
        top = int.max (0, top);

        int bottom = height - top - window_h;
        bottom = int.max (0, bottom);


        videocrop.set_property ("left", left);
        videocrop.set_property ("right", right);
        videocrop.set_property ("top", top);
        videocrop.set_property ("bottom", bottom);
        message ("l=%d r=%d t=%d b=%d (%dx%d)", left, right, top, bottom, width - left - right, height - top - bottom);
    }

    static bool sink_event (Gst.Pad pad, Gst.Object? parent, owned Gst.Event event) {
        var filter = (FocusAnalyze) parent;
        if (event.type == Gst.EventType.TAG) {
            Gst.TagList taglist;
            event.parse_tag (out taglist);
            string orientation;
            taglist.get_string ("image-orientation", out orientation);
            if (orientation != null) {
                switch (orientation) {
                case "rotate-0" :
                    filter.orientation = Orientation.ROTATE0;
                    break;
                case "rotate-90":
                    filter.orientation = Orientation.ROTATE90;
                    break;
                case "rotate-180":
                    filter.orientation = Orientation.ROTATE180;
                    break;
                case "rotate-270":
                    filter.orientation = Orientation.ROTATE270;
                    break;
                default:
                    break;
                }
                message ("%s", orientation);
            }
        }
        if (event.type == Gst.EventType.CAPS) {
            message ("Caps");
            Gst.Caps caps;
            event.parse_caps (out caps);
            var info = new Gst.Video.Info.with_caps (caps);
            filter.width = info.width;
            filter.height = info.height;
            filter.set_window ();
        }
        if (event.type == Gst.EventType.STREAM_START) {
            message ("Stream-Collection");
            filter.width = 0;
            filter.height = 0;
            filter.set_window ();
        }

        return pad.event_default (parent, event);
    }

    construct {
        add_many (tee, queue_analyze, videocrop, glupload, laplacian, gldownload, videoconvert, videoanalyze, videoconvert2, gtk4paintablesink, queue_passthrough);
        tee.link_many (queue_passthrough);
        add_pads (tee, queue_passthrough);
        tee.link_many (queue_analyze, videocrop, glupload, laplacian, gldownload, videoconvert, videoanalyze, videoconvert2, gtk4paintablesink);
        sinkpad.set_event_function (sink_event, null, null);
        var bus = new Gst.Bus ();
        videoanalyze.set_bus (bus);
        bus.add_watch (0, bus_callback);
        notify["window-wpos"].connect (set_window);
        notify["window-hpos"].connect (set_window);
    }
}
