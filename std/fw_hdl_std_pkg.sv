// fw_hdl_std_pkg.sv: the fw-hdl standard library, hand-written source.
//
// Written only against the core API (fw_hdl_pkg). Its derived collateral
// (proxies, listeners, transaction classes, ...) is not here: the kit
// stage (fe-sv's GenKit) generates it from this package at build time.

`include "fw_hdl_macros.svh"

package fw_hdl_std_pkg;
    import fw_hdl_pkg::*;

    // The protocol-neutral APIs.
    `include "fw_put_if.svh"
    `include "fw_get_if.svh"
    `include "fw_reqrsp_if.svh"
    `include "fw_mem_if.svh"

    // The ready/valid protocol and its bundle type.
    `include "fw_rv_proto.svh"
    `include "fw_rv_if.svh"
    `include "fw_rv_xtor.svh"
    `include "fw_to_sync_ep.svh"
    `include "fw_from_sync_ep.svh"

    // The base of a kit's timed channels.
    `include "fw_timed_channel.svh"

    // Runtime pieces (ported from fw-proto-axi-new's fw_proto_pkg).
    `include "fw_field.svh"
    `include "fw_inbox.svh"
endpackage
