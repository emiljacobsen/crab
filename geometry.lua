local geometry = {}

-- Returns the norm of `vector`.
-- `vector` is an array {x, y}
function geometry.norm(vector)
   return math.sqrt(vector[1]^2 + vector[2]^2)
end

-- Returns the length of `line`
-- `line` is an array {x1, y1, x2, y2}
function geometry.length(line)
   return geometry.norm({ line[3] - line[1], line[4] - line[2] })
end

-- Returns the left normal of `vector`
-- (!) Caution (!) The coordinate system is left handed
function geometry.left_normal(vector)
   return { vector[2], -vector[1] }
end

-- Checks if all points in `pts` are
-- to the left of (or on) the `line`.
-- - `pts` is an array {x1, y1, x2, y2, ...}
-- - `line` is an array {x1, y1, x2, y2}
function geometry.is_left_of(pts, line)

   if #pts % 2 == 1 then
      error("Incorrectly formatted `pts` in `is_left_of`: odd number")
   end

   -- The number of points
   local num_pts = math.floor(#pts / 2)

   -- The left normal of the line, as a vector based at the origin
   local n = geometry.left_normal({ line[3] - line[1], line[4] - line[2] })

   -- The translated points (to base everything at the origin)
   local pts_tr = {}
   for i = 1, num_pts do
      pts_tr[2*i-1] = pts[2*i-1] - line[1]
      pts_tr[2*i] = pts[2*i] - line[2]
   end

   -- Loop through the points

   for i = 1, num_pts do
      -- A vertex is to the left if its angle to
      -- the left normal is at most 90 degrees.
      local v = { pts_tr[2*i-1], pts_tr[2*i] }
      local dotprod = n[1] * v[1] + n[2] * v[2]
      local angle =
         math.abs(math.acos(dotprod / (geometry.norm(n) * geometry.norm(v))))

      if math.floor(math.deg(angle)) > 90 then
         return false
      end
   end

   -- If we get here, no vertex was to the right
   return true
end

-- Checks if all vertices of `pts` are
-- to the right of (or on) the `line`.
-- - `pts` is an array {x1, y1, x2, y2, ...}
-- - `line` is an array {x1, y1, x2, y2}
function geometry.is_right_of(pts, line)
   -- Simply reverse the line and check if left of
   return geometry.is_left_of(
      pts,
      { line[3], line[4], line[1], line[2] }
   )
end

-- Returns the average of all the points in `pts`
-- `pts` is an array { x1, y1, x2, y2, ... }
-- Returns an array { x, y }
function geometry.centre(pts)
   if #pts % 2 == 1 then
      error("Odd number of coordinates in geometry.centre")
   end

   local n = math.floor(#pts / 2)
   local x = 0
   local y = 0

   for j = 1, n do
      x = x + pts[2*j-1]
      y = y + pts[2*j]
   end

   x = x / n
   y = y / n

   return { x, y }
end

-- Scale a vector `vec` by a number `param`
-- Returns { x, y }
function geometry.scale(vec, param)
   return { vec[1] * param, vec[2] * param }
end

-- Translate points `pts` by a vector `vec`.
-- Returns { x1', y1', x2', y2', ... }
function geometry.translate(pts, vec)
   if #pts % 2 == 1 then
      error("Error: odd number of pts coordinates in geometry.translate")
   end
   if #vec ~= 2 then
      error("Error: vec has wrong length in geometry.translate")
   end

   local n = math.floor(#pts / 2)
   local new = {}

   for j = 1, n do
      new[2*j-1] = pts[2*j-1] + vec[1]
      new[2*j] = pts[2*j] + vec[2]
   end

   return new
end

function geometry.line_to_vec(x1, y1, x2, y2)
   return { x2 - x1, y2 - y1 }
end

return geometry