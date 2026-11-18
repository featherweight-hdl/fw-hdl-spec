// A sink that no source reaches: FW-E-CFG-UNBOUND on the sink.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_uart_proto.svh"

    // Reads the configuration.
    class reader extends fw_component;
        `fw_component_utils(reader)
        fw_cfg_sink #(uart_cfg_t) c;
        virtual function void build();
            c = fw_cfg_sink #(uart_cfg_t)::create("c", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        reader r;
        virtual function void build();
            r = reader::create("r", this);
        endfunction
    endclass

endpackage
