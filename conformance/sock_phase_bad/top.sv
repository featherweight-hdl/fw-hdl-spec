// A socket bound in build(): FW-E-CONN-PHASE on the socket whose connect was
// called. The early binding is not made; the one in connect() is, so top.t
// stays unbound (FW-E-SOCK-UNBOUND).
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_apis.svh"

    class sink extends fw_component implements test_put_if #(byte);
        `fw_component_utils(sink)
        fw_socket #(test_get_if #(byte), test_put_if #(byte)) t;
        virtual function void build();
            t = fw_socket #(test_get_if #(byte), test_put_if #(byte))::create("t", this);
        endfunction
        virtual task put(byte t);
        endtask
    endclass

    class top extends fw_component implements test_put_if #(byte);
        `fw_component_utils(top)
        fw_socket #(test_put_if #(byte), test_get_if #(byte)) s;
        fw_socket #(test_get_if #(byte), test_put_if #(byte)) t;
        sink                                                  k;
        virtual function void build();
            s = fw_socket #(test_put_if #(byte), test_get_if #(byte))::create("s", this);
            t = fw_socket #(test_get_if #(byte), test_put_if #(byte))::create("t", this);
            k = sink::create("k", this);
            s.connect(t);          // too early
        endfunction
        virtual function void connect();
            s.connect(k.t);
        endfunction
        virtual task put(byte t);
        endtask
    endclass

endpackage
