// A socket and a bare port left unbound: FW-E-SOCK-UNBOUND on each. Unlike
// a socket, whose two ends must pair up, a bare export may stay open.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_apis.svh"

    class user extends fw_component;
        `fw_component_utils(user)
        fw_socket #(test_put_if #(byte), test_get_if #(byte)) s;
        fw_port #(test_put_if #(byte))                        p;
        virtual function void build();
            s = fw_socket #(test_put_if #(byte), test_get_if #(byte))::create("s", this);
            p = fw_port #(test_put_if #(byte))::create("p", this);
        endfunction
    endclass

    class sink extends fw_component implements test_put_if #(byte);
        `fw_component_utils(sink)
        fw_export #(test_put_if #(byte)) e;
        virtual function void build();
            e = fw_export #(test_put_if #(byte))::create("e", this);
        endfunction
        virtual task put(byte t);
        endtask
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        user u;
        sink k;
        virtual function void build();
            u = user::create("u", this);
            k = sink::create("k", this);
        endfunction
    endclass

endpackage
