[CCode (cprefix = "ZBar", lower_case_cprefix = "zbar_", cheader_filename = "zbar.h")]
namespace ZBar {
    /* Format helper struct */
    [SimpleType]
    [CCode (cname="unsigned long", has_type_id=false)]
    public struct Format: ulong{
        [CCode (cname = "zbar_fourcc_parse")]
        public static Format fourcc_parse([CCode (array_null_terminated=true)] string format);
    }

    /** "color" of element: bar or space. */
    [CCode (cname = "zbar_color_t", has_type_id = false, cprefix = "ZBAR_")]
    public enum Color {
        SPACE, /**< light area or space between bars */
        BAR, /**< dark area or colored bar segment */
    }

    /** "color" of element: bar or space. */
    [CCode (cname = "zbar_symbol_type_t", has_type_id = false, cprefix = "ZBAR_")]
    public enum SymbolType {
        NONE, /**< no symbol decoded */
        PARTIAL, /**< intermediate status */
        EAN2, /**< GS1 2-digit add-on */
        EAN5, /**< GS1 5-digit add-on */
        EAN8, /**< EAN-8 */
        UPCE, /**< UPC-E */
        ISBN10, /**< ISBN-10 (from EAN-13). @since 0.4 */
        UPCA, /**< UPC-A */
        EAN13, /**< EAN-13 */
        ISBN13, /**< ISBN-13 (from EAN-13). @since 0.4 */
        COMPOSITE, /**< EAN/UPC composite */
        I25, /**< Interleaved 2 of 5. @since 0.4 */
        DATABAR, /**< GS1 DataBar (RSS). @since 0.11 */
        DATABAR_EXP, /**< GS1 DataBar Expanded. @since 0.11 */
        CODABAR, /**< Codabar. @since 0.11 */
        CODE39, /**< Code 39. @since 0.4 */
        PDF417, /**< PDF417. @since 0.6 */
        QRCODE, /**< QR Code. @since 0.10 */
        SQCODE, /**< SQ Code. @since 0.20.1 */
        CODE93, /**< Code 93. @since 0.11 */
        CODE128, /**< Code 128 */

        /*
        * Please see _get_symbol_hash() if adding
        * anything after 128
        */

        /** mask for base symbol type.
        * @deprecated in 0.11, remove this from existing code
        */
        SYMBOL,
        /** 2-digit add-on flag.
        * @deprecated in 0.11, a ::EAN2 component is used for
        * 2-digit GS1 add-ons
        */
        ADDON2,
        /** 5-digit add-on flag.
        * @deprecated in 0.11, a ::EAN5 component is used for
        * 5-digit GS1 add-ons
        */
        ADDON5,
        /** add-on flag mask.
        * @deprecated in 0.11, GS1 add-ons are represented using composite
        * symbols of type ::COMPOSITE; add-on components use ::EAN2
        * or ::EAN5
        */
        ADDON,
    }

    /** decoded symbol coarse orientation.
     * @since 0.11
     */
    [CCode (cname = "zbar_orientation_t", has_type_id = false, cprefix = "ZBAR_ORIENT_")]
    public enum Orientation {
        UNKNOWN, /**< unable to determine orientation */
        UP, /**< upright, read left to right */
        RIGHT, /**< sideways, read top to bottom */
        DOWN, /**< upside-down, read right to left */
        LEFT, /**< sideways, read bottom to top */
    }

    /** error codes. */
    [CCode (cname = "zbar_error_t", has_type_id = false, cprefix = "ZBAR_ERR_")]
    public enum Error {
    [CCode (cname = "ZBAR_OK")]
        OK, /**< no error */
        NOMEM, /**< out of memory */
        INTERNAL, /**< internal library error */
        UNSUPPORTED, /**< unsupported request */
        INVALID, /**< invalid request */
        SYSTEM, /**< system error */
        LOCKING, /**< locking error */
        BUSY, /**< all resources busy */
        XDISPLAY, /**< X11 display error */
        XPROTO, /**< X11 protocol error */
        CLOSED, /**< output window is closed */
        WINAPI, /**< windows system error */
        NUM /**< number of error codes */
    }

    /** decoder configuration options.
     * @since 0.4
     */
    [CCode (cname = "zbar_config_t", has_type_id = false, cprefix = "ZBAR_CFG_")]
    public enum Config {
        ENABLE, /**< enable symbology/feature */
        ADD_CHECK, /**< enable check digit when optional */
        EMIT_CHECK, /**< return check digit when present */
        ASCII, /**< enable full ASCII character set */
        BINARY, /**< don't convert binary data to text */
        NUM, /**< number of boolean decoder configs */
        MIN_LEN, /**< minimum data length for valid decode */
        MAX_LEN, /**< maximum data length for valid decode */
        UNCERTAINTY, /**< required video consistency frames */
        POSITION, /**< enable scanner to collect position data */
        TEST_INVERTED, /**< if fails to decode, test inverted */
        X_DENSITY, /**< image scanner vertical scan density */
        Y_DENSITY, /**< image scanner horizontal scan density */
    }

