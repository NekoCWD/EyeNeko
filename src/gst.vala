
public class EyeNeko.Gstreamer : Object {
    public enum CameraBinMode {
        VIDEO = 2,
        PHOTO = 1,
    }

    public enum CameraMode {
        VIDEO,
        PHOTO,
        QR;

        public string to_string () {
            return ((EnumClass) typeof (CameraMode).class_ref ()).get_value (this).value_nick;
        }

        public static CameraMode parse (string data) {
            return ((EnumClass) typeof (CameraMode).class_ref ()).get_value_by_nick (data) ? .value ?? 0;
        }

        public CameraBinMode to_camerabin_mode () {
            return this == VIDEO ? CameraBinMode.VIDEO : CameraBinMode.PHOTO;
        }
    }

    private static Gee.HashMap<CameraMode, Gst.Caps> mode_caps = new Gee.HashMap<CameraMode, Gst.Caps> ();
    private static Gee.HashMap<CameraMode, int> mode_downscale = new Gee.HashMap<CameraMode, int> ();

    static construct {
        mode_caps[CameraMode.PHOTO] = new Gst.Caps.any ();
        mode_caps[CameraMode.VIDEO] = new Gst.Caps.any ();
        mode_caps[CameraMode.QR] = Gst.Caps.from_string ("video/x-raw, format=GRAY8");
        mode_downscale[CameraMode.VIDEO] = int.parse (Env.get_variable_or ("DOWNSCALE_VIDEO", "640"));
        mode_downscale[CameraMode.PHOTO] = int.parse (Env.get_variable_or ("DOWNSCALE_PHOTO", "0"));
        mode_downscale[CameraMode.QR] = int.parse (Env.get_variable_or ("DOWNSCALE_QR", "640"));
    }

    // Public properties
    public bool ready { get; set; default = false; }
    public CameraMode camera_mode { get; set; default = CameraMode.PHOTO; }
    public Gdk.Paintable viewfinder_paintable { get; set; }
    public ListStore available_caps = new ListStore (typeof (FriendlyCaps));
    public Gtk.SingleSelection caps_selecton_model = new Gtk.SingleSelection (null);


    // Private elements
    private Gst.Bin camerabin = (Gst.Bin) Gst.ElementFactory.make ("camerabin", "camerabin");
    private Gst.Element viewfinder = Gst.ElementFactory.make ("gtk4paintablesink", "paintablesink");
    private Gst.Bin camerasrc_wrapper = (Gst.Bin) Gst.ElementFactory.make ("wrappercamerabinsrc");
    private Elements.ColorCorrectionMatrix color_correction_matrix = new Elements.ColorCorrectionMatrix ();
    private Elements.Downscale downscale = new Elements.Downscale ();
    private Gst.Element camera_convert_caps = Gst.ElementFactory.make ("capsfilter");
    public Elements.QrScaner qr_scaner = new Elements.QrScaner ();

    // Other Fields
    public Camera current_camera = null;
    private bool can_start_stream = true;

