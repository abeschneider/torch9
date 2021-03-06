local argcheck = require 'argcheck'

local dispatch =
   argcheck{
   {{name="idx", type="number", default=1}},
   function(idx)
      local env = {idx=idx, funcs={}, type=type, select=select, error=error, string=string}
      local func =
         function(...)
            local typename = type(select(idx, ...))
            local func = funcs[typename]
            if not func then
               error(string.format('function not implemented for type <%s>', typename))
            else
               return func(...)
            end
         end
      setfenv(func, env)
      return func
   end,

   {{name="idxfunc", type="function"}},
   function(idxfunc) -- ARG, the idxfunc might be the same for several functions...
      local env = {funcs={}}
      setmetatable(env, {__index=getfenv(1)})
      local func =
         function(...)
            setfenv(idxfunc, env) -- ... workaround
            return idxfunc(...)
         end
      setfenv(func, env) -- because that is how we define new dispatch functions below
      return func
   end,
   
   {{name="func", type="function"},
    {name="typename", type="string"},
    {name="functypename", type="function"}},
   function(func, typename, functypename)
      getfenv(func).funcs[typename] = functypename
   end
}

return dispatch
