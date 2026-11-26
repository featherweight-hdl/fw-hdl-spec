// Converters that do not connect what they register for: FW-E-PROTO-XTOR
// on the class (its family name). A transactor needs (but a monitor) an
// endpoint of one of its protocol's APIs; its base class makes one from
// the protocol's API, so it lacks one only when its protocol has none. Its
// bundle port is its base class's pins, so it always has one. An
// abstractor needs an endpoint or bundle port of each side.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_apis.svh"

    class xb_proto extends fw_protocol;
        `fw_protocol_utils(xb_proto, test_put_if #(byte))
    endclass

    virtual class xb_bundle extends fw_rv_if #(byte);
        `fw_bundle_utils(xb_bundle, xb_proto)
    endclass

    class ob_proto extends fw_protocol;
        `fw_protocol_utils(ob_proto, test_put_if #(shortint))
    endclass

    virtual class ob_bundle extends fw_rv_if #(shortint);
        `fw_bundle_utils(ob_bundle, ob_proto)
    endclass

    // A protocol with no API.
    class na_proto extends fw_protocol;
        `fw_protocol_utils(na_proto)
    endclass

    virtual class na_bundle extends fw_rv_if #(byte);
        `fw_bundle_utils(na_bundle, na_proto)
    endclass

    // Correct: the API through the base's export, the pins as an initiator.
    class good_init extends fw_xtor_initiator #(xb_bundle) implements test_put_if #(byte);
        `fw_xtor_utils(good_init)
        virtual task put(byte t);
        endtask
    endclass

    // Correct: a monitor needs no endpoint.
    class good_mon extends fw_xtor_monitor #(xb_bundle);
        `fw_xtor_utils(good_mon)
    endclass

    // No endpoint: na_proto has no API.
    class noapi_xtor extends fw_xtor_target #(na_bundle);
        `fw_xtor_utils(noapi_xtor)
    endclass

    // Parameterized, with no endpoint (na_proto has no API): the path is
    // the family.
    class bad_p_xtor #(int W = 8) extends fw_xtor_initiator #(na_bundle);
        typedef bad_p_xtor #(W) this_t;
        `fw_xtor_param_utils(bad_p_xtor)
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
        bad_p_xtor #(16) bp;
        half_abs         ha;
        fw_mirror #(ob_bundle) ob;
        fw_bundle #(xb_bundle) xi;
        fw_mirror #(na_bundle) nm;
        fw_bundle #(na_bundle) xo;
        virtual function void build();
            gi = good_init::create("gi", this);
            gm = good_mon::create("gm", this);
            na = noapi_xtor::create("na", this);
            bp = bad_p_xtor #(16)::create("bp", this);
            ha = half_abs::create("ha", this);
            ob = fw_mirror #(ob_bundle)::create("ob", this);
            xi = fw_bundle #(xb_bundle)::create("xi", this);
            nm = fw_mirror #(na_bundle)::create("nm", this);
            xo = fw_bundle #(na_bundle)::create("xo", this);
        endfunction
        virtual function void connect();
            gi.pins.connect_up(xi);
            gm.pins.connect(gi.pins);
            na.pins.connect_up(nm);
            bp.pins.connect_up(xo);
            ha.pins.connect_up(ob);
        endfunction
    endclass

endpackage
