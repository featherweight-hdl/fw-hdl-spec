// A naming rule for the module pins of a bundle's members: the prefix, then
// the member's path within the bundle joined with ``_``, with per-member
// renames.
//
// Created by :sv:func:`fw_extern_map::prefix`::
//
//     void'(m.prefix(in, "in_").rename("valid", "vld").rename("ready", "rdy"));
class fw_pin_rule;

    // Uses ``pin_part`` in place of a member's flattened name.
    //
    // :param member: the member's path within the bundle
    // :param pin_part: the replacement
    // :returns: this rule, for chaining
    extern function fw_pin_rule rename(string member, string pin_part);

endclass
