// One pin-level field of a bundle and its direction.
//
// Pin direction of a field, relative to the bundle's first role: FW_FWD is
// driven by the first role (e.g. the manager), FW_REV by the second.
typedef enum bit { FW_FWD = 1'b0, FW_REV = 1'b1 } fw_dir_e;

// The other direction.
function automatic fw_dir_e fw_dir_flip(fw_dir_e d);
    return (d == FW_FWD) ? FW_REV : FW_FWD;
endfunction

// One pin of a bundle.
typedef struct {
    string       name;          // pin name without prefix, e.g. "awaddr"
    int unsigned width;
    fw_dir_e     dir;
} fw_field_t;
