
public class EyeNeko.Gstreamer : Object {
    public enum CameraMode {
        VIDEO,
        PHOTO,
        QR;

        public static CameraMode parse (string data) {
            return ((EnumClass) typeof (CameraMode).class_ref ()).get_value_by_nick (data) ? .value ?? 0;
        }
    }

    // Public properties
    public bool ready { get; set; default = false; }
    public CameraMode camera_mode { get; set; default = CameraMode.PHOTO; }
    public Gdk.Paintable viewfinder_paintable { get; set; }
    public ListStore available_caps = new ListStore (typeof (FriendlyCaps));
    public Gtk.SingleSelection caps_selecton_model = new Gtk.SingleSelection (null);


    // Private elements
    private Gst.Pipeline pipeline = new Gst.Pipeline ("EyeNeko");
    private NekoTee.Tee tee = new NekoTee.Tee ();
    private Elements.CameraSrc? camerasrc = null;
    private Gst.Element viewfinder = Gst.ElementFactory.make ("gtk4paintablesink", "paintablesink");

    public Gst.Device current_camera = null;

    private void set_up_caps (Gst.Device device) {
        var caps = device.get_caps ();
        available_caps.remove_all ();
        for (uint i = 0; i < caps.get_size (); i++) {
            var cap = new Gst.Caps.empty ();
            cap.append_structure (caps.get_structure (i).copy ());
            var fcap = new FriendlyCaps.with_caps (cap);
            available_caps.append (fcap);
        }
        caps_selecton_model.selected = 0;
    }

    /**
     * Cameras could be lazy-loaded somehow
     */
    private static Gst.Device[] cameras = null;
    /**
     * Get all the cameras of default deviceprovider
     *
     * To treat device as camera, it should have Video/Source class
     */
    public static Gst.Device[] get_cameras () {
        if (cameras == null) {
            cameras = new Gst.Device[0];
            var pwprovider = Gst.DeviceProviderFactory.get_by_name (
                Env.get_variable_or ("CAM_PROVIDER", "pipewiredeviceprovider")
            );
            pwprovider.start ();
            foreach (var device in pwprovider.get_devices ()) {
                if (device.has_classes ("Video/Source")) {
                    cameras += device;
                    message ("Camera appended %s:", device.display_name);
                }
            }
        }
        return cameras;
    }

    public void start_capture () {
        var file_dir = Environment.get_user_special_dir (
            camera_mode == CameraMode.VIDEO ? UserDirectory.VIDEOS : UserDirectory.PICTURES
        );
        var dir = File.new_build_filename (file_dir, "EyeNeko");

        try {
            dir.make_directory ();
        } catch (IOError.EXISTS err) {
            // Ignore
        } catch (Error err) {
            warning (
                "Failed to create dirrectory `%s`: %s",
                dir.get_path (),
                err.message
            );
        }

        var time = new DateTime.now ();
        var formated = time.format ("%Y-%m-%d-%H-%M-%S");
        var filename = "%s.%s".printf (
            formated,
            camera_mode == CameraMode.VIDEO ? "mp4" : "jpeg"
        );
        var location = Path.build_filename (dir.get_path (), filename);
        message ("Capturing %s", location);
        // camerabin.set_property ("location", location);
        // Gst.Debug.bin_to_dot_file (camerabin, Gst.DebugGraphDetails.ALL, current_camera.device.display_name);
        // Signal.emit_by_name (camerabin, "start-capture");
    }

