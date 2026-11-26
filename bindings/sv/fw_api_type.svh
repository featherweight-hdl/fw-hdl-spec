// An API's handle: one object per specialization of an API interface
// class, returned by ``fw_api_type_of #(API)::get()``
// (:sv:class:`fw_api_type_of`). An interface class cannot register itself
// or be passed as a value, so the handle stands for it.
virtual class fw_api_type;
endclass
