[GtkTemplate(ui = "/io/gitlab/nekocwd/eyeneko/ui/caps-row.ui")]
public class EyeNeko.Ui.CapsRow : Gtk.Box {
    [GtkChild]
    private unowned Gtk.Label resolution;
    [GtkChild]
    private unowned Gtk.Label fps;
    [GtkChild]
    private unowned Gtk.Label format;
    [GtkChild]
    private unowned Gtk.Label pixelformat;

    public void set_caps(FriendlyCaps caps) {
        resolution.label = "%dx%d".printf(caps.width, caps.height);
        fps.label = "%.0f".printf(caps.fps);
        format.label = caps.format.to_string_or(caps.format_name);
        pixelformat.label = caps.pixelformat;
    }
}
