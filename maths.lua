local ffi = require 'ffi'
local argcheck = require 'argcheck'
local torch = require 'torch.env'
local class = require 'class'
local C = require 'torch.TH'
local register_ = require 'torch.register'

torch.__generator = torch._generator or C.THGenerator_new()

local function register(args)
   if args.nomethod and not args.nofunction then
      return register_(args, torch, nil)
   elseif args.nofunction and not args.nomethod then
      return register_(args, nil, class.metatable('torch.RealTensor'))
   else
      return register_(args, torch, class.metatable('torch.RealTensor'))
   end
end

-- numbers: we could emulate it in register() (right now it is done by hand)

local function defaulttensortype()
   return class.type(torch.Tensor)
end

register{
   name = "fill",
   {name="dst", type="torch.RealTensor"},
   {name="value", type="number"},
   call =
      function(dst, value)
         C.THRealTensor_fill(dst, value)
         return dst
      end
}

register{
   name = "zero",
   {name="dst", type="torch.RealTensor"},
   call =
      function(dst)
         C.THRealTensor_zero(dst)
         return dst
      end
}

register{
   name = "dot",
   {name="src1", type="torch.RealTensor"},
   {name="src2", type="torch.RealTensor"},
   call =
      function(src1, src2)
         return tonumber(C.THRealTensor_dot(src1, src2))
      end
}

register{
   name = "min",
   {name="src", type="torch.RealTensor"},
   call =
      function(src)
         return tonumber(C.THRealTensor_minall(src))
      end
}

