-- links-filter.lua
function Link(el)
  found, _, a, b = string.find(el.target, "^(%w+)%.scad#(.*)$")
  if found then
    el.target = string.format("#%sscadmd__%s", string.lower(a), string.lower(b))
    return el
  end

  found, _, a = string.find(el.target, "^(%w+)%.scad$")
  if found then
    el.target = string.format("#%sscadmd", string.lower(a))
    return el
  end

  found, _, a, b = string.find(el.target, "^Tutorial-(%w+)%#(.*)$")
  if found then
    el.target = string.format("#tutorial-%smd__%s", string.lower(a), string.lower(b))
    return el
  end

  found, _, a = string.find(el.target, "^Tutorial-(%w+)$")
  if found then
    el.target = string.format("#tutorial-%smd", string.lower(a))
    return el
  end

  found, _, a, b = string.find(el.target, "^(%w+)%.md#(.*)$")
  if found then
    el.target = string.format("#%smd__%s", string.lower(a), string.lower(b))
    return el
  end

  found, _, a = string.find(el.target, "^(%w+)%.md$")
  if found then
    el.target = string.format("#%smd", string.lower(a))
    return el
  end

  found, _, a, b = string.find(el.target, "^(%w+)#(.*)$")
  if found then
    el.target = string.format("#%smd__%s", string.lower(a), string.lower(b))
    return el
  end

  found, _, a = string.find(el.target, "^(%w+)$")
  if found then
    el.target = string.format("#%smd", string.lower(a))
    return el
  end

  return el
end

