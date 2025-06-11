
public class EyeNeko.Gstreamer : Object {
    public enum CameraBinMode {
        VIDEO = 2,
        PHOTO = 1,
    }
    // Public properties
    public bool ready { get; set; default = false; }
    public CameraBinMode camerabin_mode { get; set; default = CameraBinMode.PHOTO; }

    public Gdk.Paintable viewfinder_paintable {
        owned get {
            Gdk.Paintable paintable;
            viewfinder.get ("paintable", out paintable);
            return paintable;
        }
    }

    // Private elements
    private Gst.Bin camerabin = (Gst.Bin) Gst.ElementFactory.make ("camerabin", "camerabin");

    private Gst.Element viewfinder = Gst.ElementFactory.make ("gtk4paintablesink", "paintablesink");

    private Gst.Bin camerasrc_wrapper = (Gst.Bin) Gst.ElementFactory.make ("wrappercamerabinsrc");
    private Elements.ColorCorrectionMatrix color_correction_matrix = new Elements.ColorCorrectionMatrix ();
    private Elements.Downscale downscale = new Elements.Downscale ();


    public Camera current_camera = null;
    public int downscale_video_to = int.parse (Env.get_variable_or ("DOWNSCALE_VIDEO", "640"));
    public int downscale_photo_to = int.parse (Env.get_variable_or ("DOWNSCALE_PHOTO", "0"));
    public delegate int SelectStreamCB (Gst.Element decodebin, Gst.StreamCollection collection, Gst.Stream stream, void* userdata);


    Gst.Caps get_best_caps (Gst.Device device) {
        int max_w = 0;
        int max_h = 0;
        float max_fps = 0;
        string max_format = "";

        Gst.Structure max_caps = null;
        var caps = device.get_caps ();
        for (uint i = 0; i < caps.get_size (); i++) {
            var format = caps.get_structure (i).get_name ();
            int num = 1, denom = 1, width, height;
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
        var home_dir = Environment.get_home_dir ();
        var file_dir = Path.build_filename (home_dir, camerabin_mode == CameraBinMode.VIDEO ? "Videos" : "Pictures", "EyeNeko");
        var dir = File.new_for_path (file_dir);
        if (!dir.query_exists ()) {
            dir.make_directory ();
        }
        var time = new DateTime.now ();
        var formated = time.format ("%Y-%m-%d-%H-%M-%S");
        var filename = @"$formated.$(camerabin_mode==CameraBinMode.VIDEO?"mp4":"jpeg")";
        var location = Path.build_filename (file_dir, filename);
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

    public void start_stream_from (Camera camera) {
        camerabin.set_state (Gst.State.NULL);

        current_camera = camera;
        camerasrc_wrapper.set_property
            ("video-source",
            new Elements.CameraSrc (camera.device.create_element (null),
                                    get_best_caps (camera.device)));
        camerabin.set_state (Gst.State.PLAYING);
    }

    private void add_enc_profile () {
        var cp = new Gst.PbUtils.EncodingContainerProfile (null, null, Gst.Caps.from_string ("video/quicktime"), null);
        var vp = new Gst.PbUtils.EncodingVideoProfile (Gst.Caps.from_string ("video/x-h264"), null, null, 0);
        var ap = new Gst.PbUtils.EncodingAudioProfile (Gst.Caps.from_string ("audio/x-ac3"), null, null, 0);
        cp.add_profile (vp);
        cp.add_profile (ap);
        camerabin.set_property ("video-profile", cp);
    }

    public void init (ref weak string[] args) {
        Gst.init (ref args);
        camerabin.set_property ("camera-source", camerasrc_wrapper);
        camerabin.set_property ("viewfinder-sink", viewfinder);
        color_correction_matrix.red_in_red = 1f;
        color_correction_matrix.red_in_blue = 0.1f;
        color_correction_matrix.red_in_green = 0.1f;
        color_correction_matrix.blue_in_red = 0.1f;
        color_correction_matrix.blue_in_blue = 1f;
        color_correction_matrix.blue_in_green = 0.1f;
        color_correction_matrix.green_in_green = 0.8f;

        camerasrc_wrapper.set_property ("video-source-filter",
                                        pipe_elements ("Camera Processing",
                                                       Gst.ElementFactory.make ("videoconvert"),
                                                       Gst.ElementFactory.make ("glupload"),
                                                       color_correction_matrix,
                                                       downscale,
                                                       Gst.ElementFactory.make ("gldownload")
        ));
        camerabin.set_property ("image-filter", Gst.ElementFactory.make ("queue"));


        camerabin.set_property ("video-filter",
                                pipe_elements ("Video Processing",
                                               Gst.ElementFactory.make ("queue"),
                                               Gst.ElementFactory.make ("videoconvert"),
                                               Gst.parse_launch (Env.get_variable_or
                                                                 (
                                                                  "VIDEO_ENCODE",
                                                                  "x264enc tune=zerolatency speed-preset=ultrafast bitrate=8192"
                                                                 )
        )));

        camerabin.bind_property ("idle", this, "ready", BindingFlags.SYNC_CREATE);
        this.bind_property ("camerabin-mode", camerabin, "mode");
        add_enc_profile ();

        notify["camerabin-mode"].connect (() => {
            downscale.max_size = camerabin_mode == CameraBinMode.VIDEO ? downscale_video_to : downscale_photo_to;
            start_stream_from (current_camera);
        });

        camerabin.bus.add_watch (0, bus_callback);
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
            GLib.warning ("Error: %s %s", err.message, err.domain.to_string ());
            break;
        case Gst.MessageType.EOS:
            GLib.warning ("End of stream\n");
            break;
        case Gst.MessageType.STATE_CHANGED:
            Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;
            message.parse_state_changed (out oldstate, out newstate,
                                         out pending);
            /*
               GLib.message ("state changed: %s->%s:%s\n",
                          oldstate.to_string (), newstate.to_string (),
                          pending.to_string ());
             */
            break;
        case Gst.MessageType.ELEMENT:
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

    static construct {
        unowned string[] ? gst_args = null;
        Gst.init (ref gst_args);
    }
}
