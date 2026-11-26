// fw_acc.svh: acc ("access"), optional run-time access to a design's types
// and values, for testing, debug and reporting. Part of fw_hdl_pkg.
//
// Optionality is registration, not a package boundary: a static front end
// generates the accessors (fe-sv: fw.hdl.gen.acc) and they register here;
// with none registered, every query returns null and reports have no text.
// Nothing in a design refers to acc, and a tool's elaboration never calls
// it: it keeps typed values while it elaborates and asks acc for their text
// only when it reports them.
//
// Most of it is plain SV, the same in every tool: the registry (fw_acc), the
// field record, the accessors' defaults, fw_acc_component_of's
// registration and lookup, fw_acc_ctor_names. Only what needs the tool's
// elaboration data is extern: fw_acc::path, fw_acc_value_of::get/set (the
// tool links an accessor to the values it holds) and
// fw_acc_component_of::params/param_src (the tool's params snapshots).

typedef class fw_acc;

// A field of a value: its name and its text (JSON, as the netlist writes
// values; for :sv:func:`fw_acc_component::param_src`, the source's name).
class fw_acc_field;
    string name;
    string text;
endclass

// A list of fields.
typedef fw_acc_field fw_acc_field_q[$];

// A registered type's handle.
virtual class fw_acc_type;

    // Returns the type's canonical spelling, as the netlist writes it.
    //
    // :returns: the name
    pure virtual function string name();

endclass

// A list of type handles, as :sv:func:`fw_acc::types` returns.
typedef fw_acc_type fw_acc_type_q[$];

// The accessor of type ``T``: its name and the text of its values. A
// generated subclass overrides what ``T`` supports and registers itself
// with :sv:func:`fw_acc_value_of::set`; the defaults give no text.
//
// :param T: the type
virtual class fw_acc_value_of #(type T = int) extends fw_acc_type;

    // This class, for out-of-block method bodies.
    typedef fw_acc_value_of #(T) this_t;

    // Returns value ``v`` as text (JSON), or ``"null"``.
    //
    // :param v: the value
    // :returns: the text
    virtual function string text(T v);
        return "null";
    endfunction

    // Appends the top-level fields of value ``v`` (a struct), in
    // declaration order.
    //
    // :param v: the value
    // :param out: the list to append to
    // :returns: 1 if ``T`` has fields, else 0
    virtual function bit fields(T v, ref fw_acc_field out[$]);
        return 0;
    endfunction

    // Returns value ``v`` as SV literal text (an extern parameter's
    // value), or ``""``.
    //
    // :param v: the value
    // :returns: the text
    virtual function string literal(T v);
        return "";
    endfunction

    // Returns the accessor registered for ``T``, or null.
    //
    // :returns: the accessor
    extern static function this_t get();

    // Registers ``a`` as ``T``'s accessor; the first registration wins.
    // The tool also links it to the values it holds of type ``T``.
    //
    // :param a: the accessor
    extern static function void set(this_t a);

endclass

// A handle on a component: its class's name and its params.
virtual class fw_acc_component;

    // The component; null in a registered prototype.
    fw_component m_obj;

    // Its class's depth in the class hierarchy: the most derived
    // registered class that accepts an object makes its handle.
    int m_depth;

    // Returns the component's class's canonical spelling.
    //
    // :returns: the name
    pure virtual function string name();

    // Returns 1 if ``o`` is an object of this class.
    //
    // :param o: the object
    // :returns: 1 or 0
    pure virtual function bit accepts(fw_object o);

    // Returns a handle of this class on component ``c``.
    //
    // :param c: the component
    // :returns: the handle
    pure virtual function fw_acc_component make(fw_component c);

    // Appends the fields of the component's params value.
    //
    // :param out: the list to append to
    // :returns: 1 if the params value has fields, else 0
    pure virtual function bit params(ref fw_acc_field out[$]);

    // Appends, for each params field that a source set, the source that
    // last set it (``creator``, ``override``, ``global``, ``init``) as
    // the field's text.
    //
    // :param out: the list to append to
    // :returns: 1 if the params value has fields, else 0
    pure virtual function bit param_src(ref fw_acc_field out[$]);

