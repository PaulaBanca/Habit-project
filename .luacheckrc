local coronaAPI = {
  'audio',
  'display',
  'easing',
  'graphics',
  'lfs',
  'media',
  'native',
  'network',
  'Runtime',
  'system',
  'timer',
  'transition',
  'print',
  'require',
  'package'
 }


------------------------------
-- lua check config

max_line_length = false

stds.corona = {
   read_globals = coronaAPI   -- these globals can only be accessed.
}

std = "lua51+corona"