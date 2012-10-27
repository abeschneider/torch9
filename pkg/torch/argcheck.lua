local function callfunc(funcname, vars, argdefs)
   local txt = {}
   if #vars > 0 then
      -- defaulta
      for _,argdef in ipairs(argdefs) do
         if argdef.defaulta then
            local isvalid = false
            for _,var in ipairs(vars) do
               if var == argdef.defaulta then
                  isvalid = true
                  break
               end
            end
            if not isvalid then
               error(string.format('argument <%s> defaulta is not a valid argument', argdef.name, argdef.defaulta))
            end
            table.insert(txt, string.format('%s = %s or %s', argdef.name, argdef.name, argdef.defaulta))
         end
      end
      table.insert(txt, string.format('return %s(%s)', funcname, table.concat(vars, ', ')))
   else
      table.insert(txt, string.format('return %s()', funcname))
   end
   return table.concat(txt, '\n')
end

local function generateargcheck(argdefs, funcname)
   local txt = {}
   local vars = {}
   local hasvararg = false
   for _,argdef in ipairs(argdefs) do
      assert(type(argdef.name) == 'string', string.format('argument name must be a string'))

      -- defined only once?
      if vars[argdef.name] then
         error(string.format('argument %s is defined twice', argdef.name))
      end

      -- nonamed inconsistency?
      if argdef.named and argdefs.nonamed then
         error(string.format('argument %s is defined as named, but named argument are not allowed', argdef.name))
      end

      -- default inconsistency?
      if argdef.default and argdef.defaulta then
         error(string.format('argument %s defines <default> and <defaulta>, which is not allowed', argdef.name))
      end

      -- is it a predefined type?
      if torch.argtypes[argdef.type] then
         setmetatable(argdef, {__index=torch.argtypes[argdef.type]})
      end

      assert(not argdef.initdefault or type(argdef.initdefault) == 'function', string.format('argument <%s> initdefault member must be a function', argdef.name))
      assert(not argdef.read or type(argdef.read) == 'function', string.format('argument <%s> read member must be a function', argdef.name))
      assert(not argdef.check or type(argdef.check) == 'function', string.format('argument <%s> check member must be a function', argdef.name))

      -- is it a vararg?
      if argdef.vararg then
         if hasvararg then
            error('multiple variable arguments are not allowed')
         end
         hasvararg = true
      else
         if hasvararg and not argdef.named then
            error(string.format('argument <%s> is defined after a variable argument, which is not allowed', argdef.name))
         end
      end
      vars[argdef.name] = true
      table.insert(vars, argdef.name)
   end
   if #vars > 0 then
      table.insert(txt, 'do')
      table.insert(txt, string.format('local %s', table.concat(vars, ', ')))

      -- handling of named arguments
      if not argdefs.nonamed then
         table.insert(txt, "if narg == 1 and type(select(1, ...)) == 'table' then")
         table.insert(txt, "local arg = select(1, ...)")

         local checks = {}
         for _,argdef in ipairs(argdefs) do
            argdef.luaname = string.format('arg.%s', argdef.name)
            
            if argdef.named or argdef.default then
               -- argument might not be provided
               if argdef.check and argdef:check() then
                  table.insert(checks, string.format('(%s == nil or (%s))',
                                                     argdef.luaname,
                                                     argdef:check()))
               end
            else
               -- argument must be provided
               if argdef.check and argdef:check() then
                  table.insert(checks, string.format('%s', argdef:check()))
               else
                  table.insert(checks, string.format('%s', argdef.luaname))
               end
            end
         end
         table.insert(txt, string.format('if %s then', table.concat(checks, ' and ')))

         -- assign local variables
         for _,argdef in ipairs(argdefs) do
            if argdef.default then
               if argdef.initdefault and argdef:initdefault() then
                  table.insert(txt, string.format('%s = %s or %s', argdef.name, argdef.luaname, argdef:initdefault()))
               else
                  error(string.format('argument <%s> has a default argument which cannot be handled', argdef.name))
               end
            else
               table.insert(txt, string.format('%s = %s', argdef.name, argdef.luaname))
               if argdef.read and argdef:read() then
                  table.insert(txt, argdef:read())
               end
            end
         end

         table.insert(txt, callfunc(funcname, vars, argdefs))
         table.insert(txt, 'end') -- of arg checks
         table.insert(txt, 'end') -- of named check
      end

      -- handling of ordered arguments   
      local ndef = 0
      local nreq = 0
      for _,argdef in ipairs(argdefs) do
         if not argdef.named then
            if argdef.default then
               ndef = ndef + 1
            else
               nreq = nreq + 1
            end
         end   
      end

      if ndef > 0 or nreq > 0 then
         for defmask=0,2^ndef-1 do
            local argidx = 0
            local defidx = 0
            local checks = {''}
            local reads = {}
            local hasvararg = false
            for _,argdef in ipairs(argdefs) do
               local isvalid = false
               if not argdef.named then
                  if argdef.default then
                     defidx = defidx + 1
                     if bit.band(defidx, defmask) ~= 0 then
                        isvalid = true
                     end
                  else
                     isvalid = true
                  end
                  if isvalid then
                     argidx = argidx + 1
                     if argdef.vararg then
                        hasvararg = true
                     end
                     argdef.luaname = string.format('select(%d, ...)', argidx)
                     if argdef.check and argdef:check() then
                        table.insert(checks, argdef:check())
                        if argdef.read then
                           if argdef:read() then
                              table.insert(reads, argdef:read())
                           end
                        else
                           table.insert(reads, string.format('%s = %s', argdef.name, argdef.luaname))
                        end
                     end
                  end
               end
               -- default reads
               if not isvalid and argdef.default then
                  if argdef.initdefault and argdef:initdefault() then
                     table.insert(reads, string.format('%s = %s', argdef.name, argdef:initdefault()))
                  else
                     error(string.format('do not know how to deal with default argument <%s>', argdef.name))
                  end
               end
            end
            if hasvararg then
               checks[1] = string.format('narg >= %d', argidx)
            else
               checks[1] = string.format('narg == %d', argidx)
            end
            table.insert(txt, string.format('if %s then ', table.concat(checks, ' and ')))
            if #reads > 0 then
               table.insert(txt, table.concat(reads, '\n'))
            end
            table.insert(txt, callfunc(funcname, vars, argdefs))
            table.insert(txt, 'end')
         end
      end
      table.insert(txt, 'end')
   end
   return table.concat(txt, '\n')
