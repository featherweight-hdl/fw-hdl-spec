// Shared test APIs for the conformance scenarios (protocols feature).
// Included inside a scenario's package, after ``import fw_hdl_pkg::*``.
`ifndef TEST_APIS_SVH
`define TEST_APIS_SVH

// Sends one item.
interface class test_put_if #(type T = int);
    pure virtual task put(T t);
endclass

// Receives one item.
interface class test_get_if #(type T = int);
    pure virtual task get(output T t);
endclass

`endif // TEST_APIS_SVH
