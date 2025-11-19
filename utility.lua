local utility = {}

function utility.triord_to_string(triord)
      return table.concat(triord, ",")
end

function utility.string_to_triord(triord_string)
   local _, _, h, f, b = string.find(triord_string, "(.+),(.+),(.+)")
   return { h, f, b }
end

return utility