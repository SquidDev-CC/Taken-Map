return {
	map = {
		--- Bottom of the map: the floor the player stands on
		bottom = 64,
		--- 1 below the ceiling of the map
		top = 71,
		ceiling = 7,
		--- Width of the map
		width = 24,
		--- Height of the map
		height = 24,
	},
	--- Debug fill commands
	debugFill = false,
	--- Distance to offset player position checks:
	-- This prevents walking diagnoally (see @HDeffo)
	checkOffset = 0.05,
	--- Display debug particles
	debugParticles = false
}