    public void stop_capture () {
        // Signal.emit_by_name (camerabin, "stop-capture");
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

    public void start_stream_from (Gst.Device? camera) {
        info ("Stopping stream");
        pipeline.set_state (Gst.State.NULL);
        info ("Trying to start stream from %s", camera ? .display_name ?? "NULL");

        if (camera == null) {
            info ("Won't start stream: camera is null");
            return;
        }
        if (current_camera != camera) {
            info ("Won't start stream: camera switched -> changing caps");
            current_camera = camera;
            set_up_caps (camera);
            return;
        }

        var caps = (FriendlyCaps) caps_selecton_model.selected_item;
        if (caps == null) {
            info ("Won't start stream: caps not selected");
            return;
        }
        if (camerasrc != null) {
            camerasrc.unlink (tee);
            camerasrc.set_state (Gst.State.NULL);
            pipeline.remove (camerasrc);
        }
        camerasrc = new Elements.CameraSrc (
            camera.create_element (null),
            Gst.Caps.from_string (
                Env.get_variable_or (
                    "CAM_CAPS", caps.to_caps ().to_string ()
                )
            )
        );
        pipeline.add (camerasrc);
        camerasrc.link (tee);

        debug ("Negotiated caps: %s", caps.to_caps ().to_string ());
        message ("Starting from %s (%s)", camera.name, caps.to_string ());
        pipeline.set_state (Gst.State.PLAYING);
    }

    construct {
        var srt = new Gtk.SortListModel (available_caps, new Gtk.CustomSorter ((a, b) => FriendlyCaps.sort_func ((FriendlyCaps) a, (FriendlyCaps) b)));
        var fmt = Environment.get_variable ("ONLY_FORMAT");
        if (fmt != null) {
            var filter = new Gtk.FilterListModel (srt, new Gtk.CustomFilter ((obj) => ((FriendlyCaps) obj).pixelformat == fmt));
            caps_selecton_model.set_model (filter);
        } else
            caps_selecton_model.set_model (srt);
        caps_selecton_model.autoselect = false;
        caps_selecton_model.notify["selected-item"].connect (() => start_stream_from (current_camera));
        pipeline.add (tee);
    }

    private bool is_initialised = false;
    public void init () {
        if (is_initialised) {
            warning ("Gstreamer init duplicated");
            return;
        }
        is_initialised = true;
        viewfinder.bind_property ("paintable", this, "viewfinder-paintable", GLib.BindingFlags.SYNC_CREATE);
        notify["camera-mode"].connect (() => start_stream_from (current_camera));

        Gdk.GLContext context;
        viewfinder_paintable.get ("gl-context", out context);
        if (context != null) {
            message ("GL supported <3");
            var gl_sink = Gst.ElementFactory.make ("glsinkbin");
            gl_sink.set_property ("sink", viewfinder);
            tee.add_child (new NekoTee.TeeChild ("viewfinder", gl_sink));
        } else {
            warning ("GL NOT supported. Viewfinder will be slow as shit");
            tee.add_child (new NekoTee.TeeChild ("viewfinder", viewfinder));
        }

        pipeline.bus.add_watch (0, bus_callback);
    }

    public static void add_pads_to_bin (ref Gst.Bin bin, bool src = true, bool sink = true) {
        if (src)
            bin.add_pad (new Gst.GhostPad ("src", ((Gst.Element) bin.get_child_by_index (0)).get_static_pad ("src")));
        if (sink)
            bin.add_pad (new Gst.GhostPad ("sink", ((Gst.Element) bin.get_child_by_index (bin.get_children_count () - 1)).get_static_pad ("sink")));
    }

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        var from = "IDK";
        if (message.src is Gst.Element) {
            var element = (Gst.Element) message.src;
            from = element.name;
        }
        switch (message.type) {
        case Gst.MessageType.WARNING :
            GLib.Error err;
            string debug;
            message.parse_warning (out err, out debug);
            warning (
                "%s -> warning: %s %s %s",
                from,
                err.message,
                err.domain.to_string (),
                debug
            );
            break;
        case Gst.MessageType.ERROR :
            GLib.Error err;
            string debug;
            message.parse_error (out err, out debug);
            warning (
                "%s -> error: %s %s %s",
                from,
                err.message,
                err.domain.to_string (),
                debug
            );
            break;
        case Gst.MessageType.EOS :
            warning (
                "%s -> end of stream",
                from
            );
            break;
        case Gst.MessageType.STATE_CHANGED :
            Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;
            message.parse_state_changed (out oldstate, out newstate,
                                         out pending);
            if (message.src is Gst.Element) {
                debug (
                    "%s -> state changed: %s->%s:%s\n",
                    from,
                    oldstate.to_string (), newstate.to_string (),
                    pending.to_string ()
                );
            } else {
                warning ("WTF? State change not from element");
            }

            break;
        case Gst.MessageType.ELEMENT:
            break;
        default:
            break;
        }

        return true;
    }

    private Gstreamer () {}

    private static Gstreamer _instance = null;
    public static Gstreamer instance {
        get {
            if (_instance == null)
                _instance = new Gstreamer ();
            return _instance;
        }
    }
}
