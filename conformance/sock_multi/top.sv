// A port bound to two exports: FW-E-SOCK-MULTI on the port. One export
// serving two ports is legal.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_apis.svh"

    class user extends fw_component;
        `fw_component_utils(user)
        fw_port #(test_put_if #(byte)) p;
        virtual function void build();
            p = fw_port #(test_put_if #(byte))::create("p", this);
        endfunction
    endclass

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
        user     u0, u1;
        provider v0, v1;
        virtual function void build();
            u0 = user::create("u0", this);
            u1 = user::create("u1", this);
            v0 = provider::create("v0", this);
            v1 = provider::create("v1", this);
        endfunction
        virtual function void connect();
            u0.p.connect(v0.e);
            u0.p.connect(v1.e);    // second binding
            u1.p.connect(v0.e);    // legal: v0.e serves two ports
        endfunction
    endclass

endpackage
