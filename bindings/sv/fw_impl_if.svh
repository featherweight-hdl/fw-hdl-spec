// A tool's handle on an object. It is empty: it has no API.
//
// A tool stores an object of its own class, implementing this interface, in
// :sv:obj:`fw_object::__fw_impl`, and downcasts to it in its method bodies.
// User code never uses it.
interface class fw_impl_if;
endclass