    /** decoder symbology modifier flags.
     * @since 0.11
     */
    [CCode (cname = "zbar_modifier_t", has_type_id = false, cprefix = "ZBAR_MOD_")]
    public enum Modifier {
        /** barcode tagged as GS1 (EAN.UCC) reserved
        * (eg, FNC1 before first data character).
        * data may be parsed as a sequence of GS1 AIs
        */
        GS1,
        /** barcode tagged as AIM reserved
        * (eg, FNC1 after first character or digit pair)
        */
        AIM,
        /** number of modifiers */
        NUM,
    }
    // TODO:
    // video_control_type_e
    // video_control_menu_s
    // video_controls_s
    // video_resolution_s
    // zbar_version
    // zbar_set_verbosity
    // zbar_increase_verbosity
    // zbar_get_symbol_name
    // zbar_get_addon_name
    // zbar_get_config_name
    // zbar_get_modifier_name
    // zbar_get_orientation_name
    // zbar_parse_config
    // zbar_fourcc
    // zbar_fourcc_parse
    // _zbar_error_spew
    // etc

    [Compact]
    [CCode (cname = "zbar_image_scanner_t", cprefix = "zbar_image_scanner_", free_function = "zbar_image_scanner_destroy")]
    public class ImageScanner {
        [CCode (cname = "zbar_image_scanner_create")]
        public ImageScanner ();
        /** set config for indicated symbology (0 for all) to specified value.
         * @returns 0 for success, non-0 for failure (config does not apply to
         * specified symbology, or value out of range)
         * @see zbar_decoder_set_config()
         * @since 0.4
         */
        public Error set_config(SymbolType symbology, Config config, int value);
        /** scan for symbols in provided image.  The image format must be
         * "Y800" or "GRAY".
         * @returns >0 if symbols were successfully decoded from the image,
         * 0 if no symbols were found or -1 if an error occurs
         * @see zbar_image_convert()
         * @since 0.9 - changed to only accept grayscale images
         */
        [CCode (cname = "zbar_scan_image")]
        public Error scan_image(Image image);
    }

    [Compact]
    [CCode (cname = "zbar_image_t", cprefix = "zbar_image_", free_function = "zbar_image_destroy")]
    public class Image {
        /** new image constructor.
        * @returns a new image object with uninitialized data and format.
        * this image should be destroyed (using zbar_image_destroy()) as
        * soon as the application is finished with it
        */
        [CCode (cname = "zbar_image_create")]
        public Image ();
        /** image format conversion.  refer to the documentation for supported
         * image formats
         * @returns a @em new image with the sample data from the original image
         * converted to the requested format.  the original image is
         * unaffected.
         * @note the converted image size may be rounded (up) due to format
         * constraints
         */
        public Image convert(ulong format);

        /** image format conversion with crop/pad.
         * if the requested size is larger than the image, the last row/column
         * are duplicated to cover the difference.  if the requested size is
         * smaller than the image, the extra rows/columns are dropped from the
         * right/bottom.
         * @returns a @em new image with the sample data from the original
         * image converted to the requested format and size.
         * @note the image is @em not scaled
         * @see zbar_image_convert()
         * @since 0.4
         */
        public Image convert_resize(ulong format, uint width, uint height);

        // the fourcc describing the format of the image sample data
        public Format format {get;set;}
        // (page/frame) number
        public ulong sequence {get;set;}

        /** built-in cleanup handler.
         * passes the image data buffer to free()
         */
        public static void free_data(Image image);

        /** specify image sample data.  when image data is no longer needed by
         * the library the specific data cleanup handler will be called
         * (unless NULL)
         * @note application image data will not be modified by the library
         */
        public void set_data(void[] data, CleanupHandler handler=free_data);

        /** specify the pixel size of the image.
         * @note this also resets the crop rectangle to the full image
         * (0, 0, width, height)
         * @note this does not affect the data!
         */
        public void set_size(uint width, uint height);

        /** image_scanner decode result iterator.
         * @returns the first decoded symbol result for an image
         * or NULL if no results are available
         */
        public unowned Symbol? first_symbol();

        [CCode (cname = "zbar_image_cleanup_handler_t", has_target = false)]
        public delegate void CleanupHandler(Image image);
    }

    [Compact]
    [CCode (cname = "zbar_symbol_t", cprefix = "zbar_symbol_")]
    public class Symbol {
        public SymbolType type {get;}
        /** iterate the set to which this symbol belongs (there can be only one).
         * @returns the next symbol in the set, or
         * @returns NULL when no more results are available
         */
        public unowned Symbol? next();

        [CCode (array_null_terminated=true)]
        public string get_data();
    }

}
