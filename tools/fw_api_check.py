"""The fw-hdl API check and spec lint (core-layer1.md 4.1).

API check: a tool's ``fw_hdl_pkg`` must declare the spec's API unchanged.
It parses both packages with pyslang (syntax only) and requires that

- every package item of the spec's ``fw_hdl_pkg`` (classes, typedefs) appears
  in the tool's package with the same text, ignoring comments and
  whitespace, and in the same order;
- every other item of the tool's package is either named ``__fw_...`` (a class,
  typedef or parameter of the tool's own), or an out-of-block body of an
  ``extern`` method of an API class;
- every ``extern`` method of an API class has exactly one body;
- each API macro, expanded in a probe class with the tool's
  ``fw_hdl_macros.svh``, declares the members the spec's expansion declares,
  plus only names beginning ``__fw_``.

Spec lint (``--lint``): the spec's package has no method bodies except in
``fw_rv_if`` (a bundle type written with the API) and the domain kind
classes (a kind's static functions are its definition), and no out-of-block
bodies.

Usage::

    python fw_api_check.py --spec <fw-hdl-spec>/bindings/sv \\
        --pkg <tool>/fw_hdl_pkg.sv -I <dir> [-I <dir> ...]
    python fw_api_check.py --spec <fw-hdl-spec>/bindings/sv --lint

Exit status 0 when the check passes; each problem is printed on one line.
"""
import argparse
import os
import re
import sys
import tempfile

import pyslang
from pyslang import syntax

SK = syntax.SyntaxKind
PKG = "fw_hdl_pkg"
# Classes whose methods may have bodies in the spec.
BODY_OK = {"fw_rv_if", "fw_domain_kind", "fw_domain_kind_type_of",
           "fw_clock_kind", "fw_reset_kind"}
MACROS = {
    "fw_component_utils": "`fw_component_utils(probe)",
    "fw_extern_utils": "`fw_extern_utils(probe, \"probe_mod\")",
    "fw_component_params": "`fw_component_params",
    "fw_component_params_init": "`fw_component_params_init(probe_init)",
    "fw_domain_kind_utils": "`fw_domain_kind_utils(probe)",
}


def canon(node) -> str:
    """The text of a syntax node without comments, whitespace collapsed."""
    s = str(node)
    s = re.sub(r"//[^\n]*", " ", s)
    s = re.sub(r"/\*.*?\*/", " ", s, flags=re.S)
    return " ".join(s.split())


def parse(path, incdirs, defines=()):
    sm = pyslang.SourceManager()
    for d in incdirs:
        sm.addUserDirectories(d)
    opts = pyslang.Bag()
    if defines:
        pp = pyslang.PreprocessorOptions()
        pp.predefines = list(defines)
        opts = pyslang.Bag([pp])
    tree = syntax.SyntaxTree.fromFile(path, sm, opts)
    return tree


def package_items(tree, name=PKG):
    for m in tree.root.members:
        if m.kind == SK.PackageDeclaration and m.header.name.valueText == name:
            return list(m.members)
    return None


def item_name(it) -> str:
    """The declared name of a package item, or '' when it has none."""
    k = it.kind
    if k in (SK.ClassDeclaration, SK.TypedefDeclaration, SK.ForwardTypedefDeclaration):
        return it.name.valueText
    if k == SK.ParameterDeclarationStatement:
        decl = it.parameter
        return decl.declarators[0].name.valueText
    return ""


def is_class(it) -> bool:
    return it.kind == SK.ClassDeclaration


def body_target(it):
    """(class, method) of an out-of-block body, or None."""
    if it.kind not in (SK.FunctionDeclaration, SK.TaskDeclaration):
        return None
    name = it.prototype.name
    if name.kind != SK.ScopedName:
        return None
    return canon(name.left), canon(name.right)


def extern_methods(cls):
    """Names of the extern methods of a class declaration."""
    out = []
    for x in cls.items:
        if x.kind == SK.ClassMethodPrototype:
            if any(str(q.kind).endswith(".ExternKeyword") for q in x.qualifiers):
                out.append(canon(x.prototype.name))
    return out


def method_bodies(cls):
    return [x for x in cls.items if x.kind == SK.ClassMethodDeclaration]


def lint(spec_dir):
    errs = []
    tree = parse(os.path.join(spec_dir, "fw_hdl_pkg.sv"), [spec_dir])
    errs += ["spec: parse: %s" % d for d in diag_strings(tree)]
    items = package_items(tree)
    if items is None:
        return ["spec: no package %s" % PKG]
    for it in items:
        if body_target(it):
            errs.append("spec: out-of-block body %s::%s" % body_target(it))
        if is_class(it) and it.name.valueText not in BODY_OK:
            for b in method_bodies(it):
                errs.append("spec: %s has a method body (%s)" % (
                    it.name.valueText, canon(b.declaration.prototype.name)))
    return errs


