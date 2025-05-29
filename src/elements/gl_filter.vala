/* gl_filter.vala
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

public class EyeNeko.Elements.GLFilter : BinBase {
    public Gst.Element glshader = Gst.ElementFactory.make("glshader");

    construct {
        add_many(glshader);
        add_pads(glshader, glshader);
        notify.connect(update_uniforms);
        update_uniforms();
    }

    protected virtual void update_uniforms() {}

    protected void set_shader(string name) {
        glshader.set_property("fragment", get_shader_source(name));
    }

    public static string get_shader_source(string name) {
        try {
            return (string) resources_lookup_data("/io/gitlab/nekocwd/eyeneko/shaders/" + name + ".glsl", GLib.ResourceLookupFlags.NONE).get_data();
        } catch (Error err) {
            warning("Error during shader lookup. %s", err.message);
            return "";
        }
    }
}
