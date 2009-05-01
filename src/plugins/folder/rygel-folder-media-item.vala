/*
 * Copyright (C) 2008-2009 Jens Georg <mail@jensge.org>.
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

using GLib;
using Rygel;
using Gst;

/**
 * Very simple media item. 
 */
public class Folder.FilesystemMediaItem : Rygel.MediaItem {
    private bool need_source;
    private string raw_uri;

    public FilesystemMediaItem(MediaContainer parent, 
                               File file, 
                               string item_class,
                               FileInfo file_info) {

        base(Checksum.compute_for_string(ChecksumType.MD5, file_info.get_name()), 
             parent,
             file_info.get_name(),
             item_class);

        var content_type = file_info.get_content_type();
        need_source = false;


        this.mime_type = content_type;
        // check if rygel can handle this uri type itself
        if (file.get_uri().has_prefix("file:") || 
            file.get_uri().has_prefix("http:")) {
            this.uris.add(GLib.Markup.escape_text(file.get_uri()));
        }
        else {
            need_source = true;
            raw_uri = file.get_uri();
        }
    }

    public override Gst.Element? create_stream_source() {
        if (need_source) {
            dynamic Element src = ElementFactory.make("giosrc", null);
            if (src != null) {
                src.is_live = true;
                src.location = raw_uri;
            }

            return src;
        }

        return null;
    }
}
