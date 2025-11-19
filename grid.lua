local grid = {}

-- The possible directions of a triangle,
-- matched with the value of `h+f+b`.
grid.up = 3
grid.down = 4

local h_lo
local h_hi
local f_lo
local f_hi
local b_lo
local b_hi

local dirs = {
   h = 0,
   f = 1,
   b = 2
}

function grid.setup(scale)
   grid.scale = scale

   -- Tri-ordinate bounds:
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

function grid.get_b(h, f, type)
    return type - h - f
end

-- Check if a tri-ordinate `{ h, f, b }` is valid.
-- A triangle is uniquely determined by `(h, f, h+f+b % 2)`.
-- The determination works as follows:
-- - if dir is up, `b = h + f - 1`
-- - if dir is down, `b = h + fs`.
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

function grid.get_h_adjacent(h, f, b)
   -- +1 if dir == up, and -1 if dir == down
   local sign = (-1)^(grid.get_type(h, f, b)+1)
   return wrap(h+sign, f, b)
end

function grid.get_f_adjacent(h, f, b)
   -- +1 if dir == up, and -1 if dir == down
   local sign = (-1)^(grid.get_type(h, f, b)+1)
   return wrap(h, f+sign, b)
end

function grid.get_b_adjacent(h, f, b)
   -- +1 if dir == up, and -1 if dir == down
   local sign = (-1)^(grid.get_type(h, f, b)+1)
   return wrap(h, f, b+sign)
end

function grid.get_adjacent(h, f, b, dir)
   if dir == dirs.h then
      return grid.get_h_adjacent(h, f, b)
   elseif dir == dirs.f then
      return grid.get_f_adjacent(h, f, b)
   elseif dir == dirs.b then
      return grid.get_b_adjacent(h, f, b)
   end
end

function grid.get_left(triord, dir)
   return grid.get_adjacent(
      triord[1],
      triord[2],
      triord[3],
      (dir + 1) % 3
   )
end

function grid.get_right(triord, dir)
   return grid.get_adjacent(
      triord[1],
      triord[2],
      triord[3],
      (dir - 1) % 3
   )
end

function grid.get_behind(triord, dir)
   return grid.get_adjacent(
      triord[1],
      triord[2],
      triord[3],
      dir
   )
end

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