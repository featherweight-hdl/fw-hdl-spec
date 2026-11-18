// Converters that do not connect what they register for: FW-E-PROTO-XTOR
// on the class (its family name). A transactor needs a bundle port of its
// protocol and (but a monitor) an endpoint of one of its APIs; an
// abstractor an endpoint or bundle port of each side.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_apis.svh"

    class xb_proto extends fw_protocol;
        `fw_protocol_utils(xb_proto)
        static function void declare(fw_protocol_decl d);
            d.api(fw_api_type_of #(test_put_if #(byte))::get(), FW_PROTO_REQ);
        endfunction
    endclass

    virtual class xb_bundle extends fw_rv_if #(byte);
        `fw_bundle_protocol(xb_proto)
    endclass

    class ob_proto extends fw_protocol;
        `fw_protocol_utils(ob_proto)
        static function void declare(fw_protocol_decl d);
            d.api(fw_api_type_of #(test_put_if #(shortint))::get(), FW_PROTO_REQ);
        endfunction
    endclass

    virtual class ob_bundle extends fw_rv_if #(shortint);
        `fw_bundle_protocol(ob_proto)
    endclass

    // Correct: the API through an export, the pins as an initiator.
    class good_init extends fw_component implements test_put_if #(byte);
        `fw_xtor_utils(good_init, xb_proto)
        fw_export #(test_put_if #(byte)) t;
        fw_bundle #(xb_bundle)           pins;
        virtual function void build();
            t    = fw_export #(test_put_if #(byte))::create("t", this);
            pins = fw_bundle #(xb_bundle)::create("pins", this);
        endfunction
        virtual task put(byte t);
        endtask
    endclass

    // Correct: a monitor needs no endpoint.
    class good_mon extends fw_component;
        `fw_xtor_utils(good_mon, xb_proto)
        fw_monitor #(xb_bundle) pins;
        virtual function void build();
            pins = fw_monitor #(xb_bundle)::create("pins", this);
        endfunction
    endclass

    // No endpoint of xb_proto's API.
    class noapi_xtor extends fw_component;
        `fw_xtor_utils(noapi_xtor, xb_proto)
        fw_mirror #(xb_bundle) pins;
        virtual function void build();
            pins = fw_mirror #(xb_bundle)::create("pins", this);
        endfunction
    endclass

    // Its bundle port is of another protocol.
    class nobundle_xtor extends fw_component implements test_put_if #(byte);
        `fw_xtor_utils(nobundle_xtor, xb_proto)
        fw_export #(test_put_if #(byte)) t;
        fw_bundle #(ob_bundle)           pins;
        virtual function void build();
            t    = fw_export #(test_put_if #(byte))::create("t", this);
            pins = fw_bundle #(ob_bundle)::create("pins", this);
        endfunction
        virtual task put(byte t);
        endtask
    endclass

    // Parameterized, with no bundle port at all: the path is the family.
    class bad_p_xtor #(int W = 8) extends fw_component implements test_put_if #(byte);
        typedef bad_p_xtor #(W) this_t;
        `fw_xtor_param_utils(bad_p_xtor, xb_proto)
        fw_export #(test_put_if #(byte)) t;
        virtual function void build();
            t = fw_export #(test_put_if #(byte))::create("t", this);
        endfunction
        virtual task put(byte t);
        endtask
    endclass

    // From xb_proto to ob_proto, with nothing of xb_proto.
    class half_abs extends fw_component;
        `fw_abstractor_utils(half_abs, xb_proto, ob_proto)
        fw_mirror #(ob_bundle) pins;
        virtual function void build();
            pins = fw_mirror #(ob_bundle)::create("pins", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        good_init        gi;
        good_mon         gm;
        noapi_xtor       na;
        nobundle_xtor    nb;
        bad_p_xtor #(16) bp;
        half_abs         ha;
        virtual function void build();
            gi = good_init::create("gi", this);
            gm = good_mon::create("gm", this);
            na = noapi_xtor::create("na", this);
            nb = nobundle_xtor::create("nb", this);
            bp = bad_p_xtor #(16)::create("bp", this);
            ha = half_abs::create("ha", this);
        endfunction
        virtual function void connect();
            gi.pins.connect(na.pins);
            gm.pins.connect(gi.pins);
            nb.pins.connect(ha.pins);
        endfunction
    endclass

endpackage
