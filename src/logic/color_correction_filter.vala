public class EyeNeko.Logic.Filters.CCM : GLFilter {
    public float red_in_red { get; set; default = 1.0f; }
    public float red_in_green { get; set; default = 0.1f; }
    public float red_in_blue { get; set; default = 0.1f; }

    public float green_in_red { get; set; default = 0.0f; }
    public float green_in_green { get; set; default = 0.8f; }
    public float green_in_blue { get; set; default = 0.0f; }

    public float blue_in_red { get; set; default = 0.1f; }
    public float blue_in_green { get; set; default = 0.1f; }
    public float blue_in_blue { get; set; default = 1.0f; }

    public CCM (string name = "CCM", bool glupload = false, bool gldownload = false) {
        base ("ccm", name, glupload, gldownload);
        update_props ();
        notify.connect (update_props);
    }

    private void update_props () {
        Gst.Structure uniforms = new Gst.Structure.empty ("uniforms");
        uniforms.set ("rr", typeof (float), red_in_red);
        uniforms.set ("rg", typeof (float), red_in_green);
        uniforms.set ("rb", typeof (float), red_in_blue);
        uniforms.set ("gr", typeof (float), green_in_red);
        uniforms.set ("gg", typeof (float), green_in_green);
        uniforms.set ("gb", typeof (float), green_in_blue);
        uniforms.set ("br", typeof (float), blue_in_red);
        uniforms.set ("bg", typeof (float), blue_in_green);
        uniforms.set ("bb", typeof (float), blue_in_blue);

        gl_shader.set_property ("uniforms", uniforms);
    }
}
