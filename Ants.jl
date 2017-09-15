using Gtk.ShortNames, Graphics
using StaticArrays
using ProfileView
using BenchmarkTools

include("AntsFunctions.jl")
include("AntsGUI.jl")

function simulate(WIDTH, HEIGHT, nbAnts, VALUE_MAX, MIN_PHERO, MAX_PHERO, HOME_DECAY, FOOD_DECAY, DIFFUSION, N ; plot=true)

	BASELOC = (5, 5)
	RESSOURCELOC = (HEIGHT-5, WIDTH-5)

	const grid = [0 for i = 1:WIDTH, j = 1:HEIGHT]  ; grid[BASELOC...] = -2 ; grid[RESSOURCELOC...] = VALUE_MAX
	const home_pheromones = [MIN_PHERO for i = 1:HEIGHT, j = 1:WIDTH]
	const food_pheromones = [MIN_PHERO for i = 1:HEIGHT, j = 1:WIDTH]
	const ants = [Ant() for i = 1:nbAnts];

	AD = AntData(grid, home_pheromones, food_pheromones, MIN_PHERO, MAX_PHERO, N, false, 1)
	plot && (c = setGUI(grid, ants, home_pheromones, food_pheromones, MIN_PHERO, MAX_PHERO, VALUE_MAX, AD))
		
	iter = 0
	while maximum(grid) > 0
	
		while AD.is_paused
			sleep(0.1)
		end
	
		iter += 1
		
		#EVAPORATION
		map!(x -> max(MIN_PHERO, x*HOME_DECAY), home_pheromones, home_pheromones)
		map!(x -> max(MIN_PHERO, x*FOOD_DECAY), food_pheromones, food_pheromones)
		
		
		#DIFFUSION
		if rand(Bool)
			for i = 2:HEIGHT
				home_pheromones[i, :] .+= DIFFUSION * home_pheromones[i-1, :]
				food_pheromones[i, :] .+= DIFFUSION * food_pheromones[i-1, :]
			end
			for i = 2:WIDTH
				home_pheromones[:, i] .+= DIFFUSION * home_pheromones[:, i-1]
				food_pheromones[:, i] .+= DIFFUSION * food_pheromones[:, i-1]
			end
		else
			for i = 1:HEIGHT-1
				home_pheromones[i, :] .+= DIFFUSION * home_pheromones[i+1, :]
				food_pheromones[i, :] .+= DIFFUSION * food_pheromones[i+1, :]
			end
			for i = 1:WIDTH-1
				home_pheromones[:, i] .+= DIFFUSION * home_pheromones[:, i+1]
				food_pheromones[:, i] .+= DIFFUSION * food_pheromones[:, i+1]
			end
		end
		
		
		#respawn an ant at base
		if iter % 100 == 0
			ant = rand(ants)
			ant.x, ant.y = BASELOC
			ant.loaded = false
			drop_home_pheromones(ant, AD)
		end
		
		#FORAGING
		for ant in ants
			forage(ant, AD)
		end
		
		#PLOTTING
		plot && iter % AD.skip_frames == 0 && draw(c)
		plot && iter % AD.skip_frames == 0 && (any(x -> x.loaded, ants) ? sleep(0.00001) : sleep(0.00001))
	end
	return iter

end

@time simulate(100, 100, 100, 5000, 0.1, 10000.0, 0.9975, 0.9975, 0.0008, 2, plot = true )


# for blue_decay in [0.9985, 0.999, 0.9995], red_decay in [0.9985, 0.999, 0.9995], diffusion in [0.0001, 0.0003, 0.0005]
	# @show blue_decay, red_decay, diffusion
	# @btime simulate(100, 100, 200, 1000, 0.001, 1000.0, $blue_decay, $red_decay, $diffusion, 10, plot = false)
# end