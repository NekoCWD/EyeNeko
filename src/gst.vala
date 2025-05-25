
public class EyeNeko.Gstreamer : Object {
    public Gst.Element viewfinder;
    private Gst.Bin camerabin;
    public enum CameraBinMode {
        VIDEO = 2,
        PHOTO = 1,
    }
    public bool ready { get; set; default = false; }
    public CameraBinMode camerabin_mode { get; set; default = CameraBinMode.PHOTO; }

    Gst.Caps get_best_caps (Gst.Device device) {
        int max_w = 0;
        int max_h = 0;
        float max_fps = 0;
        string max_format = "";

        Gst.Structure max_caps = null;
        var caps = device.get_caps ();
        for (uint i = 0; i < caps.get_size (); i++) {
            var format = caps.get_structure (i).get_name ();
            int num, denom, width, height;
            if (caps.get_structure (i).get_field_type ("width") != typeof (int) || caps.get_structure (i).get_field_type ("height") != typeof (int)) {
                warning ("Can't find best caps :(. I hate arrays!");
            }
            caps.get_structure (i).get_int ("width", out width);
            caps.get_structure (i).get_int ("height", out height);
            caps.get_structure (i).get_fraction ("framerate", out num, out denom);
            if (denom == 0)
                denom = 1;
            var fps = num / denom;
            if (max_caps == null || (width > max_w && height > max_h) || (width == max_w && height == max_h && fps > max_fps)) {
                max_w = width;
                max_h = height;
                max_caps = caps.get_structure (i).copy ();
                max_fps = fps;
                max_format = format;
            }
        }
        var best_cap = new Gst.Caps.empty ();
        best_cap.append_structure (max_caps.copy ());
        message ("%s %dx%d %f (%s)", max_format, max_w, max_h, max_fps, best_cap.to_string ());
        return best_cap;
    }

    Gst.Caps get_downscale_caps (Camera camera, int max_size) {
        int w = 0, h = 0;
        var caps = get_best_caps (camera.device);
        var struct = caps.get_structure (0).copy ();
        struct.get_int ("width", out w);
        struct.get_int ("height", out h);
        struct = new Gst.Structure.empty ("video/x-raw");
        var max_dim = int.max (w, h);
        double mult = 1;
        if (max_dim > max_size) {
            mult = max_size / (double) max_dim;
        }
        struct.set ("width", typeof (int), (int) (w * mult));
        struct.set ("height", typeof (int), (int) (h * mult));

        caps = new Gst.Caps.empty ();
        caps.append_structure (struct.copy ());
        return caps;
    }

    public class Camera : Object {
        public string name { owned get { return device.display_name; } }
        public Gst.Device device { get; }

        private Camera (Gst.Device device) {
            _device = device;
        }

        private static Camera[] cameras = null;
        public static Camera[] get_all () {
            if (cameras == null) {
                cameras = new Camera[0];
                var pwprovider = Gst.DeviceProviderFactory.get_by_name ("pipewiredeviceprovider");
                pwprovider.start ();
                foreach (var device in pwprovider.get_devices ()) {
                    if (device.has_classes ("Video/Source")) {
                        cameras += new Camera (device);
                        message ("Camera appended %s:", device.display_name);
                    }
                }
            }
            return cameras;
        }
    }

    public void start_capture () {
        var time = new DateTime.now ();
        var formated = time.format ("%Y-%m-%d-%H-%M-%S");
        var location = @"$formated.$(camerabin_mode==CameraBinMode.VIDEO?"mp4":"png")";
        message ("Capturing %s", location);
        camerabin.set_property ("location", location);
        Signal.emit_by_name (camerabin, "start-capture");
    }

    public void stop_capture () {
        Signal.emit_by_name (camerabin, "stop-capture");
    }

    public Gst.Bin pipe_elements (string? name = null, ...) {
        var bin = new Gst.Bin (name);
        var args = va_list ();
        Gst.Element prev_elem = null;
        for (Gst.Element elem = args.arg (); elem != null; elem = args.arg ()) {
            bin.add (elem);
            if (prev_elem != null)
                prev_elem.link (elem);
            prev_elem = elem;
        }
        add_pads_to_bin (ref bin);
        return bin;
    }

    public Gst.Bin make_downscale_filter (Camera camera, int max_size) {
        var videoscale = Gst.ElementFactory.make ("videoconvertscale");
        var capsfilt = Gst.ElementFactory.make ("capsfilter");
        capsfilt.set_property ("caps", get_downscale_caps (camera, max_size));
        return pipe_elements ("Downscale filter", videoscale, capsfilt);
    }

