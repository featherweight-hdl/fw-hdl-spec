// One request and its response: the protocol-neutral call API.
//
// Outputs lead: ``rsp = call(req)``.
//
// :param Treq: the request type
// :param Trsp: the response type
interface class fw_reqrsp_if #(type Treq = int, type Trsp = int);
    // Sends ``req`` and returns its response in ``rsp``.
    pure virtual task call(output Trsp rsp, input Treq req);
endclass
