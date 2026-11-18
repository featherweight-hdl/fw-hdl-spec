// Timed kit channels (protocol-kit prep §3.5), placed by the user. A
// device d sends two characters to a VIP v through a forwarding
// uart_tx_chan f: each takes its transfer time under d's configuration
// (50 ns at 200 Mbaud, 100 ns at 100 Mbaud), and v sees d's configuration
// through f. Two devices ua and ub are joined by a sinking uart_txrx_chan
// x: each character is timed by its sender's configuration, and once ub
// moves to 100 Mbaud (at 55) the characters either way arrive with
// frame_err set. Every send starts off a clock edge, and every delivery
// is committed at the next edge.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_proc.svh"
    `include "test_uart_chan.svh"

    // Records the last character received and when.
    virtual class rx_rec extends fw_component implements uart_put_if;
        fw_output #(bit [7:0]) data;
        fw_output #(bit)       err;
        fw_output #(time)      t;
        virtual function void build();
            data = fw_output #(bit [7:0])::create("data", this);
            err  = fw_output #(bit)::create("err", this);
            t    = fw_output #(time)::create("t", this);
        endfunction
        virtual task put(uart_char_t c);
            data.write(c.data);
            err.write(c.frame_err);
            t.write(fw_time::now());
        endtask
    endclass

    // A device with a configured port: 0x11 at 200 Mbaud, then 0x12 at 100.
    class dev extends fw_component implements fw_run_if;
        `fw_component_utils(dev)
        fw_port_cfg_src #(uart_put_if, uart_cfg_t) p;
        virtual function void build();
            p = fw_port_cfg_src #(uart_put_if, uart_cfg_t)::create("p", this);
            p.set('{baud: 200_000_000, parity: 0, stop_bits: 1});
        endfunction
        virtual task run();
            uart_put_if i = p.get_if();
            fw_time::delay(5ns);
            i.put('{data: 8'h11, frame_err: 0});
            p.set('{baud: 100_000_000, parity: 0, stop_bits: 1});
            i.put('{data: 8'h12, frame_err: 0});
        endtask
    endclass

    // The VIP: also records the baud rate it sees from the device.
    class vip extends rx_rec;
        `fw_component_utils(vip)
        fw_export_cfg_sink #(uart_put_if, uart_cfg_t) e;
        fw_output #(int unsigned) baud;
        virtual function void build();
            super.build();
            e = fw_export_cfg_sink #(uart_put_if, uart_cfg_t)::create("e", this);
            baud = fw_output #(int unsigned)::create("baud", this);
            e.set_imp(this);
        endfunction
        virtual task put(uart_char_t c);
            super.put(c);
            baud.write(e.cfg.baud);
        endtask
    endclass

    // A device on the two-way link, at 200 Mbaud.
    virtual class uart extends rx_rec;
        fw_socket_cfg_src #(uart_put_if, uart_put_if, uart_cfg_t) s;
        virtual function void build();
            super.build();
            s = fw_socket_cfg_src #(uart_put_if, uart_put_if, uart_cfg_t)::create("s", this);
            s.set_imp(this);
            s.set('{baud: 200_000_000, parity: 0, stop_bits: 1});
        endfunction
    endclass

    // Sends 0x21 at 5 (arrives 55) and 0x22 at 62, after ub's change
    // (arrives 112, frame_err).
    class uart_a extends uart implements fw_run_if;
        `fw_component_utils(uart_a)
        virtual task run();
            uart_put_if i = s.get_if();
            fw_time::delay(5ns);
            i.put('{data: 8'h21, frame_err: 0});
            fw_time::delay(7ns);
            i.put('{data: 8'h22, frame_err: 0});
        endtask
    endclass

    // Sends 0x31 at 5 (arrives 55), moves to 100 Mbaud, sends 0x32 (100 ns,
    // arrives 155, frame_err).
    class uart_b extends uart implements fw_run_if;
        `fw_component_utils(uart_b)
        virtual task run();
            uart_put_if i = s.get_if();
            fw_time::delay(5ns);
            i.put('{data: 8'h31, frame_err: 0});
            s.set('{baud: 100_000_000, parity: 0, stop_bits: 1});
            i.put('{data: 8'h32, frame_err: 0});
        endtask
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        dev            d;
        uart_tx_chan   f;
        vip            v;
        uart_a         ua;
        uart_txrx_chan x;
        uart_b         ub;
        virtual function void build();
            super.build();
            d  = dev::create("d", this);
            f  = uart_tx_chan::create("f", this);
            v  = vip::create("v", this);
            ua = uart_a::create("ua", this);
            x  = uart_txrx_chan::create("x", this);
            ub = uart_b::create("ub", this);
        endfunction
        virtual function void connect();
            super.connect();
            d.p.connect(f.dev);
            f.vip.connect(v.e);
            x.a.connect(ua.s);
            x.b.connect(ub.s);
        endfunction
    endclass

endpackage
