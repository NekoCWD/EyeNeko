public class EyeNeko.Elements.FocusAnalyze : Gst.Bin {
    public Gst.Element tee = Gst.ElementFactory.make("tee");
    public Gst.Element queue_analyze = Gst.ElementFactory.make("queue");
    public Gst.Element glupload = Gst.ElementFactory.make("glupload");
    public Gst.Element laplacian = Gst.ElementFactory.make("gleffects_laplacian");
    public Gst.Element gldownload = Gst.ElementFactory.make("gldownload");
    public Gst.Element videoconvert = Gst.ElementFactory.make("videoconvert");
    public Gst.Element videoanalyze = Gst.ElementFactory.make("videoanalyse");
    public Gst.Element videoconvert2 = Gst.ElementFactory.make("videoconvert");
    public Gst.Element gtk4paintablesink = Gst.ElementFactory.make("gtk4paintablesink");

    public Gst.Element queue_passthrough = Gst.ElementFactory.make("queue");
    Gst.Pad sinkpad;
    Gst.Pad srcpad;

    public Gdk.Paintable get_paintable() {
        Gdk.Paintable paintable;
        gtk4paintablesink.get("paintable", out paintable);
        return paintable;
    }

    static construct {
        set_static_metadata(
                            "focusanalyze",
                            "Filter",
                            "Focus analyze video filter.",
                            "nekocwd@mainlining.org");

        add_static_pad_template(
        {
            "sink",
            Gst.PadDirection.SINK,
            Gst.PadPresence.ALWAYS,
            { null, "video/x-raw" }
        });
        add_static_pad_template(
        {
            "src",
            Gst.PadDirection.SRC,
            Gst.PadPresence.ALWAYS,
            { null, "video/x-raw" }
        });
    }

    public FocusAnalyze() {}

    construct {
        // Child elements
        add_many(tee, queue_analyze, glupload, laplacian, gldownload, videoconvert, videoanalyze, videoconvert2, gtk4paintablesink, queue_passthrough);
        tee.link_many(queue_analyze, glupload, laplacian, gldownload, videoconvert, videoanalyze, videoconvert2, gtk4paintablesink);
        tee.link_many(queue_passthrough);
        // Sink Pad
        sinkpad = new Gst.GhostPad("sink", tee.get_static_pad("sink"));
        add_pad(sinkpad);
        // Src Pad
        srcpad = new Gst.GhostPad("src", queue_passthrough.get_static_pad("src"));
        add_pad(srcpad);
    }
}
