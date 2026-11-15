"""sv-weave weaver: default bodies for the fw_hdl_pkg API.

The API (bindings/sv/fw_hdl_api.svh) is declarations only: every method is an
`extern` prototype. To compile code written against the API with no tool behind
it, this weaver gives every extern method of every class in fw_hdl_pkg an
out-of-block body that does nothing: a void method is empty, any other returns
a default value. The bodies go into fw_hdl_pkg through sv-weave's package
include (``SyntaxCtx.add_package_include``).

The output is generated, never checked in or edited: anything a body would do
is a tool's business, not the spec's.
"""
from sv_weave.plugin import Weaver

PACKAGE = "fw_hdl_pkg"


def _ret(decl, ret: str) -> str:
    """The return type as an out-of-block body names it: a class typedef or
    parameter needs the class scope."""
    local = set(decl.param_names) | {t.name for t in decl.typedefs}
    return "%s::%s" % (decl.name, ret) if ret in local else ret


def _arg(a) -> str:
    return " ".join(x for x in (a.type, a.name, a.dims) if x)


def bodies(decl) -> list:
    """Out-of-block default bodies for the extern methods of one class."""
    out = []
    for m in decl.methods:
        if "extern" not in m.qualifiers:
            continue
        args = ", ".join(_arg(a) for a in m.args)
        if m.is_task:
            out.append("task %s::%s(%s); endtask" % (decl.name, m.name, args))
        elif m.is_void:
            out.append("function void %s::%s(%s); endfunction" % (decl.name, m.name, args))
        else:
            ret = _ret(decl, m.ret)
            out.append("function %s %s::%s(%s); %s __r; return __r; endfunction"
                       % (ret, decl.name, m.name, args, ret))
    return out


class DefaultBodies(Weaver):
    """Runs in the syntax pre-pass: the API does not elaborate without bodies."""
    name = "fw_hdl_bodies"
    version = "0.1"

    def subscribe(self, bus):
        bus.on_syntax(self.gen)

    def gen(self, s):
        lines = []
        for c in s.classes():
            if c.package != PACKAGE or c.decl is None or c.decl.is_interface:
                continue
            lines.extend(bodies(c.decl))
        s.add_package_include(PACKAGE, "\n".join(lines) + "\n")
