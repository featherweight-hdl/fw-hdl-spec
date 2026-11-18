// sbus behaviour: what cannot be derived. Two adapters between the
// transaction-level API (sbus_if) and the generated channel APIs
// (sbus_req_if, sbus_rsp_if), and a memory model behind sbus_if. Written on
// the generated package; no pins anywhere.
`include "fw_hdl_macros.svh"

package sbus_behav_pkg;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    import sbus_pkg::*;
    import sbus_pkg_gen_pkg::*;

    // Initiator side: provides sbus_if (export t); each access sends one
    // req beat through socket s and returns with the rsp beat that comes
    // back. The rsp may arrive inside the req call, so it is queued.
    class sbus_host extends fw_component implements sbus_if, sbus_rsp_if;
        `fw_component_utils(sbus_host)
        fw_export #(sbus_if)                    t;
        fw_socket #(sbus_req_if, sbus_rsp_if)   s;
        mailbox #(sbus_rsp_t) rsps = new();

        virtual function void build();
            t = fw_export #(sbus_if)::create("t", this);
            s = fw_socket #(sbus_req_if, sbus_rsp_if)::create("s", this);
        endfunction

        virtual task access(output sbus_rsp_t rsp, input sbus_req_t req);
            s.get_if().req(req);
            rsps.get(rsp);
        endtask

        // Called by the initiator transactor for each rsp beat.
        virtual task rsp(input sbus_rsp_t t);
            rsps.put(t);
        endtask
    endclass

    // Target side: takes req beats from socket s, runs each as an access on
    // port m, and sends the response back. Requests are queued and served
    // from run(), so a slow model never holds up the req channel's call.
    class sbus_dev extends fw_component implements sbus_req_if, fw_run_if;
        `fw_component_utils(sbus_dev)
        fw_socket #(sbus_rsp_if, sbus_req_if)   s;
        fw_port #(sbus_if)                      m;
        mailbox #(sbus_req_t) reqs = new();

        virtual function void build();
            s = fw_socket #(sbus_rsp_if, sbus_req_if)::create("s", this);
            m = fw_port #(sbus_if)::create("m", this);
        endfunction

        virtual task req(input sbus_req_t t);
            reqs.put(t);
        endtask

        virtual task run();
            sbus_req_t r;
            sbus_rsp_t p;
            forever begin
                reqs.get(r);
                m.get_if().access(p, r);
                s.get_if().rsp(p);
            end
        endtask
    endclass

    // The reference model: 240 words; an access at 0xF0 and above is an
    // error. A write returns the value written.
    class sbus_mem extends fw_component implements sbus_if;
        `fw_component_utils(sbus_mem)
        fw_export #(sbus_if) t;
        bit [31:0] mem [256];

        virtual function void build();
            t = fw_export #(sbus_if)::create("t", this);
        endfunction

        virtual task access(output sbus_rsp_t rsp, input sbus_req_t req);
            rsp.err = (req.addr >= 8'hF0);
            if (req.we && !rsp.err)
                mem[req.addr] = req.wdata;
            rsp.rdata = rsp.err ? 32'h0 : mem[req.addr];
        endtask
    endclass
endpackage
