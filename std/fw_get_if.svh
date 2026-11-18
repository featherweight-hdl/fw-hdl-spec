// Receives one item: the protocol-neutral get API.
//
// :param T: the item type
interface class fw_get_if #(type T = int);
    // Returns the next item in ``t``.
    pure virtual task get(output T t);
endclass
