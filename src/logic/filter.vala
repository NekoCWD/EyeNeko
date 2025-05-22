namespace EyeNeko.Logic.Filters {
    public interface Filter : Object {
        public abstract Gst.Element element { get; }
    }
    public class GLFilter : Filter, Object {
        public static string get_shader_source (string name) {
            try {
                return (string) resources_lookup_data ("/io/gitlab/nekocwd/eyeneko/shaders/" + name + ".glsl", GLib.ResourceLookupFlags.NONE).get_data ();
            } catch (Error err) {
                warning ("Error during shader lookup. %s", err.message);
                return "";
            }
        }

        public Gst.Element element { get; }
        public Gst.Element gl_shader { get; }

        public GLFilter (string shader_name, string elem_name = "GLShader", bool glupload = false, bool gldownload = false) {
            var bin = new Gst.Bin (elem_name);
            var gl_upload = Gst.ElementFactory.make ("glupload", @"$(elem_name)-upload");
            var gl_download = Gst.ElementFactory.make ("gldownload", @"$(elem_name)-download");
            _gl_shader = Gst.ElementFactory.make ("glshader", @"$(elem_name)-shader");
            gl_shader.set_property ("fragment", GLFilter.get_shader_source (shader_name));
            if (glupload) {
                bin.add (gl_upload);
            }

            bin.add (gl_shader);

            if (gldownload) {
                bin.add (gl_download);
                gl_shader.link (gl_download);
            }

            if (glupload) {
                gl_upload.link (gl_shader);
            }

            EyeNeko.Gstreamer.add_pads_to_bin (ref bin);
            _element = bin;
        }
    }
}
