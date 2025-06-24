[GtkTemplate(ui = "/io/gitlab/nekocwd/eyeneko/ui/qr-row.ui")]
public class EyeNeko.Ui.QRRow : Gtk.Box {
    [GtkChild]
    private unowned Gtk.Label data;
    [GtkChild]
    private unowned Gtk.Button copy;

    public void set_qr(string qr) {
        data.label = qr;
    }

    construct {
        copy.clicked.connect(() => {
            data.get_clipboard().set_text(data.label);
        });
    }
}
