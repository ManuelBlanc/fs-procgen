# FS Procedural Generator
**Requires LuaJIT.** A 2D procedural level generator engine.

LuaJIT is used because:
+ It allows calling library C functions without having to write Lua bindings.
+ Using structs instead of tables when the shape of the data is known allows for some 
+ Mersenne Twister relies on having bitwise operations available and benefits greatly from the JIT.


### References
+ CogMind https://www.gridsagegames.com/blog/2014/06/procedural-map-generation/
+ DungeonMaker http://dungeonmaker.sourceforge.net/DM2_Manual/
+ Brogue https://github.com/tsadok/brogue/blob/master/src/brogue/Architect.c
+ NecroDancer https://github.com/leonard-thieu/ndref/blob/master/src/level/level.monkey
+ Spelunky http://tinysubversions.com/spelunkyGen/
+ Anband https://github.com/angband/angband/blob/master/src/gen-cave.c
+ Bob Nystrom http://journal.stuffwithstuff.com/2014/12/21/rooms-and-mazes/
+ https://github.com/mreinstein/level-generator/blob/master/lib/roomie.js
+ https://github.com/Zakru/opencrypt/blob/master/modules/opencrypt/worldGenerator.lua
+ Wave Function https://github.com/mxgmn/WaveFunctionCollapse
+ ProcGen Wiki http://pcg.wikidot.com/pcg-algorithm:dungeon-generation
+ https://github.com/marukrap/RoguelikeDevResources

## License
MIT license. See [LICENSE](./LICENSE).
