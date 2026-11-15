Worked example
==============

The API's smoke test: an abstract FIFO with an RTL realization, a chain of
FIFOs whose realization is chosen through a constructor factory, a monitor,
and an integrator that overrides one FIFO deep inside the chain. The spec
compiles and elaborates it against the default bodies; behavior is tested in
each tool.

.. literalinclude:: ../tests/sv/smoke/smoke_pkg.sv
   :language: systemverilog
