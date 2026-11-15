# Bundles

A **bundle type** is a named, ordered group of ports and nested bundles.
Member directions are written from the **initiator's** point of view. A
bundle type is never used directly; every use names a **role**:

| Role | Netlist kind | Effective direction of a member declared `out` |
|---|---|---|
| initiator | `bundle` | out |
| mirror (target) | `mirror` | in |
| monitor | `monitor` | in (every member is an input) |

- Bundles nest: a member may be a bundle of another type, in a role. AXI is
  five channel bundles, with `r` and `b` mirrored.
- **Effective direction.** Start from the member's declared direction and
  walk from the member up to its scope (the component owning the outermost
  bundle): each mirror on the path flips `in`/`out`; if any monitor is on
  the path the member is `in`. An `inout` member stays `inout` in every
  role, including under a monitor. A mirror inside a mirror therefore keeps
  the declared direction.
- A bundle may be an array, like a port.
- The netlist lists a bundle as an object (kind = role, type = the bundle
  type without the role) and each member as an object of its own, ports
  with their effective direction.
- **Flattening.** Emitted RTL flattens a bundle to one port per member,
  named by its path relative to the component with `.` replaced by `_`:
  `out_valid`, `axi_aw_addr`. Array indices stay: `in[0].valid` flattens to
  `in[0]_valid`. Two ports, signals or bundle members of one component with
  the same flattened name are `FW-E-NAME-FLAT`, on the one created later.

Bundle connections are member-wise ([connections](connections.md)).
