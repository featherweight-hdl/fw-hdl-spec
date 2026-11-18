// An abstractor between two protocols: packets (test_pkt_proto) over a
// byte PHY (test_phy_proto).
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_pkt_phy.svh"

    // Packets in through an export (may stay open), bytes out on the PHY
    // bundle.
    class pkt_over_phy extends fw_component implements test_put_if #(test_pkt_t);
        `fw_abstractor_utils(pkt_over_phy, test_phy_proto, test_pkt_proto)
        fw_export #(test_put_if #(test_pkt_t)) up;
        fw_bundle #(test_phy_bundle)            phy;
        virtual function void build();
            up  = fw_export #(test_put_if #(test_pkt_t))::create("up", this);
            phy = fw_bundle #(test_phy_bundle)::create("phy", this);
        endfunction
        virtual task put(test_pkt_t t);
        endtask
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_bundle #(test_phy_bundle) phy;
        pkt_over_phy a;
        virtual function void build();
            phy = fw_bundle #(test_phy_bundle)::create("phy", this);
            a   = pkt_over_phy::create("a", this);
        endfunction
        virtual function void connect();
            a.phy.connect_up(phy);
        endfunction
    endclass

endpackage
