// The base of a protocol kit's timed channel (protocol-kit prep §3.5). A
// channel is a component the user places between two endpoints; each call
// through it takes the protocol's transfer time, so neither end times it.
// The kit's channel defines the time and the mismatch rule; this base
// holds the sampling and the delay::
//
//     class uart_txrx_chan extends fw_timed_channel #(uart_cfg_t, uart_byte_t) ...
//         virtual function time xfer_time(uart_cfg_t cfg, uart_byte_t t);
//             return uart_frame_time(cfg);
//         endfunction
//         virtual function uart_byte_t mismatch(uart_cfg_t tx_cfg,
//                 uart_cfg_t rx_cfg, uart_byte_t t);
//             if (tx_cfg.baud != rx_cfg.baud) t.frame_err = 1;
//             return t;
//         endfunction
//         virtual task put(input uart_byte_t t);      // from side a
//             uart_byte_t rx;
//             xfer_sink(a.cfg, b.cfg, t, rx);
//             b.get_if().put(rx);
//         endtask
//
// A *forwarding* channel (a device and a VIP, one configuration) uses
// ``xfer_fwd``; a *sinking* channel (two devices, each with its own
// configuration) uses ``xfer_sink``, timed by the sender's configuration.
// Both block the caller for the transfer and then return, so the channel
// delivers unbuffered (block-then-deliver). A channel that should return
// at once queues the payload and delivers it from its own ``run()``.
//
// Simulation-only: it uses :sv:class:`fw_time`.
//
// :param CFG: the configuration struct
// :param T: the payload type
virtual class fw_timed_channel #(type CFG = int, type T = int) extends fw_component;

    // The time to transfer ``t`` under the sender's configuration.
    //
    // :param cfg: the sender's configuration
    // :param t: the payload
    // :returns: the transfer time
    pure virtual function time xfer_time(CFG cfg, T t);

    // The payload as a receiver configured with ``rx_cfg`` sees ``t``, sent
    // under ``tx_cfg`` (for UART, with ``frame_err`` set when the baud rates
    // differ). Called by ``xfer_sink`` only. The default returns ``t``.
    //
    // :param tx_cfg: the sender's configuration
    // :param rx_cfg: the receiver's configuration
    // :param t: the payload as sent
    // :returns: the payload as received
    virtual function T mismatch(CFG tx_cfg, CFG rx_cfg, T t);
        return t;
    endfunction

    // Forwarding: waits the transfer time of ``t`` under ``cfg``, sampled
    // at the call. The payload is delivered as sent.
    //
    // :param cfg: the configuration
    // :param t: the payload
    protected task xfer_fwd(input CFG cfg, input T t);
        fw_time::delay(xfer_time(cfg, t));
    endtask

    // Sinking: waits the transfer time of ``t`` under ``tx_cfg``, then
    // returns in ``rx`` the payload as the receiver sees it. Both
    // configurations are sampled at the call, the start of the transfer.
    //
    // :param tx_cfg: the sender's configuration
    // :param rx_cfg: the receiver's configuration
    // :param t: the payload as sent
    // :param rx: the payload as received
    protected task xfer_sink(input CFG tx_cfg, input CFG rx_cfg, input T t, output T rx);
        fw_time::delay(xfer_time(tx_cfg, t));
        rx = mismatch(tx_cfg, rx_cfg, t);
    endtask
endclass
