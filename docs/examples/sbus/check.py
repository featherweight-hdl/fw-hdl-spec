"""Builds and runs the sbus example of docs/protocol-packages.rst.

    direnv exec . python packages/fw-hdl-spec/docs/examples/sbus/check.py <outdir>

1. GenKit (as Python): scan src/sbus_pkg.sv, write sbus_pkg_gen_pkg.sv.
2. Back to back: build tb/sbus_b2b.sv in Verilator against rt-sv and std,
   run it, require PASS; elaborate the same top_c with fe-sv (static
   checks), require no errors.
3. Against RTL: elaborate src/sbus_wrap_pkg.sv (rtl/sbus_mem_rtl.sv
   wrapped), emit Verilog, generate its testbench (gen_tb with monitors,
   gen_bind) from a scan of the kit and its generated package, build
   tb/sbus_rtl_tb.sv (the test, a subclass of the generated class) with it
   in Verilator, run it, require PASS.

Needs the packages of an fw-hdl workspace (fw-hdl-fe-sv, fw-hdl-rt-sv) and
verilator on PATH. Exits non-zero on the first failure.
"""
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SPEC = HERE.parents[2]
PKGS = SPEC.parent
STD = SPEC / "std"
BIND = SPEC / "bindings" / "sv"
RT = PKGS / "fw-hdl-rt-sv" / "sv"
VLT = ["verilator", "--binary", "-Wno-fatal", "-Wno-lint", "-Wno-style",
       "--timescale", "1ns/1ns", f"-I{RT}", f"-I{BIND}", f"-I{STD}"]
BASE = [str(RT / "fw_hdl_pkg.sv"), str(STD / "fw_hdl_std_pkg.sv")]


def run(cmd, log: Path, **kw):
    r = subprocess.run(cmd, capture_output=True, text=True, **kw)
    log.write_text(r.stdout + r.stderr)
    if r.returncode != 0:
        sys.exit(f"FAIL: {cmd[0]} (rc={r.returncode}), see {log}")
    return r.stdout


def sim(out: Path, name: str, top: str, files, edges: int):
    obj = out / f"obj_{name}"
    run(VLT + ["--top-module", top, "-Mdir", str(obj), "-o", "V" + name] + files,
        out / f"{name}.build.log")
    text = run([str(obj / ("V" + name)), f"+fw_edges={edges}"], out / f"{name}.run.log")
    ok = "PASS" in text.splitlines()
    print(f"{name}: {'PASS' if ok else 'FAIL'}")
    if not ok:
        sys.exit(f"FAIL: {name}, see {out / (name + '.run.log')}")


def main(out: Path):
    from fw.hdl.fe.sv import elaborate
    from fw.hdl.fe.sv.emit import emit_sv
    from fw.hdl.fe.sv.scan import scan
    from fw.hdl.gen import gen_bind, gen_kit, gen_tb

    out.mkdir(parents=True, exist_ok=True)
    src = HERE / "src"
    kit = str(src / "sbus_pkg.sv")
    inc = [str(STD), str(BIND)]

    # 1. GenKit
    s = scan([kit], incdirs=inc)
    if not s.ok:
        sys.exit(f"FAIL: scan: {[str(d) for d in s.diags]}")
    gen = out / "sbus_pkg_gen_pkg.sv"
    gen.write_text(gen_kit(s))
    kit_files = [kit, str(gen), str(src / "sbus_behav_pkg.sv")]

    # 2. Back to back
    b2b = kit_files + [str(HERE / "tb" / "sbus_b2b.sv")]
    sim(out, "b2b", "sbus_b2b", BASE + b2b + [str(HERE / "tb" / "sbus_b2b_top.sv")], 40)
    # The same composition through fe-sv's static elaboration.
    r = elaborate(b2b, top="sbus_b2b_pkg::top_c", incdirs=inc)
    if not r.ok:
        sys.exit(f"FAIL: elaborate b2b: {[str(d) for d in r.diags]}")
    print("b2b elaborate: PASS")

    # 3. Against RTL
    rtl = [str(HERE / "rtl" / "sbus_mem_rtl.sv")]
    r = elaborate([kit, str(gen), str(src / "sbus_wrap_pkg.sv")],
                  top="sbus_wrap_pkg::sbus_sys", incdirs=inc, rtl=rtl, lower=True)
    if not r.ok:
        sys.exit(f"FAIL: elaborate: {[str(d) for d in r.diags]}")
    ctxt, top = r.to_ir()
    res = emit_sv(ctxt, top, out / "emit", extern_files=rtl, top_module="sbus_sys")
    # The testbench: the kit's transactors and monitor, from a scan of the
    # kit and its generated package.
    xs = scan([kit, str(gen)], incdirs=inc)
    tb, bd = out / "sbus_sys_tb.sv", out / "sbus_sys_fw_mon.sv"
    tb.write_text(gen_tb(r, xs, "sbus_sys", bind=True))
    bd.write_text(gen_bind(r, xs, "sbus_sys"))
    files = BASE + [str(RT / "fw_pin_bridge.sv")] + kit_files \
        + res.filelist.read_text().split() + [str(tb), str(bd), str(HERE / "tb" / "sbus_rtl_tb.sv")]
    sim(out, "rtl", "sbus_rtl_tb", files, 60)


if __name__ == "__main__":
    main(Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "build")
