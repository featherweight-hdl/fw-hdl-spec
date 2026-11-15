// fw_hdl_pkg.sv: the package of the fw-hdl core API, layer 1.
//
// The API is declarations only (fw_hdl_api.svh): no method bodies. A tool
// provides its own fw_hdl_pkg, which includes fw_hdl_api.svh unchanged and
// supplies out-of-block bodies for every extern method:
//     package fw_hdl_pkg;
//         `include "fw_hdl_api.svh"
//         `include "<the tool's bodies>"
//     endpackage
// This file is that package with no bodies. It compiles only with
// generated default bodies (tools/fw_hdl_bodies.py, an sv-weave weaver,
// which the hook below includes), which is how the spec compile-checks code
// written against the API.

`include "fw_hdl_macros.svh"

// The fw-hdl core API, layer 1: components, signals, ports, bundles and
// externs.
//
// User code imports it and follows one recipe: declare fields with the API
// classes, and create anything with ``T::create``::
//
//     import fw_hdl_pkg::*;
//     `include "fw_hdl_macros.svh"
package fw_hdl_pkg;
    `include "fw_hdl_api.svh"
`ifdef SV_WEAVE_INCLUDE_fw_hdl_pkg
    `include `SV_WEAVE_INCLUDE_fw_hdl_pkg
`endif
endpackage