end

local function generateusage(argdefs)
   local txt
   if argdefs.help then
      txt = {argdefs.help, '', '> arguments:', '{'}
   else
      txt = {'> arguments:', argdefs.nonamed and '(' or '{'}
   end
   local size = 0
   for _,argdef in ipairs(argdefs) do
      size = math.max(size, #argdef.name)
   end
   local arg = {}
   local hlp = {}
   for _,argdef in ipairs(argdefs) do
      table.insert(arg,
                   ((argdef.named or argdef.default) and '[' or ' ')
                   .. argdef.name .. string.rep(' ', size-#argdef.name)
                   .. (argdef.type and (' = ' .. argdef.type) or '')
                .. ((argdef.named or argdef.default) and ']' or '')
             .. (argdef.named and '*' or ''))
      
      local default = ''
      if type(argdef.default) == 'nil' then
      elseif type(argdef.default) == 'string' then
         default = string.format(' [default=%s]', argdef.default)
      elseif type(argdef.default) == 'number' then
         default = string.format(' [default=%s]', argdef.default)
      elseif type(argdef.default) == 'boolean' then
         default = string.format(' [default=%s]', argdef.default and 'true' or 'false')
      else
         default = ' [has default value]'
      end
      table.insert(hlp, (argdef.help or '') .. default)
                
   end

   local size = 0
   for i=1,#arg do
      size = math.max(size, #arg[i])
   end

   for i=1,#arg do
      table.insert(txt, string.format("  %s %s -- %s", arg[i], string.rep(' ', size-#arg[i]), hlp[i]))
   end

   table.insert(txt, argdefs.nonamed and ')' or '}')
   return table.concat(txt, '\n')
end

function _G.argcheck(...)
   local narg = select('#', ...)
   local err
   local globalhelp
   local pairs
   if narg == 2 and type(select(1, ...)) == 'table' and type(select(2, ...)) == 'function' then
      pairs = {select(1, ...), select(2, ...)}
   elseif narg == 1 and type(select(1, ...)) == 'table' then
      local tbl = select(1, ...)
      globalhelp = tbl.help
      local npairs = #tbl/2
      local valid = (npairs == math.floor(npairs))
      if valid then
         for i=1,npairs do
            if type(tbl[(i-1)*2+1]) ~= 'table' or type(tbl[(i-1)*2+2]) ~= 'function' then
               valid = false
            end
         end
      end
      if valid then
         pairs = tbl
      end
   end
   if not pairs then
      error('expecting (table, function) | {table, function, table, function ... }')
   end

   -- note: generateargcheck checks if the argdefs are valid in all possible ways
   -- so we start by that
   local code = {'return function(...)', "local narg = select('#', ...)"}
   for i=1,#pairs/2 do
      table.insert(code, generateargcheck(pairs[(i-1)*2+1], 'func' .. i))
   end
   table.insert(code, "usage()")
   table.insert(code, "end")

   -- ok, now we generate the usage
   -- this one is going to be an upvalue for argcheck
   local usage = {'return function()', 'print[['}
   if globalhelp then
      table.insert(usage, globalhelp)
      table.insert(usage, '')
   end
   local hlp = {}
   for i=1,#pairs/2 do
      table.insert(hlp, generateusage(pairs[(i-1)*2+1]))
   end
   table.insert(usage, table.concat(hlp, '\n\nor\n\n'))
   table.insert(usage, ']]')
   table.insert(usage, 'error("invalid arguments")')
   table.insert(usage, 'end')
   usage = table.concat(usage, '\n')
--   print(usage)
   usage, err = loadstring(usage)
   if not usage then
      error(err)
   end
   usage = usage()

   -- setup the environment properly
   -- type and select must be fast, so we put them as direct upvalues
   local env = {type=type, select=select, usage=usage}
   setmetatable(env, {__index=_G})
   for i=1,#pairs/2 do
      env['func' .. i] = pairs[(i-1)*2+2]
   end
   code = table.concat(code, '\n')
--   print(code)
   code, err = loadstring(code)
   if not code then
      error(err)
   end
   setfenv(code, env)
   return code()
end
