/* window.vala
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

[GtkTemplate (ui = "/io/gitlab/nekocwd/eyeneko/window.ui")]
public class EyeNeko.Window : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Gtk.Overlay overlay;
    [GtkChild]
    private unowned Adw.ToolbarView toolbar;
    [GtkChild]
    private unowned Gtk.Picture viewfinder;
    [GtkChild]
    private unowned Gtk.Picture focus_overlay;
    [GtkChild]
    private unowned Gtk.MenuButton video_source_btn;
    [GtkChild]
    private unowned Gtk.Button capture_btn;
    [GtkChild]
    private unowned Adw.ToggleGroup camera_mode;

    [GtkChild]
    private unowned Gtk.Button focus_btn;
    [GtkChild]
    private unowned Gtk.Label focus_label;

    public string camera_path { get; set; default = "Unknown"; }
    private void setup_video_source_changer () {
        notify["camera-path"].connect (() => {
            message ("Camera switching P0: retrived camera path: %s", camera_path);
            foreach (var camera in Gstreamer.Camera.get_all ()) {
                if (camera.device.get_path_string () == camera_path) {
                    message ("Camera switching P1: camera found by path: %s", camera.name);
                    Gstreamer.instance.start_stream_from (camera);
                    return;
                }
            }
        });

        if (Gstreamer.Camera.get_all ().length > 0)
            camera_path = Gstreamer.Camera.get_all ()[0].device.get_path_string ();

        var change_video_source_action = new PropertyAction ("change-video-source", this, "camera-path");
        add_action (change_video_source_action);


        var sources_menu = new Menu ();
        foreach (var camera in Gstreamer.Camera.get_all ()) {
            var item = new MenuItem (camera.name, null);
            item.set_action_and_target_value ("win.change-video-source", camera.device.get_path_string ());
            sources_menu.append_item (item);
        }

        video_source_btn.set_menu_model (sources_menu);

        Gstreamer.instance.notify["ready"].connect (() => {
            if (!Gstreamer.instance.ready) {
                capture_btn.add_css_class ("recording");
            } else {
                capture_btn.remove_css_class ("recording");
            }
        });
    }

    public Window (Gtk.Application app) {
        Object (application: app);
        overlay.add_overlay (toolbar);
        overlay.add_overlay (focus_overlay);


        setup_video_source_changer ();

        Gstreamer.instance.bind_property ("focus-paintable", focus_overlay, "paintable", BindingFlags.SYNC_CREATE);

        viewfinder.set_paintable (Gstreamer.instance.viewfinder_paintable);
        Gstreamer.instance.start_stream_from (Gstreamer.Camera.get_all ()[0]);
        var ec = new Gtk.GestureClick ();
        overlay.add_controller (ec);
        ec.pressed.connect ((n, x, y) => {
            if (!viewfinder.contains (x, y))
                return;
            var width = x / viewfinder.get_width ();
            var height = y / viewfinder.get_height ();

            Gstreamer.instance.focus_analyze.window_hpos = height;
            Gstreamer.instance.focus_analyze.window_wpos = width;
        });
        ec.button = 0;


        focus_btn.clicked.connect (AutoFocus.instance.reset_focus);
        AutoFocus.instance.bind_property ("prev_pos", focus_label, "label", GLib.BindingFlags.SYNC_CREATE, (b, src, ref tgt) => { tgt = "%.1f".printf (src.get_double ()); return true; });

        capture_btn.clicked.connect (() => {
            message ("%d %d", Gstreamer.instance.camerabin_mode, (int) Gstreamer.instance.ready);
            if (Gstreamer.instance.camerabin_mode == Gstreamer.CameraBinMode.VIDEO && !Gstreamer.instance.ready) {
                Gstreamer.instance.stop_capture ();
            } else {
                Gstreamer.instance.start_capture ();
            }
        });

        camera_mode.notify["active"].connect (() => {
            switch (camera_mode.active_name) {
                case "photo":
                    Gstreamer.instance.camerabin_mode = Gstreamer.CameraBinMode.PHOTO;
                    break;
                case "video":
                    Gstreamer.instance.camerabin_mode = Gstreamer.CameraBinMode.VIDEO;
                    break;
                default:
                    break;
            }
        });
    }
}