    private void set_up_caps (Gst.Device device) {
        var caps = device.get_caps ();
        can_start_stream = false;
        available_caps.remove_all ();
        for (uint i = 0; i < caps.get_size (); i++) {
            var cap = new Gst.Caps.empty ();
            cap.append_structure (caps.get_structure (i).copy ());
            var fcap = new FriendlyCaps.with_caps (cap);
            available_caps.append (fcap);
        }
        can_start_stream = true;
        caps_selecton_model.selected = 0;
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
                var pwprovider = Gst.DeviceProviderFactory.get_by_name (Env.get_variable_or ("CAM_PROVIDER", "pipewiredeviceprovider"));
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
        var file_dir = Environment.get_user_special_dir (camera_mode == CameraMode.VIDEO ? UserDirectory.VIDEOS : UserDirectory.PICTURES);
        var dir = File.new_build_filename (file_dir, "EyeNeko");

        try {
            dir.make_directory ();
        } catch (IOError.EXISTS err) {
            // Ignore
        } catch (Error err) {
            warning ("Failed to create dirrectory `%s`: %s", dir.get_path (), err.message);
        }

        var time = new DateTime.now ();
        var formated = time.format ("%Y-%m-%d-%H-%M-%S");
        var filename = "%s.%s".printf (formated, camera_mode == CameraMode.VIDEO ? "mp4" : "jpeg");
        var location = Path.build_filename (dir.get_path (), filename);
        message ("Capturing %s", location);
        camerabin.set_property ("location", location);
        Gst.Debug.bin_to_dot_file (camerabin, Gst.DebugGraphDetails.ALL, current_camera.device.display_name);
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

    public void start_stream_from (Camera? camera) {
        if (!can_start_stream)
            return;
        message ("Stream stop");
        camerabin.set_state (Gst.State.NULL);

        if (camera == null)
            return;
        if (current_camera != camera) {
            current_camera = camera;
            set_up_caps (camera.device);
        }
        var caps = ((FriendlyCaps) caps_selecton_model.selected_item).to_caps ().to_string ();
        camerasrc_wrapper.set_property
            ("video-source",
            new Elements.CameraSrc (camera.device.create_element (null), Gst.Caps.from_string (Env.get_variable_or ("CAM_CAPS", caps))));
        camerabin.set_state (Gst.State.PLAYING);
        message ("Started stream with %s", caps);
    }

    private void add_enc_profile () {
        var cp = new Gst.PbUtils.EncodingContainerProfile (null, null, Gst.Caps.from_string ("video/quicktime"), null);
        var vp = new Gst.PbUtils.EncodingVideoProfile (Gst.Caps.from_string ("video/x-h264"), null, null, 0);
        if (bool.parse (Env.get_variable_or ("AUDIO_ENABLED", "true"))) {
            var ap = new Gst.PbUtils.EncodingAudioProfile (Gst.Caps.from_string (Env.get_variable_or ("AUDIO_PROFILE", "audio/x-ac3")), null, null, 0);
            cp.add_profile (ap);
        }
        cp.add_profile (vp);
        camerabin.set_property ("video-profile", cp);
    }

    construct {
        var srt = new Gtk.SortListModel (available_caps, new Gtk.CustomSorter ((a, b) => FriendlyCaps.sort_func ((FriendlyCaps) a, (FriendlyCaps) b)));
        var fmt = Environment.get_variable ("ONLY_FORMAT");
        if (fmt != null) {
            var filter = new Gtk.FilterListModel (srt, new Gtk.CustomFilter ((obj) => ((FriendlyCaps) obj).pixelformat == fmt));
            caps_selecton_model.set_model (filter);
        } else
            caps_selecton_model.set_model (srt);

        caps_selecton_model.notify["selected-item"].connect (() => start_stream_from (current_camera));
    }

    private bool is_initialised = false;
    public void init () {
        if (is_initialised) {
            warning ("Gstreamer init duplicated");
            return;
        }
        is_initialised = true;
        viewfinder.bind_property ("paintable", this, "viewfinder-paintable", GLib.BindingFlags.SYNC_CREATE);
        camerabin.set_property ("camera-source", camerasrc_wrapper);
        color_correction_matrix.red_in_red = 1f;
        color_correction_matrix.blue_in_blue = 1f;
        color_correction_matrix.green_in_green = 0.9f;

        camerasrc_wrapper.set_property ("video-source-filter",
                                        pipe_elements ("Camera Processing",
                                                       downscale,
                                                       Gst.ElementFactory.make ("videoconvert"),
                                                       camera_convert_caps,
                                                       qr_scaner,
                                                       Gst.ElementFactory.make ("videoconvert"),
                                                       Gst.ElementFactory.make ("glupload"),
                                                       color_correction_matrix,
                                                       Gst.ElementFactory.make ("gldownload")
        ));
        camerabin.set_property ("image-filter", Gst.ElementFactory.make ("videoconvert"));


        camerabin.set_property ("video-filter",
                                pipe_elements ("Video Processing",
                                               Gst.ElementFactory.make ("videoconvert"),
                                               Gst.parse_launch (Env.get_variable_or
                                                                 (
                                                                  "VIDEO_ENCODE",
                                                                  "x264enc tune=zerolatency speed-preset=ultrafast bitrate=8192"
                                                                 )
        )));

        camerabin.bind_property ("idle", this, "ready", BindingFlags.SYNC_CREATE);
        this.bind_property ("camera-mode", camerabin, "mode", BindingFlags.SYNC_CREATE, (b, s, ref d) => {
            d.set_enum (((CameraMode) s).to_camerabin_mode ());
            return true;
        });
        this.bind_property ("camera-mode", camera_convert_caps, "caps", BindingFlags.SYNC_CREATE, (b, s, ref d) => {
            d = mode_caps[((CameraMode) s)];
            return true;
        });
        this.bind_property ("camera-mode", downscale, "max-size", BindingFlags.SYNC_CREATE, (b, s, ref d) => {
            d = mode_downscale[((CameraMode) s)];
            return true;
        });
        this.bind_property ("camera-mode", qr_scaner, "enabled", BindingFlags.SYNC_CREATE, (b, s, ref d) => {
            d = (CameraMode) s == CameraMode.QR;
            return true;
        });

        notify["camera-mode"].connect (() => start_stream_from (current_camera));

        add_enc_profile ();

        Gdk.GLContext context;
        viewfinder_paintable.get ("gl-context", out context);
        if (context != null) {
            message ("GL supported <3");
            var gl_sink = Gst.ElementFactory.make ("glsinkbin");
            gl_sink.set_property ("sink", viewfinder);
            camerabin.set_property ("viewfinder-sink", gl_sink);
        } else {
            warning ("GL NOT supported. Viewfinder will be slow as shit");
            camerabin.set_property ("viewfinder-sink", viewfinder);
        }

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
        case Gst.MessageType.WARNING :
            GLib.Error err;
            string debug;
            message.parse_warning (out err, out debug);
            GLib.warning ("Warning: %s %s %s", err.message, err.domain.to_string (), debug);
            break;
        case Gst.MessageType.ERROR:
            GLib.Error err;
            string debug;
            message.parse_error (out err, out debug);
            GLib.warning ("Error: %s %s %s", err.message, err.domain.to_string (), debug);
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
}
