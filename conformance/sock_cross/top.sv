// A socket binding across unrelated clock domains: FW-E-DOM-CROSS on the
// lesser endpoint path. The same binding within one domain is no crossing.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_apis.svh"

    class src extends fw_component;
        `fw_component_utils(src)
        fw_socket #(test_put_if #(byte), test_get_if #(byte)) s;
        virtual function void build();
            s = fw_socket #(test_put_if #(byte), test_get_if #(byte))::create("s", this);
        endfunction
    endclass

    class sink extends fw_component implements test_put_if #(byte);
        `fw_component_utils(sink)
        fw_socket #(test_get_if #(byte), test_put_if #(byte)) t;
        virtual function void build();
            t = fw_socket #(test_get_if #(byte), test_put_if #(byte))::create("t", this);
        endfunction
        virtual task put(byte t);
        endtask
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_clock_domain c0, c2;
        src             a0, a1;
        sink            k0, k1;
        virtual function void build();
            c0 = fw_clock_domain::create("c0", this);
            c2 = fw_clock_domain::create("c2", this);
            fw_clock_domain::set(this, c0);
            a0 = src::create("a0", this);
            a1 = src::create("a1", this);
            k0 = sink::create("k0", this);
            k1 = sink::create("k1", this);
            fw_clock_domain::set(k1, c2);
        endfunction
        virtual function void connect();
            a0.s.connect(k0.t);    // same domain
            a1.s.connect(k1.t);    // c0 to c2
        endfunction
    endclass

endpackage