register{
   name = "min",
   {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
   {name="idx", type="torch.LongTensor", opt=true},
   {name="src", type="torch.RealTensor", method={opt=true}},
   {name="dim", type="number"},
   call =
      function(dst, idx, src, dim)
         local res = src and dst or torch.RealTensor()
         src = src or dst
         idx = idx or torch.LongTensor()
         C.THRealTensor_min(res, idx, src, dim-1)
         idx:add(1)
         return res, idx
      end
}

register{
   name = "max",
   {name="src", type="torch.RealTensor"},
   call =
      function(src)
         return tonumber(C.THRealTensor_maxall(src))
      end
}

register{
   name = "max",
   {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
   {name="idx", type="torch.LongRealTensor", opt=true},
   {name="src", type="torch.RealTensor", method={opt=true}},
   {name="dim", type="number"},
   call =
      function(dst, idx, src, dim)
         local res = src and dst or torch.RealTensor()
         src = src or dst
         idx = idx or torch.LongTensor()
         C.THRealTensor_max(res, idx, src, dim-1)
         idx:add(1)
         return res, idx
      end
}

register{
   name = "sum",
   {name="src", type="torch.RealTensor"},
   call =
      function(src)
         return tonumber(C.THRealTensor_sumall(src))
      end
}

register{
   name = "sum",
   {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
   {name="src", type="torch.RealTensor", method={opt=true}},
   {name="dim", type="number"},
   call =
      function(dst, src, dim)
         local res = src and dst or torch.RealTensor()
         src = src or dst
         C.THRealTensor_max(res, src, dim-1)
         return res
      end
}

-- NYI
-- register{
--    name = "prod",
--    {name="src", type="torch.RealTensor"},
--    call =
-- }

register{
   name = "prod",
   {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
   {name="src", type="torch.RealTensor", method={opt=true}},
   {name="dim", type="number"},
   call =
      function(dst, src, dim)
         local res = src and dst or torch.RealTensor()
         src = src or dst
         C.THRealTensor_prod(res, src, dim-1)
         return res
      end
}

register{
   name = "cumsum",
   {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
   {name="src", type="torch.RealTensor", method={opt=true}},
   {name="dim", type="number"},
   call =
      function(dst, src, dim)
         local res = src and dst or torch.RealTensor()
         src = src or dst
         C.THRealTensor_cumsum(res, src, dim-1)
         return res
      end
}

register{
   name = "cumprod",
   {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
   {name="src", type="torch.RealTensor", method={opt=true}},
   {name="dim", type="number"},
   call =
      function(dst, src, dim)
         local res = src and dst or torch.RealTensor()
         src = src or dst
         C.THRealTensor_cumprod(res, src, dim-1)
         return res
      end
}

register{
   name = "add",
   {name="dst", type="torch.RealTensor", opt=true,  method={opt=false}},
   {name="src", type="torch.RealTensor", method={defaulta="self"}},
   {name="value", type="number"},
   call =
      function(dst, src, value)
         local res = src and dst or torch.RealTensor()
         src = src or dst
         res:resizeAs(src)
         C.THRealTensor_add(res, src, value)
         return res
      end
}

register{
   name = "add",
   {name="dst", type="torch.RealTensor", opt=true,   method={opt=false}},
   {name="src1", type="torch.RealTensor", opt=false, method={defaulta="self"}},
   {name="value", type="number", default=1},
   {name="src2", type="torch.RealTensor"},
   call =
      function(dst, src1, value, src2)
         local res = src1 and dst or torch.RealTensor()
         src1 = src1 or dst
         res:resizeAs(src1)
         C.THRealTensor_cadd(dst, src1, value, src2)
         return res
      end
}

register{
   name = "mul",
   {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
   {name="src", type="torch.RealTensor", method={defaulta="self"}},
   {name="value", type="number"},
   call =
      function(dst, src, value)
         local res = src and dst or torch.RealTensor()
         src = src or dst
         res:resizeAs(src)
         C.THRealTensor_mul(res, src, value)
         return res
      end
}

register{
   name = "cmul",
   {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
   {name="src1", type="torch.RealTensor", method={defaulta="self"}},
   {name="src2", type="torch.RealTensor"},
   call =
      function(dst, src1, src2)
         local res = src1 and dst or torch.RealTensor()
         src1 = src1 or dst
         res:resizeAs(src1)
         C.THRealTensor_cmul(dst, src1, src2)
         return res
      end
}


register{
   name = "div",
   {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
   {name="src", type="torch.RealTensor", method={defaulta="self"}},
   {name="value", type="number"},
   call =
      function(dst, src, value)
         local res = src and dst or torch.RealTensor()
         src = src or dst
         res:resizeAs(src)
         C.THRealTensor_div(res, src, value)
         return res
      end
}

register{
   name = "cdiv",
   {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
   {name="src1", type="torch.RealTensor", method={defaulta="self"}},
   {name="src2", type="torch.RealTensor"},
   call =
      function(dst, src1, src2)
         local res = src1 and dst or torch.RealTensor()
         src1 = src1 or dst
         res:resizeAs(src1)
         C.THRealTensor_cdiv(dst, src1, src2)
         return res
      end
}

register{
   name = "addcmul",
   {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
   {name="src", type="torch.RealTensor", method={defaulta="self"}},
   {name="value", type="number", default=1},
   {name="src1", type="torch.RealTensor"},
   {name="src2", type="torch.RealTensor"},
   call =
      function(dst, src, value, src1, src2)
         local res = src and dst or torch.RealTensor()
         src = src or dst
         C.THRealTensor_addcmul(res, src, value, src1, src2)
         return res
      end
}

register{
   name = "addcdiv",
   {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
   {name="src", type="torch.RealTensor", method={defaulta="self"}},
   {name="value", type="number", default=1},
   {name="src1", type="torch.RealTensor"},
   {name="src2", type="torch.RealTensor"},
   call =
      function(dst, src, value, src1, src2)
         local res = src and dst or torch.RealTensor()
         src = src or dst
         C.THRealTensor_addcdiv(res, src, value, src1, src2)
         return res
      end
}

register{
   name = "trace",
   {name="src", type="torch.RealTensor"},
   call =
      function(src)
         return tonumber(C.THRealTensor_trace(src))
      end
}

register{
   name = "diag",
   {name="dst", type='torch.RealTensor', opt=true, method={opt=false}},
   {name="src", type='torch.RealTensor', method={opt=true}},
   {name="k", type='number', default=0},
   call =
      function(dst, src, k)
         local res = src and dst or torch.RealTensor()
         src = src or dst
         C.THRealTensor_diag(dst, src, k)
         return res
      end
}

register{
   name = "addmv",
   {name="dst", type='torch.RealTensor', opt=true, method={opt=false}},
   {name="src", type='torch.RealTensor', method={defaulta="self"}},
   {name="alpha", type='number', default=1},
   {name="mat", type='torch.RealTensor'}, -- could check dim
   {name="vec", type='torch.RealTensor'},
   call =
      function(dst, src, alpha, mat, vec)
         local res = src and dst or torch.RealTensor()
         src = src or self
         C.THRealTensor_addmv(res, 1, src, alpha, mat, vec)
         return res
      end
}

register{
   name = "addmv",
   {name="dst", type='torch.RealTensor', opt=true, method={opt=false}},
   {name="beta", type='number'},
   {name="src", type='torch.RealTensor', method={defaulta="self"}},
   {name="alpha", type='number'},
   {name="mat", type='torch.RealTensor'}, -- could check dim
   {name="vec", type='torch.RealTensor'},
   call =
      function(dst, beta, src, alpha, mat, vec)
         local res = src and dst or torch.RealTensor()
         src = src or self
         C.THRealTensor_addmv(res, beta, src, alpha, mat, vec)
         return res
      end
}

-- copy
register{
   name = "copy",
   {name="dst", type='torch.RealTensor'},
   {name="src", type='torch.RealTensor'},
   call =
      function(dst, src)
         C.THRealTensor_copy(dst, src)
         return dst
      end
}

register{
   name = "copy",
   {name="dst", type='torch.RealTensor'},
   {name="src", type='torch.ByteTensor'},
   call =
      function(dst, src)
         C.THRealTensor_copyByte(dst, src)
         return dst
      end
}

register{
   name = "copy",
   {name="dst", type='torch.RealTensor'},
   {name="src", type='torch.CharTensor'},
   call =
      function(dst, src)
         C.THRealTensor_copyChar(dst, src)
         return dst
      end
}

register{
   name = "copy",
   {name="dst", type='torch.RealTensor'},
   {name="src", type='torch.ShortTensor'},
   call =
      function(dst, src)
         C.THRealTensor_copyShort(dst, src)
         return dst
      end
}

register{
   name = "copy",
   {name="dst", type='torch.RealTensor'},
   {name="src", type='torch.IntTensor'},
   call =
      function(dst, src)
         C.THRealTensor_copyInt(dst, src)
         return dst
      end
}

register{
   name = "copy",
   {name="dst", type='torch.RealTensor'},
   {name="src", type='torch.LongTensor'},
   call =
      function(dst, src)
         C.THRealTensor_copyLong(dst, src)
         return dst
      end
}

register{
   name = "copy",
   {name="dst", type='torch.RealTensor'},
   {name="src", type='torch.FloatTensor'},
   call =
      function(dst, src)
         C.THRealTensor_copyFloat(dst, src)
         return dst
      end
}

register{
   name = "copy",
   {name="dst", type='torch.RealTensor'},
   {name="src", type='torch.DoubleTensor'},
   call =
      function(dst, src)
         C.THRealTensor_copyDouble(dst, src)
         return dst
      end
}

-- creation
register{
   name = "zeros",
   {name="dst", type='torch.RealTensor', opt=true, method={opt=false}},
   {name="size", type="table"},
   {name="typename", type="string", defaultf=defaulttensortype}, -- namedispatch
   call =
      function(dst, size, typename)
         if dst then
            size = torch.LongStorage(size)
            C.THRealTensor_resize(dst, size, nil)
            C.THRealTensor_zero(dst)
         else
            dst = class.metatable(typename).new()
            dst:zeros(size)
         end
         return dst
      end
}

register{
   name = "zeros",
   {name="dst", type='torch.RealTensor', opt=true, method={opt=false}},
   {name="dim1", type="number"},
   {name="dim2", type="number", default=0},
   {name="dim3", type="number", default=0},
   {name="dim4", type="number", default=0},
   {name="typename", type="string", defaultf=defaulttensortype}, -- namedispatch
   call =
      function(dst, dim1, dim2, dim3, dim4, typename)
         if dst then
            C.THRealTensor_resize4d(dst, dim1, dim2, dim3, dim4)
            C.THRealTensor_zero(dst)
         else
            dst = class.metatable(typename).new()
            dst:zeros(dim1, dim2, dim3, dim4)
         end
         return dst
      end
}

register{
   name = "ones",
   {name="dst", type='torch.RealTensor', opt=true, method={opt=false}},
   {name="size", type="table"},
   {name="typename", type="string", defaultf=defaulttensortype}, -- namedispatch
   call =
      function(dst, size, typename)
         if dst then
            size = torch.LongStorage(size)
            C.THRealTensor_resize(dst, size, nil)
            C.THRealTensor_fill(dst, 1)
         else
            dst = class.metatable(typename).new()
            dst:ones(size)
         end
         return dst
      end
}

register{
   name = "ones",
   {name="dst", type='torch.RealTensor', opt=true, method={opt=false}},
   {name="dim1", type="number"},
   {name="dim2", type="number", default=0},
   {name="dim3", type="number", default=0},
   {name="dim4", type="number", default=0},
   {name="typename", type="string", defaultf=defaulttensortype}, -- namedispatch
   call =
      function(dst, dim1, dim2, dim3, dim4, typename)
         if dst then
            C.THRealTensor_resize4d(dst, dim1, dim2, dim3, dim4)
            C.THRealTensor_fill(dst, 1)
         else
            dst = class.metatable(typename).new()
            dst:ones(dim1, dim2, dim3, dim4)
         end
         return dst
      end
}

register{
   name = "rand",
   {name="dst", type='torch.RealTensor', opt=true, method={opt=false}},
   {name="size", type="table"},
   {name="typename", type="string", defaultf=defaulttensortype}, -- namedispatch
   call =
      function(dst, size, typename)
         if dst then
            size = torch.LongStorage(size)
            C.THRealTensor_resize(dst, size, nil)
            C.THRealTensor_uniform(dst, torch.__generator, 0, 1)
         else
            dst = class.metatable(typename).new()
            dst:rand(size)
         end
         return dst
      end
}

register{
   name = "rand",
   {name="dst", type='torch.RealTensor', opt=true, method={opt=false}},
   {name="dim1", type="number"},
   {name="dim2", type="number", default=0},
   {name="dim3", type="number", default=0},
   {name="dim4", type="number", default=0},
   {name="typename", type="string", defaultf=defaulttensortype}, -- namedispatch
   call =
      function(dst, dim1, dim2, dim3, dim4, typename)
         if dst then
            C.THRealTensor_resize4d(dst, dim1, dim2, dim3, dim4)
            C.THRealTensor_uniform(dst, torch.__generator, 0, 1)
         else
            dst = class.metatable(typename).new()
            dst:rand(dim1, dim2, dim3, dim4)
         end
         return dst
      end
}

register{
   name = "randn",
   {name="dst", type='torch.RealTensor', opt=true, method={opt=false}},
   {name="size", type="table"},
   {name="typename", type="string", defaultf=defaulttensortype}, -- namedispatch
   call =
      function(dst, size, typename)
         if dst then
            size = torch.LongStorage(size)
            C.THRealTensor_resize(dst, size, nil)
            C.THRealTensor_normal(dst, torch.__generator, 0, 1)
         else
            dst = class.metatable(typename).new()
            dst:randn(size)
         end
         return dst
      end
}

register{
   name = "randn",
   {name="dst", type='torch.RealTensor', opt=true, method={opt=false}},
   {name="dim1", type="number"},
   {name="dim2", type="number", default=0},
   {name="dim3", type="number", default=0},
   {name="dim4", type="number", default=0},
   {name="typename", type="string", defaultf=defaulttensortype}, -- namedispatch
   call =
      function(dst, dim1, dim2, dim3, dim4, typename)
         if dst then
            C.THRealTensor_resize4d(dst, dim1, dim2, dim3, dim4)
            C.THRealTensor_normal(dst, torch.__generator, 0, 1)
         else
            dst = class.metatable(typename).new()
            dst:randn(dim1, dim2, dim3, dim4)
         end
         return dst
      end
}

-- float only
if "real" == "double" or "real" == "float" then

   register{
      name = "mean",
      {name="src", type="torch.RealTensor"},
      call = C.THRealTensor_meanall
   }

   register{
      name = "mean",
      {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},  -- could be torch.DoubleRealTensor for other types
      {name="src", type="torch.RealTensor", method={opt=true}},
      {name="dim", type="number"},
      call =
         function(dst, src, dim)
            local res = src and dst or torch.RealTensor()
            src = src or dst
            C.THRealTensor_mean(dst, src, n, dim-1)
            return res
         end
   }

   register{
      name = "std",
      {name="src", type="torch.RealTensor"},
      {name="flag", type="boolean", default=false}, -- NYI
      call =
         function(src, flag)
            return C.THRealTensor_stdall(src)
         end
   }
   
   register{
      name = "std",
      {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
      {name="src", type="torch.RealTensor", method={opt=true}},
      {name="dim", type="number"},
      {name="flag", type="boolean", default=false},
      call =
         function(dst, src, dim, flag)
            local res = src and dst or torch.RealTensor()
            src = src or dst
            C.THRealTensor_std(dst, src, dim-1, flag and 1 or 0)
            return res
         end
   }

   register{
      name = "var",
      {name="src", type="torch.RealTensor"},
      {name="flag", type="boolean", default=false},
      call =
         function(src, flag)
            return C.THRealTensor_varall(src) -- NYI
         end
   }

   register{
      name = "var",
      {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
      {name="src", type="torch.RealTensor", method={opt=true}},
      {name="dim", type="number"},
      {name="flag", type="boolean", default=false},
      call =
         function(dst, src, dim, flag)
            local res = src and dst or torch.RealTensor()
            src = src or dst
            C.THRealTensor_var(dst, src, dim-1, flag and 1 or 0)
            return res
         end
   }

   register{
      name = "norm",
      {name="src", type="torch.RealTensor"},
      {name="n", type="number", default=2},
      call = C.THRealTensor_normall
   }

   register{
      name = "norm",
      {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
      {name="src", type="torch.RealTensor", method={opt=true}},
      {name="n", type="number", default=2},
      {name="dim", type="number"},
      call =
         function(dst, src, n, dim)
            local res = src and dst or torch.RealTensor()
            src = src or dst
            C.THRealTensor_norm(dst, src, n, dim-1)
            return res
         end
   }

   for _,name in ipairs{'log', 'log1p', 'exp', 'cos', 'acos', 'cosh', 'sin', 'asin',
                        'sinh', 'tan', 'atan', 'tanh', 'sqrt', 'ceil', 'floor', 'abs'} do

      local func = C['THRealTensor_' .. name]
      register{
         name = name,
         {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
         {name="src", type="torch.RealTensor", method={defaulta="self"}},
         call =
            function(dst, src)
               local res = src and dst or torch.RealTensor()
               src = src or dst
               func(res, src)
               return res
            end
      }
   end

   register{
      name = "pow",
      {name="dst", type="torch.RealTensor", opt=true, method={opt=false}},
      {name="src", type="torch.RealTensor", method={defaulta="self"}},
      {name="value", type="number"},
      call =
         function(dst, src, value)
            local res = src and dst or torch.RealTensor()
            src = src or dst
            C.THRealTensor_pow(res, src)
            return res
         end
   }

end
