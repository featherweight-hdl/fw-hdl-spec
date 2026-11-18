// One API, test_put_if #(uart_char_t), registered by two protocols.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_uart_proto.svh"

    class uart2_proto extends fw_protocol;
        `fw_protocol_utils(uart2_proto)
        static function void declare(fw_protocol_decl d);
            d.api(fw_api_type_of #(test_put_if #(uart_char_t))::get(), FW_PROTO_REQ);
        endfunction
    endclass

    virtual class uart2_bundle extends fw_rv_if #(uart_char_t);
        `fw_bundle_protocol(uart2_proto)
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_bundle #(test_uart_serial) a;
        fw_bundle #(uart2_bundle)     b;
        virtual function void build();
            a = fw_bundle #(test_uart_serial)::create("a", this);
            b = fw_bundle #(uart2_bundle)::create("b", this);
        endfunction
    endclass

endpackage