    public void start_stream_from (Camera camera) {
        var camerasrc = new Gst.Bin ("CameraSRC");

        var src = camera.device.create_element ("camerasrc");
        var caps = get_best_caps (camera.device);
        var capsfilt = Gst.ElementFactory.make ("capsfilter");
        capsfilt.set_property ("caps", caps);

        var db = Gst.ElementFactory.make ("decodebin3");
        var identity = Gst.ElementFactory.make ("identity");

        camerasrc.add_many (src, capsfilt, db, identity);
        src.link_many (capsfilt, db);
        db.pad_added.connect ((pad) => {
            if (pad.get_stream () != null && pad.get_stream ().stream_type == Gst.StreamType.VIDEO) {
                pad.link (identity.get_static_pad ("sink"));
            }
        });
        camerasrc.add_pad (new Gst.GhostPad ("src", identity.get_static_pad ("src")));

        var camerasrc_wrapper = Gst.ElementFactory.make ("wrappercamerabinsrc");
        camerasrc_wrapper.set_property ("video-source", camerasrc);
        camerasrc_wrapper.set_property ("video-source-filter",
                                        pipe_elements ("Camera filter",
                                                       make_downscale_filter (camera, 640),
                                                       new Logic.Filters.CCM ("CCM", true, true).element
        ));

        camerabin.set_property ("camera-source", camerasrc_wrapper);

        camerabin.set_state (Gst.State.NULL);
        camerabin.set_state (Gst.State.READY);

        camerabin.set_state (Gst.State.PAUSED);
        replace_videoencodebin ();
        camerabin.set_state (Gst.State.PLAYING);
        Gst.Debug.bin_to_dot_file ((Gst.Bin) camerabin, Gst.DebugGraphDetails.ALL, camera.name);
    }

    bool meow = false;
    public void replace_videoencodebin () {
        if (meow)
            return;
        meow = true;
        message ("Replacing Encodebin");
        var capsfilter = (Gst.Element) camerabin.get_child_by_name ("videobin-capsfilter");
        message ("capsfilter %s", capsfilter == null ? "IS NULL" : "OK");
        var encodebin = (Gst.Bin) camerabin.get_child_by_name ("video-encodebin");
        message ("enodebin %s", encodebin == null ? "IS NULL" : "OK");
        var filesink = (Gst.Element) camerabin.get_child_by_name ("videobin-filesink");
        message ("filesink %s", filesink == null ? "IS NULL" : "OK");
        capsfilter.unlink (encodebin);
        camerabin.remove (encodebin);

        var queue = Gst.ElementFactory.make ("queue");
        var x264enc = Gst.ElementFactory.make ("x264enc");
        var h264timestamper = Gst.ElementFactory.make ("h264timestamper");
        var mux = Gst.ElementFactory.make ("qtmux");
        encodebin = pipe_elements ("video-encodebin", queue, x264enc, h264timestamper, mux);


        camerabin.add (encodebin);
        capsfilter.link (encodebin);
        encodebin.link (filesink);
        message ("Encodebin replaced. Miaw <3");
    }

    private void add_enc_profile () {
        var cp = new Gst.PbUtils.EncodingContainerProfile (null, null, Gst.Caps.from_string ("video/quicktime"), null);
        var vp = new Gst.PbUtils.EncodingVideoProfile (Gst.Caps.from_string ("video/x-h264"), null, null, 0);
        // var ap = new Gst.PbUtils.EncodingAudioProfile (Gst.Caps.from_string ("audio/x-ac3"), null, null, 0);
        cp.add_profile (vp);
        // cp.add_profile (ap);
        camerabin.set_property ("video-profile", cp);
    }

    public void init (ref weak string[] args) {
        Gst.init (ref args);

        camerabin = (Gst.Bin) Gst.ElementFactory.make ("camerabin", "camerabin");
        camerabin.set_property ("video-filter", Gst.ElementFactory.make ("videoconvert"));
        camerabin.bind_property ("idle", this, "ready", BindingFlags.SYNC_CREATE);
        this.bind_property ("camerabin-mode", camerabin, "mode");
        add_enc_profile ();

        camerabin.bus.add_watch (0, bus_callback);
    }

    public Gdk.Paintable init_viewfinder () {
        Gdk.Paintable paintable;
        viewfinder = Gst.ElementFactory.make ("gtk4paintablesink", "paintablesink");
        viewfinder.get ("paintable", out paintable);
        camerabin.set_property ("viewfinder-sink", viewfinder);
        return paintable;
    }

    public static void add_pads_to_bin (ref Gst.Bin bin, bool src = true, bool sink = true) {
        if (src)
            bin.add_pad (new Gst.GhostPad ("src", ((Gst.Element) bin.get_child_by_index (0)).get_static_pad ("src")));
        if (sink)
            bin.add_pad (new Gst.GhostPad ("sink", ((Gst.Element) bin.get_child_by_index (bin.get_children_count () - 1)).get_static_pad ("sink")));
    }

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
        case Gst.MessageType.ERROR:
            GLib.Error err;
            string debug;
            message.parse_error (out err, out debug);
            GLib.warning ("Error: %s", err.message);
            break;
        case Gst.MessageType.EOS:
            GLib.warning ("end of stream\n");
            break;
        case Gst.MessageType.STATE_CHANGED:
            Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;
            message.parse_state_changed (out oldstate, out newstate,
                                         out pending);
            // GLib.message ("state changed: %s->%s:%s\n",
            // oldstate.to_string (), newstate.to_string (),
            // pending.to_string ());
            break;
        case Gst.MessageType.TAG:
            Gst.TagList tag_list;
            stdout.printf ("taglist found\n");
            message.parse_tag (out tag_list);
            break;
        case Gst.MessageType.ELEMENT:
            if (message.get_structure ().get_name () == "GstVideoAnalyse") {
                double val;
                message.get_structure ().get_double ("luma-average", out val);
                // af.adjust_step (val);
            }
            break;
        default:
            break;
        }

        return true;
    }

    private Gstreamer () {
    }

    private static Gstreamer _instance = null;
    public static Gstreamer instance {
        get {
            if (_instance == null)
                _instance = new Gstreamer ();
            return _instance;
        }
    }
}