endclass

// The handle of component class ``C``. Generated code registers ``C``
// with :sv:func:`fw_acc_component_of::register`.
//
// :param C: the component class
class fw_acc_component_of #(type C = fw_component) extends fw_acc_component;

    // This class, for out-of-block method bodies.
    typedef fw_acc_component_of #(C) this_t;

    string m_name;

    // Registers class ``C``.
    //
    // :param name: its canonical spelling
    // :param depth: its depth in the class hierarchy
    static function void register(string name, int depth);
        this_t p = new;
        p.m_name = name;
        p.m_depth = depth;
        fw_acc::add_component(p);
    endfunction

    virtual function string name();
        return m_name;
    endfunction

    virtual function bit accepts(fw_object o);
        C c;
        return o != null && $cast(c, o);
    endfunction

    virtual function fw_acc_component make(fw_component c);
        this_t h = new;
        h.m_name = m_name;
        h.m_depth = m_depth;
        h.m_obj = c;
        return h;
    endfunction

    extern virtual function bit params(ref fw_acc_field out[$]);
    extern virtual function bit param_src(ref fw_acc_field out[$]);

endclass

// The names of the constructor factories of base ``B``, by handle: a
// params field holding one is written as the name of the realization it
// creates. Generated code adds the factories it knows.
//
// :param B: the base class
class fw_acc_ctor_names #(type B = fw_component);

    static fw_ctor #(B) m_handles[$];
    static string       m_names[$];

    // Names factory ``h``.
    //
    // :param h: the factory
    // :param name: its realization's canonical spelling
    static function void add(fw_ctor #(B) h, string name);
        if (h == null) return;
        foreach (m_handles[i]) if (m_handles[i] == h) return;
        m_handles.push_back(h);
        m_names.push_back(name);
    endfunction

    // Returns factory ``h`` as text (JSON): its name, or ``"null"``.
    //
    // :param h: the factory
    // :returns: the text
    static function string text(fw_ctor #(B) h);
        if (h == null) return "null";
        foreach (m_handles[i]) if (m_handles[i] == h) return fw_acc::jstr(m_names[i]);
        return "null";
    endfunction

endclass

// The handle factory: the registry of every registered type and component
// class.
class fw_acc;

    static fw_acc_type      m_types[$];
    static fw_acc_component m_comps[$];

    // Adds type ``t`` (:sv:func:`fw_acc_value_of::set` calls it).
    //
    // :param t: the type's handle
    static function void add_type(fw_acc_type t);
        m_types.push_back(t);
    endfunction

    // Returns every registered type, in registration order.
    //
    // :returns: the handles
    static function fw_acc_type_q types();
        return m_types;
    endfunction

    // Adds a component class (:sv:func:`fw_acc_component_of::register`
    // calls it).
    //
    // :param c: the class's prototype
    static function void add_component(fw_acc_component c);
        m_comps.push_back(c);
    endfunction

    // Returns a handle on component ``c`` from the most derived registered
    // class that accepts it, or null.
    //
    // :param c: the component
    // :returns: the handle
    static function fw_acc_component component(fw_component c);
        fw_acc_component best;
        if (c == null) return null;
        foreach (m_comps[i])
            if ((best == null || m_comps[i].m_depth > best.m_depth) && m_comps[i].accepts(c))
                best = m_comps[i];
        return best == null ? null : best.make(c);
    endfunction

    // Returns object ``o``'s path as text (JSON), or ``"null"``.
    //
    // :param o: the object
    // :returns: the text
    extern static function string path(fw_object o);

    // Returns ``s`` as a JSON string literal.
    //
    // :param s: the text
    // :returns: the literal
    static function string jstr(string s);
        string r = "\"";
        for (int i = 0; i < s.len(); i++) begin
            if (s[i] == "\"" || s[i] == "\\") r = {r, "\\"};
            r = {r, s.substr(i, i)};
        end
        return {r, "\""};
    endfunction

endclass
