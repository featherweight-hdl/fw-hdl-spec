// Initiator, target and monitor transactors of one protocol, connected by
// their bundles; the target and monitor call up through ports to a sink's
// export (many ports may serve one export).
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_apis.svh"

    class xp_proto extends fw_protocol;
        `fw_protocol_utils(xp_proto)
        static function void declare(fw_protocol_decl d);
            d.api(fw_api_type_of #(test_put_if #(byte))::get(), FW_PROTO_REQ);
        endfunction
    endclass

    virtual class xp_bundle extends fw_rv_if #(byte);
        `fw_bundle_protocol(xp_proto)
    endclass

    // API in, pins out; its own export may stay open.
    class xp_init_xtor extends fw_component implements test_put_if #(byte);
        `fw_xtor_utils(xp_init_xtor, xp_proto)
        fw_export #(test_put_if #(byte)) t;
        fw_bundle #(xp_bundle)           pins;
        virtual function void build();
            t    = fw_export #(test_put_if #(byte))::create("t", this);
            pins = fw_bundle #(xp_bundle)::create("pins", this);
        endfunction
        virtual task put(byte t);
        endtask
    endclass

    // Pins in, API out through a port.
    class xp_tgt_xtor extends fw_component;
        `fw_xtor_utils(xp_tgt_xtor, xp_proto)
        fw_mirror #(xp_bundle)         pins;
        fw_port #(test_put_if #(byte)) s;
        virtual function void build();
            pins = fw_mirror #(xp_bundle)::create("pins", this);
            s    = fw_port #(test_put_if #(byte))::create("s", this);
        endfunction
    endclass

    // Pins observed, API out through a port.
    class xp_mon_xtor extends fw_component;
        `fw_xtor_utils(xp_mon_xtor, xp_proto)
        fw_monitor #(xp_bundle)        pins;
        fw_port #(test_put_if #(byte)) s;
        virtual function void build();
            pins = fw_monitor #(xp_bundle)::create("pins", this);
            s    = fw_port #(test_put_if #(byte))::create("s", this);
        endfunction
    endclass

    // Implements the API for its export; many ports may bind to it.
    class sink extends fw_component implements test_put_if #(byte);
        `fw_component_utils(sink)
        fw_export #(test_put_if #(byte)) t;
        virtual function void build();
            t = fw_export #(test_put_if #(byte))::create("t", this);
        endfunction
        virtual task put(byte t);
        endtask
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        xp_init_xtor i;
        xp_tgt_xtor  t;
        xp_mon_xtor  m;
        sink         k;
        virtual function void build();
            i = xp_init_xtor::create("i", this);
            t = xp_tgt_xtor::create("t", this);
            m = xp_mon_xtor::create("m", this);
            k = sink::create("k", this);
        endfunction
        virtual function void connect();
            i.pins.connect(t.pins);
            m.pins.connect(i.pins);
            t.s.connect(k.t);
            m.s.connect(k.t);
        endfunction
    endclass

endpackage
