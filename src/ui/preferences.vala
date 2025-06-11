public class EyeNeko.Ui.Settings : Adw.PreferencesDialog {
    private Adw.PreferencesPage cameras = new Adw.PreferencesPage ();
    construct {
        cameras.title = _("Cameras");
    }
}
