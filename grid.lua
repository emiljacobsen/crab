local grid = {}

-- The possible orientations of a triangle,
-- matched with the value of `h+f+b`.

grid.up = 3 -- = h + f + b = 1 + 1 + 1
grid.down = 4 -- = h + f + b = (1 + 1) + 1 + 1

-- Triordinate bounds for the grid.

local h_lo
local h_hi
local f_lo
local f_hi
local b_lo
local b_hi

-- The three directions.
-- Ordered clockwise for an up-triangle,
-- counter-clockwise for a down-triangle.
grid.dirs = {
   h = 0,
   f = 1,
   b = 2
}

-- Must run first.
-- `scale` is the number of triangles along a side of the hexagon.
function grid.setup(scale)
   grid.scale = scale

   -- Set tri-ordinate bounds:

   h_lo = 1
   h_hi = 2 * scale
   f_lo = -2 * scale + 2
   f_hi = 1
   b_lo = -scale + 2
   b_hi = scale + 1
end

-- Get the type of a triangle (pointing up or down)
-- (equal to either of `grid.up` or `grid.down`).
function grid.get_type(h, f, b)
   return h + f + b
end

-- Returns -1 for a triangle pointing up and +1 otherwise
function grid.get_sign(h, f, b)
   return (-1)^(grid.get_type(h, f, b))
end

-- Compute the b tri-ordinate of a triangle
-- from its `h`, `f`, and orientation (`type`).
function grid.get_b(h, f, type)
    return type - h - f
end

-- Check if a tri-ordinate `h, f, b` is valid.
-- A triangle is uniquely determined by `(h, f, h+f+b)`.
-- TODO: consider not exporting this.
function grid.check_valid(h, f, b)
   return grid.get_type(h, f, b) == grid.up
      or grid.get_type(h, f, b) == grid.down
   -- return b == get_b(h, f, get_type(h, f, b))
end

-- Uses the wrapping/warping logic to shift a tri-ordinate into the grid.
-- Returns an array { h', f', b' }.
-- Assumes (for now) at most one tri-ordinate is OOB, and by at most 1.
local function wrap(h, f, b)
   if h == h_lo - 1 then
      return { h_hi, f - grid.scale, b - grid.scale }
   elseif h == h_hi + 1 then
      return { h_lo, f + grid.scale, b + grid.scale }
   elseif f == f_lo - 1 then
      return { h - grid.scale, f_hi, b - grid.scale }
   elseif f == f_hi + 1 then
      return { h + grid.scale, f_lo, b + grid.scale }
   elseif b == b_lo - 1 then
      return { h - grid.scale, f - grid.scale, b_hi }
   elseif b == b_hi + 1 then
      return { h + grid.scale, f + grid.scale, b_lo }
   else
      return { h, f, b }
   end
end

-- Get the adjacent tri-ordinates (including adjacent by warping)
-- Returns an array of arrays
-- { {h1, f1, b1}, ... }
function grid.get_adjacents(h, f, b)
   local adjacents = {
      grid.get_h_adjacent(h, f, b),
      grid.get_f_adjacent(h, f, b),
      grid.get_b_adjacent(h, f, b)
   }
   return adjacents
end

-- Return the adjacent triangle along an h line.
-- Returns an array { h', f', b' }.
function grid.get_h_adjacent(h, f, b)
   -- +1 if dir == up, and -1 if dir == down
   local sign = (-1)^(grid.get_type(h, f, b)+1)
   return wrap(h+sign, f, b)
end

-- Return the adjacent triangle along an f line.
-- Returns an array { h', f', b' }.
function grid.get_f_adjacent(h, f, b)
   -- +1 if dir == up, and -1 if dir == down
   local sign = (-1)^(grid.get_type(h, f, b)+1)
   return wrap(h, f+sign, b)
end

-- Return the adjacent triangle along an b line.
-- Returns an array { h', f', b' }.
function grid.get_b_adjacent(h, f, b)
   -- +1 if dir == up, and -1 if dir == down
   local sign = (-1)^(grid.get_type(h, f, b)+1)
   return wrap(h, f, b+sign)
end

-- Return the adjacent triangle along a dir line.
-- Returns an array { h', f', b' }.
function grid.get_adjacent(h, f, b, dir)
   if dir == grid.dirs.h then
      return grid.get_h_adjacent(h, f, b)
   elseif dir == grid.dirs.f then
      return grid.get_f_adjacent(h, f, b)
   elseif dir == grid.dirs.b then
      return grid.get_b_adjacent(h, f, b)
   end
end

-- Get the adjacent triangle which is left for
-- someone standing at `triord` with the `dir` line behind them.
-- Returns a triordinate array.
function grid.get_left(triord, dir)
   return grid.get_adjacent(
      triord[1],
      triord[2],
      triord[3],
      (dir + 1) % 3
   )
end

-- Get the adjacent triangle which is right for
-- someone standing at `triord` with the `dir` line behind them.
-- Returns a triordinate array.
function grid.get_right(triord, dir)
   return grid.get_adjacent(
      triord[1],
      triord[2],
      triord[3],
      (dir - 1) % 3
   )
end

-- Get the adjacent triangle which is across the `dir` line.
-- This is the same, as grid.get_adjacent, but with args differently formatted.
-- Returns a triordinate array.
function grid.get_behind(triord, dir)
   return grid.get_adjacent(
      triord[1],
      triord[2],
      triord[3],
      dir
   )
end

-- Get the hexagon one spinns through when standing at
-- triord with the dir line behind ones back,
-- and rotating around the vertex ahead.
-- Returns an array of six arrays
-- { { h1, f1, b1 }, ..., { h6, f6, b6 } }.
function grid.get_hexagon(triord, dir)
   local triords = {}
   local last_dir = dir
   triords[1] = triord
   for i = 2, 6 do
      triords[i] = grid.get_right(triords[i-1], last_dir)
      last_dir = (last_dir + 1) % 3
   end
   return triords
end

-- Get the triordinates of all the triangles in the grid.
-- Returns an array
-- { { h1, f1, b1 }, ... }.
function grid.get_all_triangles()

   -- TODO: do sanity check that all triords are valid

   local triords = {}

   -- Upper half of the hexagon

   local f_bnd = f_lo + grid.scale
   for h = 1, grid.scale do
      for f = f_bnd, f_hi do
         triords[#triords+1] = { h, f, grid.get_b(h, f, grid.up) }
         triords[#triords+1] = { h, f, grid.get_b(h, f, grid.down) }
      end
      f_bnd = f_bnd - 1
      triords[#triords+1] = { h, f_bnd, grid.get_b(h, f_bnd, grid.up) }
   end

   -- Sanity check
   -- print("upper half f_bnd check in arena.get_all_triangles:", f_bnd == f_lo)

   -- Lower half of the hexagon

   f_bnd = f_hi
   for h = grid.scale+1, 2 * grid.scale do
      triords[#triords+1] = { h, f_bnd, grid.get_b(h, f_bnd, grid.down) }
      f_bnd = f_bnd - 1

      for f = f_lo, f_bnd do
         triords[#triords+1] = { h, f, grid.get_b(h, f, grid.up) }
         triords[#triords+1] = { h, f, grid.get_b(h, f, grid.down) }
      end
   end

   -- Sanity check
   -- print(
   --    "lower half f_bnd check in arena.get_all_triangles:",
   --    f_bnd == f_lo + arena.scale - 1
   -- )

   return triords
end

return grid