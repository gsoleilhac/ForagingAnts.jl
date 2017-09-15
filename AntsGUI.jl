function setGUI(grid, ants, home_pheromones, food_pheromones, MIN_PHERO, MAX_PHERO, VALUE_MAX, AD)
	
	
	HEIGHT = size(grid, 1)
	WIDTH = size(grid,2)
	
	
	b = Box(:h) ; setproperty!(b, :halign, 0)
	bb = Box(:v) ; setproperty!(bb, :width_request, 100) ; setproperty!(bb, :expand, false)
	btn = Button("Pause") ; setproperty!(btn, :halign, 3)
	slider =	Scale(false, 1:50)
	w = Window("Ants")
	f = AspectFrame("ants", 1., 1.); setproperty!(f, :expand, true)
	setproperty!(f, :yalign, 0.)
	setproperty!(f, :xalign, 0.)

	push!(bb, btn) ; push!(bb, slider)
	push!(b, f) ; push!(b, bb)
	push!(w, b)
	c = Canvas()
	push!(f, c)
	showall(w)
	

	
	pause_button_cliked(widget, AD) = begin
		AD.is_paused = 1-AD.is_paused
		if AD.is_paused
			setproperty!(widget, :label, "Play")
		else
			setproperty!(widget, :label, "Pause")
		end
		
	end
	id = signal_connect((widget) -> pause_button_cliked(widget, AD), btn, "clicked")
	
	update_skip_frames(widget, AD) = begin
		AD.skip_frames = Gtk._.value(widget)
	end
	signal_connect((widget,state) -> update_skip_frames(widget, AD), slider, "button-release-event")
	


	@guarded draw(c) do widget
		ctx = getgc(c)
		h = height(c)
		w = width(c)
		
		step_w = w/WIDTH
		step_h = h/HEIGHT
		
		#fill with white
		rectangle(ctx, 0, 0, w, h)
		set_source_rgb(ctx, 1, 1, 1)
		fill(ctx)
		
		
		
		
		for i = 1:length(home_pheromones)
			value = home_pheromones[i]
			x,y = ind2sub(home_pheromones, i).-1
			if value > MIN_PHERO
				rectangle(ctx, x*step_w, y*step_h, step_w, step_h)
				set_source_rgba(ctx, 0, 0.1, 0.8,  ((value - MIN_PHERO) / MAX_PHERO)^2)
				fill(ctx)
			end
		end
		
		for i = 1:length(food_pheromones)
			value = food_pheromones[i]
			x,y = ind2sub(food_pheromones, i).-1
			if value > MIN_PHERO
				rectangle(ctx, x*step_w, y*step_h, step_w, step_h)
				set_source_rgba(ctx, 0.9, 0.1, 0, ((value - MIN_PHERO) / MAX_PHERO)^2)
				fill(ctx)
			end
		end
		#draw the ants
		for ant in ants
			#rectangle(ctx, (ant.x-1)*step_w, (ant.y-1)*step_h, step_w, step_h)
			arc(ctx, (ant.x-1)*step_w + step_w/2, (ant.y-1)*step_h + step_h/2,0.5 * min(step_h, step_w), 0, 2pi)
			set_source_rgb(ctx, ant.loaded ? 1 : 0, 0, ant.loaded ? 0 : 1)
			fill(ctx)
		end
		
		#draw the ressource grid
		inds = 1:length(grid)
		for i in inds
			value = grid[i]
			if value != 0
				x,y = ind2sub(grid, i).-1
				rectangle(ctx, x*step_w, y*step_h, step_w, step_h)
				if value == -1
					set_source_rgb(ctx, 0, 0, 0)
				elseif value == -2
					set_source_rgb(ctx, 0.5, 0.5, 0.5)
				else
					set_source_rgba(ctx, 0, 1, 0, value/VALUE_MAX)
				end
				fill(ctx)
			end
		end	
	end
	
	c.mouse.button1press = @guarded (widget, event) -> begin
		ctx = getgc(widget)

		step_w = width(c)/WIDTH
		step_h = height(c)/HEIGHT
		x = trunc(Int,event.x / width(c) * WIDTH) + 1
		y = trunc(Int,event.y / height(c) * HEIGHT) + 1
		
		if grid[x,y] == 0
			grid[x,y] = -1
		end
		draw(widget)
	end

	c.mouse.button1motion = @guarded (widget, event) -> begin
		ctx = getgc(widget)

		step_w = width(c)/WIDTH
		step_h = height(c)/HEIGHT
		x = trunc(Int,event.x / width(c) * WIDTH) + 1
		y = trunc(Int,event.y / height(c) * HEIGHT) + 1
		
		if grid[x,y] == 0
			grid[x,y] = -1
		end
		draw(widget)
	end
	
	c.mouse.button2press = @guarded (widget, event) -> begin
		ctx = getgc(widget)

		step_w = width(c)/WIDTH
		step_h = height(c)/HEIGHT
		x = trunc(Int,event.x / width(c) * WIDTH) + 1
		y = trunc(Int,event.y / height(c) * HEIGHT) + 1
		
		if grid[x,y] == -1
			grid[x,y] = 0
		end
		draw(widget)
	end

	c.mouse.button2motion = @guarded (widget, event) -> begin
		ctx = getgc(widget)

		step_w = width(c)/WIDTH
		step_h = height(c)/HEIGHT
		x = trunc(Int,event.x / width(c) * WIDTH) + 1
		y = trunc(Int,event.y / height(c) * HEIGHT) + 1
		
		if grid[x,y] == -1
			grid[x,y] = 0
		end
		draw(widget)
	end
	
	c.mouse.button3press = @guarded (widget, event) -> begin
		ctx = getgc(widget)

		step_w = width(c)/WIDTH
		step_h = height(c)/HEIGHT
		x = trunc(Int,event.x / width(c) * WIDTH) + 1
		y = trunc(Int,event.y / height(c) * HEIGHT) + 1
		
		for i = -1:1, j = -1:1
			_x, _y = x + i, y + j
			if 1 <= _x <= HEIGHT && 1 <= _y <= WIDTH && grid[_x,_y] == 0
				grid[_x,_y] = -1
			end
		end
		draw(widget)

	end

	c.mouse.button3motion = @guarded (widget, event) -> begin
		ctx = getgc(widget)

		step_w = width(c)/WIDTH
		step_h = height(c)/HEIGHT
		x = trunc(Int,event.x / width(c) * WIDTH) + 1
		y = trunc(Int,event.y / height(c) * HEIGHT) + 1
		
		for i = -1:1, j = -1:1
			_x, _y = x + i, y + j
			if 1 <= _x <= HEIGHT && 1 <= _y <= WIDTH && grid[_x,_y] == 0
				grid[_x,_y] = -1
			end
		end
		draw(widget)
	end
	
	sleep(5)
	c
end