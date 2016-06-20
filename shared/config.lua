return {
	map = {
		-- Height of the world
		ceiling = 7,
		--- Width of the map
		width = 24,
		--- Height of the map
		height = 24,

		spawnOffset = { 2, -3 },
		buildOffset = { 7, -3 },
	},
	--- Debug fill commands
	debugFill = false,
	--- Distance to offset player position checks:
	-- This prevents walking diagnoally (see @HDeffo)
	checkOffset = 0.05,
	--- Display debug particles
	debugParticles = false,

}
