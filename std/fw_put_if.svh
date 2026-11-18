// Sends one item: the protocol-neutral put API.
//
// :param T: the item type
interface class fw_put_if #(type T = int);
    // Sends ``t``; returns when it is accepted.
    pure virtual task put(input T t);
endclass
