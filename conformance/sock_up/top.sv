// A socket passed up two levels with connect_up, then bound at the top: one
// api binding per call, inner to outer, then the calling side to the
// providing side.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_apis.svh"

    // Calls the API through its socket.
    class leaf extends fw_component;
        `fw_component_utils(leaf)
        fw_socket #(test_put_if #(byte), test_get_if #(byte)) s;
        virtual function void build();
            s = fw_socket #(test_put_if #(byte), test_get_if #(byte))::create("s", this);
        endfunction
    endclass

    class mid extends fw_component;
        `fw_component_utils(mid)
        fw_socket #(test_put_if #(byte), test_get_if #(byte)) s;
        leaf                                                  l;
        virtual function void build();
            s = fw_socket #(test_put_if #(byte), test_get_if #(byte))::create("s", this);
            l = leaf::create("l", this);
        endfunction
        virtual function void connect();
            l.s.connect_up(s);
        endfunction
    endclass

    class outer extends fw_component;
        `fw_component_utils(outer)
        fw_socket #(test_put_if #(byte), test_get_if #(byte)) s;
        mid                                                   m;
        virtual function void build();
            s = fw_socket #(test_put_if #(byte), test_get_if #(byte))::create("s", this);
            m = mid::create("m", this);
        endfunction
        virtual function void connect();
            m.s.connect_up(s);
        endfunction
    endclass

    // Implements the API for its mirror socket.
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
        outer o;
        sink  k;
        virtual function void build();
            o = outer::create("o", this);
            k = sink::create("k", this);
        endfunction
        virtual function void connect();
            o.s.connect(k.t);
        endfunction
    endclass

endpackage
