/*
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 *
 * Author: Neha Shanbhag <N.Shanbhag@cablelabs.com>
 * Contact: http://www.cablelabs.com/
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

using Rygel;
using Gee;

internal class Rygel.Ruih.Plugin : Rygel.RuihServerPlugin {
    public const string NAME = "Ruih";

    public Plugin () {
        string title;
        try {
            title = MetaConfig.get_default().get_string (Plugin.NAME,"title");
        } catch(Error err) {
            warning ("Setting default name for Ruih");
            title = "CableLabs CVP-2 RemoteUIServer";
        }
        base (Plugin.NAME, _(title));
    }

}
