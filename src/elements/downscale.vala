public class EyeNeko.Elements.Downscale : Gst.Bin {
    Gst.Element videoscale = Gst.ElementFactory.make("videoscale");
    Gst.Element capsfilter = Gst.ElementFactory.make("capsfilter");
    Gst.Pad sinkpad;
    Gst.Pad srcpad;

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
        message("MEOW MEOW MEOW %s", event.type.get_name());
        if (event.type == Gst.EventType.CAPS) {
            Gst.Caps caps;
            event.parse_caps(out caps);
            var info = new Gst.Video.Info.with_caps(caps);
            message("%d %d", info.width, info.height);
        }
        return pad.event_default(parent, event);
    }

    private bool _query(Gst.Query query) {
        message("MMM %s", query.type.get_name());
        return base.query(query);
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
