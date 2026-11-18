// An API's handle: one object per specialization of an API interface
// class, returned by ``fw_api_type_of #(API)::get()``
// (:sv:class:`fw_api_type_of`). An interface class cannot register itself
// or be passed as a value, so the handle stands for it.
virtual class fw_api_type;

    // Returns the API's name: its canonical type spelling, with parameters.
    //
    // :returns: the name
    extern function string name();

    // Returns the API's family: the interface class's name, without
    // parameters (``fw_put_if``).
    //
    // :returns: the family name
    extern function string family();

    // Returns every protocol that registers the API, in registration
    // order. A neutral API (``put``, ``mem``) belongs to many.
    //
    // :returns: the protocols' handles
    extern function fw_protocol_type_q protocols();

endclass
