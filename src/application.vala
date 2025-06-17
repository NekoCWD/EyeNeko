/* application.vala
 *
 * Copyright 2025 Vasiliy Doylov <nekocwd@mainlining.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class EyeNeko.Application : Adw.Application {
    public Application () {
        Object (
                application_id: "io.gitlab.nekocwd.eyeneko",
                flags: ApplicationFlags.DEFAULT_FLAGS,
                resource_base_path: "/io/gitlab/nekocwd/eyeneko"
        );
    }

    construct {
        ActionEntry[] action_entries = {
            { "about", this.on_about_action },
            { "preferences", this.on_preferences_action },
            { "quit", this.quit }
        };
        this.add_action_entries (action_entries, this);
        this.set_accels_for_action ("app.quit", { "<primary>q" });
    }

    public override void activate () {
        base.activate ();
        var win = this.active_window ?? new EyeNeko.Window (this);
        win.present ();
        var styling = new Gtk.CssProvider ();
        styling.load_from_resource ("/io/gitlab/nekocwd/eyeneko/style.css");
        Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (),
                                                   styling,
                                                   Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    private void on_about_action () {
        string[] developers = {
            "Vasiliy Doylov (NekoCWD) <nekocwd@mainlining.org>",
        };
        string[] artists = {
            "Jaymz665 <jaymz665@gmail.com>",
        };
        var about = new Adw.AboutDialog () {
            application_name = "EyeNeko",
            application_icon = "io.gitlab.nekocwd.eyeneko",
            developer_name = "NekoCWD",
            translator_credits = _("translator-credits"),
            version = Config.PACKAGE_VERSION,
            developers = developers,
            copyright = "© 2025 Vasiliy Doylov nekocwd@mainlining.org",
            website = "https://git.nekocwd.duckdns.org/NekoCWD/EyeNeko",
            artists = artists,
        };

        about.present (this.active_window);
    }

    private void on_preferences_action () {
        message ("app.preferences action activated");
    }
}
