public class EyeNeko.Elements.Downscale : Gst.Bin {
    public Gst.Element videoscale = Gst.ElementFactory.make("videoscale");
    public Gst.Element capsfilter = Gst.ElementFactory.make("capsfilter");
    Gst.Pad sinkpad;
    Gst.Pad srcpad;
    public int max_size { get; set; default = 0; }

    static construct {
        set_static_metadata(
                            "downscale",
                            "Filter",
                            "Downscale video filter.",
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

    static bool sink_event(Gst.Pad pad, Gst.Object? parent, owned Gst.Event event) {
        var filter = (Downscale) parent;
        if (event.type == Gst.EventType.CAPS) {
            Gst.Caps caps;
            event.parse_caps(out caps);
            var info = new Gst.Video.Info.with_caps(caps);
            var old_info = info.copy();
            var max_dim = int.max(info.width, info.height);
            if (filter.max_size > 0 && max_dim > filter.max_size) {
                double mult = (double) filter.max_size / (double) max_dim;
                info.width = (int) (info.width * mult);
                info.height = (int) (info.height * mult);
            }
            if (info.width % 2 > 0)
                info.width++;
            if (info.height % 2 > 0)
                info.height++;
            debug("%dx%d=S=>%dx%d", old_info.width, old_info.height, info.width, info.height);
            var new_caps = caps.copy();
            new_caps.set_simple("width", typeof (int), info.width);
            new_caps.set_simple("height", typeof (int), info.height);
            filter.capsfilter.set_property("caps", new_caps);
        }
        return pad.event_default(parent, event);
    }

    public Downscale() {}
    public Downscale.to(int max_size) {
        _max_size = max_size;
    }

    construct {
        // Child elements
        add_many(videoscale, capsfilter);
        videoscale.link(capsfilter);
        // Sink Pad
        sinkpad = new Gst.GhostPad("sink", videoscale.get_static_pad("sink"));
        sinkpad.set_event_function(sink_event, null, null);
        add_pad(sinkpad);
        // Src Pad
        srcpad = new Gst.GhostPad("src", capsfilter.get_static_pad("src"));
        add_pad(srcpad);
    }
}
