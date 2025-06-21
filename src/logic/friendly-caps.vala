namespace EyeNeko {
    public class FriendlyCaps : Object {
        public Gst.Caps caps { get;  construct set; }
        public enum Format {
            RAW,
            JPEG,
            UNKNOWN;
            // TODO: Add more formats

            public string to_string () {
                return ((EnumClass) typeof (Format).class_ref ()).get_value (this).value_nick.up ();
            }

            public string to_string_or (string detailed) {
                return this == UNKNOWN ? detailed : to_string ();
            }

            public static Format from_gst_name (string name) {
                switch (name) {
                case "video/x-raw":
                    return RAW;
                case "image/jpeg":
                    return JPEG;
                default:
                    return UNKNOWN;
                }
            }
        }

        public string format_name { get; default = ""; }
        public Format format { get; default = Format.UNKNOWN; }
        public int width { get; default = 0; }
        public int height { get; default = 0; }
        public float fps { get; default = 0f; }
        public string pixelformat { get; default = ""; }

        construct {
            caps.get_structure (0).get_int ("width", out _width);
            caps.get_structure (0).get_int ("height", out _height);
            _format_name = caps.get_structure (0).get_name ();
            _format = Format.from_gst_name (format_name);
            _pixelformat = caps.get_structure (0).get_string ("format"); int num, denom;
            caps.get_structure (0).get_fraction ("framerate", out num, out denom);
            if (denom == 0)
                denom = 1;
            _fps = num / denom;
        }

        public FriendlyCaps.with_caps (Gst.Caps caps) {
            if (caps.get_size () != 1) {
                warning ("Unsupported caps structute count (%u)", caps.get_size ());
                return;
            }
            Object (caps: caps);
        }

        public string to_string () {
            return "%s %dx%d %0.1f FPS %s".printf (format.to_string_or (format_name), width, height, fps, pixelformat ?? "");
        }

        public bool is_res_better (FriendlyCaps cap) {
            return (width * height > cap.width * cap.height);
        }

        public bool is_res_same (FriendlyCaps cap) {
            return (width * height == cap.width * cap.height);
        }

        public static int sort_func (FriendlyCaps a, FriendlyCaps b) {
            if (a.width > b.width)
                return -1;
            else if (a.width == b.width)
                return a.height > b.height ? -1 : a.height == b.height ? a.fps > b.fps ? -1 : a.fps == b.fps ? 0 : 1 : 1;
            else
                return 1;
        }

        public Gst.Caps to_caps () {
            return caps.copy ();
        }
    }
}
