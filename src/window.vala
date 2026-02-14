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
using EyeNeko.Ui;
[GtkTemplate (ui = "/io/gitlab/nekocwd/eyeneko/window.ui")]
public class EyeNeko.Window : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Gtk.Overlay overlay;
    [GtkChild]
    private unowned Adw.ToolbarView toolbar;
    [GtkChild]
    private unowned Gtk.Picture viewfinder;
    [GtkChild]
    private unowned Gtk.MenuButton video_source_btn;
    [GtkChild]
    private unowned Gtk.MenuButton video_caps_btn;
    [GtkChild]
    private unowned Gtk.Button capture_btn;
    [GtkChild]
    private unowned Adw.ToggleGroup camera_mode;
    [GtkChild]
    private unowned Gtk.SignalListItemFactory qr_factory;
    [GtkChild]
    private unowned Gtk.StringList qr_list;
    [GtkChild]
    private unowned Adw.Dialog qr_dialog;

    public string camera_path { get; set; default = "Unknown"; }
    public string current_caps { get; set; default = "Unknown"; }

    private void setup_video_source_changer () {
        notify["camera-path"].connect (() => {
            foreach (var camera in Gstreamer.get_cameras ()) {
                if (camera.get_path_string () == camera_path) {
                    info ("Switching to: %s", camera.name);
                    Gstreamer.instance.start_stream_from (camera);
                    return;
                }
            }
            warning ("Camera switching: Camera not found: %s", camera_path);
        });

        if (Gstreamer.get_cameras ().length > 0)
            camera_path = Gstreamer.get_cameras ()[int.parse (Env.get_variable_or ("CAM_N", "0"))].get_path_string ();

        var change_video_source_action = new PropertyAction ("change-video-source", this, "camera-path");
        add_action (change_video_source_action);


        var sources_menu = new Menu ();
        foreach (var camera in Gstreamer.get_cameras ()) {
            var item = new MenuItem (camera.display_name, null);
            item.set_action_and_target_value ("win.change-video-source", camera.get_path_string ());
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

    Gtk.Popover popover = null;
    void setup_caps_changer () {
        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect ((mdl) => {
            var item = (Gtk.ListItem) mdl;
            item.child = new CapsRow ();
        });
        factory.bind.connect ((mdl) => {
            var item = (Gtk.ListItem) mdl;
            var row = (CapsRow) item.child;
            var data = (FriendlyCaps) item.item;
            row.set_caps (data);
        });

        popover = new Gtk.Popover () {
            child = new Gtk.ScrolledWindow () {
                css_classes = { "caps-list" },
                child = new Gtk.ListView (Gstreamer.instance.caps_selecton_model, factory) {
                    css_classes = { "caps-list" },
                },
                propagate_natural_width = true,
                propagate_natural_height = true,
                max_content_height = 300,
            },
        };
        video_caps_btn.set_popover (popover);
    }

    private void setup_qr_scaner () {
        qr_factory.setup.connect ((mdl) => {
            var item = (Gtk.ListItem) mdl;
            item.child = new QRRow ();
        });
        qr_factory.bind.connect ((mdl) => {
            var item = (Gtk.ListItem) mdl;
            var row = (QRRow) item.child;
            var data = (Gtk.StringObject) item.item;
            row.set_qr (data.string);
        });
        Gstreamer.instance.qr_scaner.new_qr.connect ((qr) => {
            qr_list.append (qr);
            qr_dialog.present (this);
        });
    }

    private void shot () {
        switch (Gstreamer.instance.camera_mode) {
        case Gstreamer.CameraMode.QR:
            qr_dialog.present (this);
            break;
        case Gstreamer.CameraMode.VIDEO:
            if (Gstreamer.instance.ready)
                Gstreamer.instance.start_capture ();
            else
                Gstreamer.instance.stop_capture ();
            break;
        default:
            Gstreamer.instance.start_capture ();
            break;
        }
    }

    public Window (Gtk.Application app) {
        Object (application: app);
        overlay.add_overlay (toolbar);
        add_action_entries ({
            { "shot", this.shot }
        }, this);

        Gstreamer.instance.bind_property ("viewfinder-paintable", viewfinder, "paintable", BindingFlags.SYNC_CREATE);

        setup_video_source_changer ();
        setup_caps_changer ();
        setup_qr_scaner ();

        close_request.connect (() => {
            Gstreamer.instance.start_stream_from (null);
            return false;
        });

        camera_mode.bind_property ("active-name", Gstreamer.instance, "camera-mode", BindingFlags.SYNC_CREATE, (b, s, ref d) => {
            d = Gstreamer.CameraMode.parse (s.get_string ());
            return true;
        });
        camera_mode.active_name = Env.get_variable_or ("CAM_M", "photo");
    }
}