def diag_strings(tree):
    out = []
    for d in tree.diagnostics:
        if d.isError():
            out.append(str(d.code))
    return out


def macro_members(macros_file, incdirs):
    """{macro: [member names]} for each API macro, expanded in a probe class."""
    out = {}
    with tempfile.TemporaryDirectory() as td:
        for name, use in MACROS.items():
            src = os.path.join(td, "probe.sv")
            with open(src, "w") as fp:
                fp.write('`include "%s"\nclass probe;\n    %s\nendclass\n' % (macros_file, use))
            tree = parse(src, incdirs + [os.path.dirname(macros_file)])
            names = []
            for m in tree.root.members:
                if m.kind == SK.ClassDeclaration:
                    for x in m.items:
                        names.extend(member_names(x))
            out[name] = names
    return out


def member_names(x):
    k = x.kind
    if k in (SK.ClassMethodDeclaration, SK.ClassMethodPrototype):
        n = x.declaration.prototype.name if k == SK.ClassMethodDeclaration else x.prototype.name
        return [canon(n)]
    if k == SK.ClassPropertyDeclaration:
        d = x.declaration
        if d.kind == SK.DataDeclaration:
            return [v.name.valueText for v in d.declarators]
        if hasattr(d, "name"):
            return [d.name.valueText]
    return ["<%s>" % k]


def check(spec_dir, pkg, incdirs, macros=None):
    errs = []
    st = parse(os.path.join(spec_dir, "fw_hdl_pkg.sv"), [spec_dir])
    tt = parse(pkg, incdirs)
    errs += ["tool: parse: %s" % d for d in diag_strings(tt)]
    s_items = package_items(st)
    t_items = package_items(tt)
    if t_items is None:
        return errs + ["tool: no package %s in %s" % (PKG, pkg)]
    spec_classes = {it.name.valueText: it for it in s_items if is_class(it)}
    # 1. every spec item, in order, unchanged
    t_canon = [canon(it) for it in t_items]
    pos = 0
    for it in s_items:
        c = canon(it)
        try:
            pos = t_canon.index(c, pos) + 1
        except ValueError:
            n = item_name(it) or c[:50]
            errs.append("tool: API item '%s' missing, changed or out of order" % n)
    spec_canon = set(canon(it) for it in s_items)
    # 2. everything else: __fw_ names, or bodies of API extern methods
    bodies = {}
    for it in t_items:
        c = canon(it)
        if c in spec_canon:
            continue
        bt = body_target(it)
        if bt:
            cls, meth = bt
            if cls not in spec_classes:
                errs.append("tool: body %s::%s is not of an API class" % bt)
            elif meth not in extern_methods(spec_classes[cls]):
                errs.append("tool: body %s::%s is not of an extern method" % bt)
            bodies[bt] = bodies.get(bt, 0) + 1
            continue
        n = item_name(it)
        if n in spec_classes:
            errs.append("tool: API class %s differs from the spec's" % n)
        elif not n.lower().startswith("__fw_"):
            errs.append("tool: package item '%s' is neither API nor __fw_" % (n or c[:50]))
    # 3. one body per extern method
    for cn, cls in spec_classes.items():
        for m in extern_methods(cls):
            k = bodies.get((cn, m), 0)
            if k != 1:
                errs.append("tool: %s::%s has %d bodies" % (cn, m, k))
    # 4. macros
    if macros:
        sm = macro_members(os.path.join(spec_dir, "fw_hdl_macros.svh"), [spec_dir])
        tm = macro_members(os.path.abspath(macros), incdirs)
        for name in MACROS:
            want, got = set(sm[name]), set(tm[name])
            for n in sorted(want - got):
                errs.append("tool: `%s does not declare %s" % (name, n))
            for n in sorted(got - want):
                if not n.startswith("__fw_"):
                    errs.append("tool: `%s declares %s, not in the API" % (name, n))
    return errs


def main(argv=None):
    ap = argparse.ArgumentParser(description="fw-hdl API check and spec lint")
    ap.add_argument("--spec", required=True, help="the spec's bindings/sv directory")
    ap.add_argument("--pkg", help="the tool's fw_hdl_pkg.sv")
    ap.add_argument("--macros", help="the tool's fw_hdl_macros.svh")
    ap.add_argument("-I", dest="incdirs", action="append", default=[], help="include directory")
    ap.add_argument("--lint", action="store_true", help="lint the spec itself")
    args = ap.parse_args(argv)
    spec = os.path.abspath(args.spec)
    if args.lint:
        errs = lint(spec)
        what = "spec lint"
    else:
        if not args.pkg:
            ap.error("--pkg is required unless --lint")
        errs = check(spec, os.path.abspath(args.pkg), [os.path.abspath(d) for d in args.incdirs],
                     args.macros)
        what = "API check"
    for e in errs:
        print(e)
    print("%s: %s" % (what, "FAIL (%d)" % len(errs) if errs else "PASS"))
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
