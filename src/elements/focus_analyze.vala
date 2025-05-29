public class EyeNeko.Elements.FocusAnalyze : BinBase {
    public Gst.Element tee = Gst.ElementFactory.make ("tee");
    public Gst.Element queue_analyze = Gst.ElementFactory.make ("queue");
    public Gst.Element laplacian = Gst.ElementFactory.make ("gleffects_laplacian");
    public Gst.Element gldownload = Gst.ElementFactory.make ("gldownload");
    public Gst.Element videoconvert = Gst.ElementFactory.make ("videoconvert");
    public Gst.Element videoanalyze = Gst.ElementFactory.make ("videoanalyse");
    public Gst.Element videoconvert2 = Gst.ElementFactory.make ("videoconvert");
    public Gst.Element gtk4paintablesink = Gst.ElementFactory.make ("gtk4paintablesink");

    public Gst.Element queue_passthrough = Gst.ElementFactory.make ("queue");
    public double focus_mark { get; private set; }

    public Gdk.Paintable paintable {
        owned get {
            Gdk.Paintable paintable;
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

    construct {
        add_many (tee, queue_analyze, laplacian, gldownload, videoconvert, videoanalyze, videoconvert2, gtk4paintablesink, queue_passthrough);
        tee.link_many (queue_analyze, laplacian, gldownload, videoconvert, videoanalyze, videoconvert2, gtk4paintablesink);
        tee.link_many (queue_passthrough);
        add_pads (tee, queue_passthrough);
        var bus = new Gst.Bus ();
        videoanalyze.set_bus (bus);
        bus.add_watch (0, bus_callback);
    }
}
