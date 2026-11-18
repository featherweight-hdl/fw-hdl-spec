// Addressed, byte-strobed memory access: the protocol-neutral mem API.
//
// Code written against it does not change when the bus does: an adapter
// per protocol (AXI, Wishbone, ...) maps it onto that protocol's API.
// Outputs lead: ``data = read(addr)``.
//
// :param ADDR: the address type
// :param DATA: the data type
// :param STRB: the byte-strobe type
interface class fw_mem_if #(type ADDR = logic [31:0],
                            type DATA = logic [31:0],
                            type STRB = logic [3:0]);
    // Writes ``data``, qualified by ``strb``, to ``addr``; ``err`` is 1 on
    // a bus error.
    pure virtual task write(output bit err, input ADDR addr, input DATA data,
                            input STRB strb);
    // Reads ``addr`` into ``data``; ``err`` is 1 on a bus error.
    pure virtual task read(output DATA data, output bit err, input ADDR addr);
endclass
