/*
 * This file is part of Rygel.
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

using Gst;
using Gst.PbUtils;

internal class Rygel.TranscodingGstDataSource : Rygel.GstDataSource {
    private const string DECODE_BIN = "decodebin";
    private const string ENCODE_BIN = "encodebin";

    dynamic Element decoder;
    dynamic Element encoder;
    private bool link_failed = true;

    public TranscodingGstDataSource(DataSource src, EncodingProfile profile) throws Error {
        var bin = new Bin ("transcoder-source");
        base.from_element (bin);

        var orig_source = (GstDataSource) src;

        this.decoder = GstUtils.create_element (DECODE_BIN, DECODE_BIN);
        this.encoder = GstUtils.create_element (ENCODE_BIN, ENCODE_BIN);

        this.encoder.profile = profile;
        if (encoder.profile == null) {
            var message = _("Could not create a transcoder configuration. Your GStreamer installation might be missing a plug-in");

            throw new GstTranscoderError.CANT_TRANSCODE (message);
        }

        debug ("%s using the following encoding profile:",
               this.get_class ().get_type ().name ());
               GstUtils.dump_encoding_profile (encoder.profile);

        bin.add_many (orig_source.src, decoder, encoder);

        orig_source.src.link (decoder);

        decoder.autoplug_continue.connect (this.on_decode_autoplug_continue);
        decoder.pad_added.connect (this.on_decoder_pad_added);
        decoder.no_more_pads.connect (this.on_no_more_pads);

        var pad = encoder.get_static_pad ("src");
        var ghost = new GhostPad (null, pad);
        bin.add_pad (ghost);
    }

    private Gst.Pad? get_compatible_sink_pad (Pad pad, Caps caps) {
        var sinkpad = this.encoder.get_compatible_pad (pad, null);

        if (sinkpad == null) {
            Signal.emit_by_name (this.encoder, "request-pad", caps, out sinkpad);
        }

        if (sinkpad == null) {
            debug ("No compatible encodebin pad found for pad '%s', ignoring...",
                   pad.name);
        }

        return sinkpad;
    }

    private bool on_decode_autoplug_continue (Element decodebin,
                                              Pad     new_pad,
                                              Caps    caps) {
        return this.get_compatible_sink_pad (new_pad, caps) == null;
    }

    private void on_decoder_pad_added (Element decodebin, Pad new_pad) {
        var sinkpad = this.get_compatible_sink_pad (new_pad, new_pad.query_caps (null));

        if (sinkpad == null) {
            debug ("No compatible encodebin pad found for pad '%s', ignoring...",
                   new_pad.name);
            return;
        }

        var pad_link_ok = (new_pad.link (sinkpad) == PadLinkReturn.OK);
        if (!pad_link_ok) {
            warning ("Failed to link pad '%s' to '%s'",
                     new_pad.name,
                     sinkpad.name);
        } else {
            this.link_failed = false;
        }
    }

    private const string DESCRIPTION = "Encoder and decoder are not " +
                                       "compatible";

    private void on_no_more_pads (Element decodebin) {
        // We haven't found any pads we could link
        if (this.link_failed) {
            // Signalize that error
            var bin = this.encoder.get_parent () as Bin;
            var error = new IOError.FAILED ("Could not link");
            var message = new Message.error (bin,
                                             error,
                                             DESCRIPTION);


            var bus = bin.get_bus ();
            bus.post (message);
        }
    }
}
