// A bare API port bound to a bare API export: endpoints with no protocol.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_apis.svh"

    // Calls the API through its port.
    class user extends fw_component;
        `fw_component_utils(user)
        fw_port #(test_put_if #(byte)) p;
        virtual function void build();
            p = fw_port #(test_put_if #(byte))::create("p", this);
        endfunction
    endclass

    // Provides the API; the implementation is derived.
    class provider extends fw_component implements test_put_if #(byte);
        `fw_component_utils(provider)
        fw_export #(test_put_if #(byte)) e;
        virtual function void build();
            e = fw_export #(test_put_if #(byte))::create("e", this);
        endfunction
        virtual task put(byte t);
        endtask
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        user     u;
        provider v;
        virtual function void build();
            u = user::create("u", this);
            v = provider::create("v", this);
        endfunction
        virtual function void connect();
            u.p.connect(v.e);
        endfunction
    endclass

endpackage
