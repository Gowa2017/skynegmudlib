function bind(fn, obj) return function(...) return fn(obj, ...) end end

return { bind = bind }
