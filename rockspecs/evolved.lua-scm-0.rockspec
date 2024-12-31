package = "evolved.lua"
version = "scm-0"
source = {
   url = "git://github.com/BlackMATov/evolved.lua",
}
description = {
   homepage = "https://github.com/BlackMATov/evolved.lua",
   summary = "Evolved Entity-Component-System for Lua",
   license = "MIT",
}
dependencies = {
   "lua >= 5.1",
}
build = {
   type = "builtin",
   modules = {
      evolved = "evolved.lua",
   }
}
