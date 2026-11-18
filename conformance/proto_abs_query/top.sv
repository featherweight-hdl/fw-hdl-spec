// The constructor queries: abstractor_for and abstractors() find an
// abstractor the design names only by its declaration, and the top creates
// it through the constructor they return.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_pkt_phy.svh"

    // Registered between the two protocols; created only through a query.
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
        fw_component a;
        virtual function void build();
            fw_protocol_type pkt = test_pkt_proto::get_type();
            fw_protocol_type ph  = test_phy_proto::get_type();
            // Registered from phy to pkt; found in either direction.
            fw_ctor #(fw_component) c = fw_protocol::abstractor_for(pkt, ph);
            fw_component_ctor_q qa = ph.abstractors();
            fw_component_ctor_q qb = pkt.abstractors();
            phy = fw_bundle #(test_phy_bundle)::create("phy", this);
            if (c != null && qa.size() == 1 && qa[0] == c && qb.size() == 1 && qb[0] == c
                    && fw_protocol::abstractor_for(pkt, pkt) == null)
                a = c.create("a", this, fw_component::mk_params());
        endfunction
        virtual function void connect();
            pkt_over_phy x;
            if ($cast(x, a))
                x.phy.connect_up(phy);
        endfunction
    endclass

endpackage
