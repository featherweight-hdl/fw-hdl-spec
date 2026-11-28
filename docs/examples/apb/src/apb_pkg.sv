// apb: an APB-style bus (one transfer in flight: a setup cycle, then access
// cycles until PREADY) as a hand-written protocol package. Its pins are
// plain signals, not ready/valid channels, so GenKit generates no
// transactors for it: the two here are written by hand, the reference for
// docs/protocol-packages/behaviour.rst, "Hand-written transactors".
//
// Each transactor is one class with the API on one side and the pins on the
// other. Its task code (the API task, run()) only hands items through
// task-sync crossings; comb() and step() drive and sample the pins.
`include "fw_hdl_macros.svh"

package apb_pkg;
    import fw_hdl_pkg::*;

    // One request: what the initiator drives through a transfer.
    typedef struct packed {
        bit [15:0] addr;
        bit [31:0] wdata;
        bit        write;
    } apb_req_t;

    // One response: the read data and the error flag.
    typedef struct packed {
        bit [31:0] rdata;
        bit        slverr;
    } apb_rsp_t;

    // The transaction-level API: one transfer and its response. Outputs
    // lead.
    interface class apb_if;
        pure virtual task access(output apb_rsp_t rsp, input apb_req_t req);
    endclass

    // The protocol: its request API is apb_if.
    class apb_proto extends fw_protocol;
        `fw_protocol_utils(apb_proto, apb_if)
    endclass

    // The pins, from the initiator's view.
    virtual class apb_bundle extends fw_bundle_base;
        `fw_bundle_utils(apb_bundle, apb_proto)
        fw_output #(bit)        psel;
        fw_output #(bit)        penable;
        fw_output #(bit)        pwrite;
        fw_output #(bit [15:0]) paddr;
        fw_output #(bit [31:0]) pwdata;
        fw_input  #(bit [31:0]) prdata;
        fw_input  #(bit)        pready;
        fw_input  #(bit)        pslverr;

        virtual function void build();
            psel    = fw_output #(bit)       ::create("psel",    this);
            penable = fw_output #(bit)       ::create("penable", this);
            pwrite  = fw_output #(bit)       ::create("pwrite",  this);
            paddr   = fw_output #(bit [15:0])::create("paddr",   this);
            pwdata  = fw_output #(bit [31:0])::create("pwdata",  this);
            prdata  = fw_input  #(bit [31:0])::create("prdata",  this);
            pready  = fw_input  #(bit)       ::create("pready",  this);
            pslverr = fw_input  #(bit)       ::create("pslverr", this);
        endfunction
    endclass

    // The initiator. ``access`` puts the request into ``reqs`` and gets the
    // response from ``rsps``; it touches no pin. ``comb()`` drives the
    // transfer while a request waits, ``step()`` moves it from setup to
    // access and, at the edge where PREADY is high, takes the request and
    // gives the response, so ``access`` returns at that edge.
    class apb_initiator extends fw_xtor_initiator #(apb_bundle)
            implements apb_if, fw_comb_if, fw_step_if, fw_reset_state_if;
        `fw_xtor_utils(apb_initiator)

        fw_to_sync   #(apb_req_t) reqs;   // the transfer in progress
        fw_from_sync #(apb_rsp_t) rsps;   // its response
        bit acc;                          // in the access phase

        // Creates ``pins`` and ``t`` (the base), and the crossings.
        virtual function void build();
            super.build();
            reqs = fw_to_sync   #(apb_req_t)::create("reqs", this);
            rsps = fw_from_sync #(apb_rsp_t)::create("rsps", this);
        endfunction

        // The API: task code, so it only hands off.
        virtual task access(output apb_rsp_t rsp, input apb_req_t req);
            reqs.put(req);
            rsps.get(rsp);
        endtask

        // Selects while a request waits (and its response has room).
        virtual function void comb();
            apb_req_t r = reqs.peek();
            bit sel = reqs.valid() && rsps.ready();
            pins.psel.write(sel);
            pins.penable.write(sel && acc);
            pins.pwrite.write(r.write);
            pins.paddr.write(r.addr);
            pins.pwdata.write(r.wdata);
        endfunction

        // Setup, then access until PREADY: then the transfer ends.
        virtual function void step();
            apb_req_t r;
            apb_rsp_t s;
            if (pins.psel.read()) begin
                if (!pins.penable.read()) acc = 1;
                else if (pins.pready.read()) begin
                    void'(reqs.take(r));
                    s.rdata  = pins.prdata.read();
                    s.slverr = pins.pslverr.read();
                    void'(rsps.give(s));
                    acc = 0;
                end
            end
        endfunction

        virtual function void reset_state();
            acc = 0;
        endfunction
    endclass

    // The target. Each transfer seen at the pins is made an ``access`` call
    // through ``p``. ``step()`` gives the request to ``run()`` at the setup
    // edge and takes the response at the edge that ends the transfer;
    // ``comb()`` raises PREADY while a response waits. ``run()`` only hands
    // off: get, call, put.
    class apb_target extends fw_xtor_target #(apb_bundle)
            implements fw_run_if, fw_comb_if, fw_step_if, fw_reset_state_if;
        `fw_xtor_utils(apb_target)

        fw_from_sync #(apb_req_t) reqs;   // requests, for run()
        fw_to_sync   #(apb_rsp_t) rsps;   // their responses
        bit busy;                         // a request is with run()

        // Creates ``pins`` and ``p`` (the base), and the crossings.
        virtual function void build();
            super.build();
            reqs = fw_from_sync #(apb_req_t)::create("reqs", this);
            rsps = fw_to_sync   #(apb_rsp_t)::create("rsps", this);
        endfunction

        // Task code: hands each request to the API and its response back.
        virtual task run();
            apb_if i = p.get_if();
            apb_req_t r;
            apb_rsp_t s;
            forever begin
                reqs.get(r);
                i.access(s, r);
                rsps.put(s);
            end
        endtask

        // Ready while a response waits.
        virtual function void comb();
            apb_rsp_t s = rsps.peek();
            pins.pready.write(rsps.valid());
            pins.prdata.write(s.rdata);
            pins.pslverr.write(rsps.valid() && s.slverr);
        endfunction

        // Gives each request at its setup edge; takes the response at the
        // edge that ends the transfer.
        virtual function void step();
            apb_req_t r;
            apb_rsp_t s;
            if (busy) begin
                if (pins.pready.read()) begin
                    void'(rsps.take(s));
                    busy = 0;
                end
            end else if (pins.psel.read() && !pins.penable.read()) begin
                r.addr  = pins.paddr.read();
                r.wdata = pins.pwdata.read();
                r.write = pins.pwrite.read();
                busy = reqs.give(r);
            end
        endfunction

        virtual function void reset_state();
            busy = 0;
        endfunction
    endclass
endpackage
