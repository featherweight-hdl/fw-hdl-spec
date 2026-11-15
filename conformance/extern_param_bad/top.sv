// Module parameters that do not fit the module (FW-E-EXT-PARAM, on the
// extern; needs the module header): one mistake per instance.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    typedef enum { E_A, E_B } local_e;

    class ext extends fw_component implements fw_extern_if;
        typedef struct { int mistake; } params_t;
        static function params_t mk_params(int mistake = 0);
            params_t p;
            p.mistake = mistake;
            return p;
        endfunction
        `fw_component_params
        `fw_extern_utils(ext, "bad_mod")

        virtual function void extern_map(fw_extern_map m);
            case (params.mistake)
                0: m.param("NOPE", fw_value #(int)::of(1));          // no such parameter
                1: m.param("N",    fw_value #(string)::of("1"));     // a string for an int
                2: m.param("S",    fw_value #(int)::of(1));          // an int for a string
                3: m.param("N",    fw_type #(bit)::get());           // a type for a value
                4: m.param("T",    fw_value #(int)::of(1));          // a value for a type
                5: m.param("N",    fw_value #(local_e)::of(E_B));    // an enum for an int
                default: m.param("N", fw_value #(int)::of(2));       // fits
            endcase
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        ext e[];
        virtual function void build();
            e = new[7];
            foreach (e[i]) e[i] = ext::create($sformatf("e[%0d]", i), this, ext::mk_params(.mistake(i)));
        endfunction
    endclass

endpackage
