var/global/total_lighting_overlays = 0
/atom/movable/lighting_overlay
	name = ""
	mouse_opacity = 0
	simulated = FALSE
	anchored = TRUE
	icon = LIGHTING_ICON
	plane = LIGHTING_PLANE
	layer = LIGHTING_LAYER
	invisibility = INVISIBILITY_LIGHTING
	color = LIGHTING_BASE_MATRIX
	icon_state = "light1"
	blend_mode = BLEND_OVERLAY

	appearance_flags = DEFAULT_APPEARANCE_FLAGS

	var/lum_r = 0
	var/lum_g = 0
	var/lum_b = 0

	var/needs_update = FALSE

/atom/movable/lighting_overlay/Initialize()
	// doesn't need special init
	SHOULD_CALL_PARENT(FALSE)
	atom_flags |= ATOM_FLAG_INITIALIZED
	return INITIALIZE_HINT_NORMAL

/atom/movable/lighting_overlay/New(atom/loc, no_update = FALSE)
	var/turf/T = loc //If this runtimes atleast we'll know what's creating overlays outside of turfs.
	if(T.dynamic_lighting)
		. = ..()
		verbs.Cut()
		total_lighting_overlays++

		T.lighting_overlay = src
		T.luminosity = 0
		if(no_update)
			return
		update_overlay()
	else
		qdel(src)

/atom/movable/lighting_overlay/proc/update_overlay()
	set waitfor = FALSE
	var/turf/T = loc

	if(!istype(T))
		if(loc)
			log_debug("A lighting overlay realised its loc was NOT a turf (actual loc: [loc][loc ? ", " + loc.type : "null"]) in update_overlay() and got qdel'ed!")
		else
			log_debug("A lighting overlay realised it was in nullspace in update_overlay() and got pooled!")
		qdel(src)
		return
	if(!T.dynamic_lighting)
		qdel(src)
		return

	// To the future coder who sees this and thinks
	// "Why didn't he just use a loop?"
	// Well my man, it's because the loop performed like shit.
	// And there's no way to improve it because
	// without a loop you can make the list all at once which is the fastest you're gonna get.
	// Oh it's also shorter line wise.
	// Including with these comments.

	// See LIGHTING_CORNER_DIAGONAL in lighting_corner.dm for why these values are what they are.
	// No I seriously cannot think of a more efficient method, fuck off Comic.
	var/datum/lighting_corner/cr = T.corners[3] || dummy_lighting_corner
	var/datum/lighting_corner/cg = T.corners[2] || dummy_lighting_corner
	var/datum/lighting_corner/cb = T.corners[4] || dummy_lighting_corner
	var/datum/lighting_corner/ca = T.corners[1] || dummy_lighting_corner

	var/max = max(cr.cache_mx, cg.cache_mx, cb.cache_mx, ca.cache_mx)

	var/rr = cr.cache_r
	var/rg = cr.cache_g
	var/rb = cr.cache_b

	var/gr = cg.cache_r
	var/gg = cg.cache_g
	var/gb = cg.cache_b

	var/br = cb.cache_r
	var/bg = cb.cache_g
	var/bb = cb.cache_b

	var/ar = ca.cache_r
	var/ag = ca.cache_g
	var/ab = ca.cache_b

	#if LIGHTING_SOFT_THRESHOLD != 0
	var/set_luminosity = max > LIGHTING_SOFT_THRESHOLD
	#else
	// Because of floating points, it won't even be a flat 0.
	// This number is mostly arbitrary.
	var/set_luminosity = max > 1e-6
	#endif

	// If all channels are full lum, there's no point showing the overlay.
	if(rr + rg + rb + gr + gg + gb + br + bg + bb + ar + ag + ab >= 12)
		icon_state = "transparent"
		color = null
	else if(!set_luminosity)
		icon_state = LIGHTING_ICON_STATE_DARK
		color = null
	else
		icon_state = null
		color = list(
			-rr, -rg, -rb, 00,
			-gr, -gg, -gb, 00,
			-br, -bg, -bb, 00,
			-ar, -ag, -ab, 00,
			01, 01, 01, 01
		)

	luminosity = set_luminosity
	// if (T.above && T.above.shadower)
	// 	T.above.shadower.copy_lighting(src)

// Variety of overrides so the overlays don't get affected by weird things.
/atom/movable/lighting_overlay/ex_act()
	return

/atom/movable/lighting_overlay/singularity_pull()
	return

/atom/movable/lighting_overlay/Destroy()
	total_lighting_overlays--
	SSlighting.overlay_queue -= src

	var/turf/T = loc
	if(istype(T))
		T.lighting_overlay = null

	. = ..()

/atom/movable/lighting_overlay/forceMove()
	//should never move
	//In theory... except when getting deleted :C
	if(QDELING(src))
		return ..()
	return 0

/atom/movable/lighting_overlay/Move()
	return 0

/atom/movable/lighting_overlay/throw_at()
	return 0



// This controls by how much console sprites are dimmed before being overlayed.
#define HOLOSCREEN_ADDITION_FACTOR 1
#define HOLOSCREEN_MULTIPLICATION_FACTOR 0.5
#define HOLOSCREEN_ADDITION_OPACITY 0.8
#define HOLOSCREEN_MULTIPLICATION_OPACITY 1

// Factor/Opacity values are defined in __defines\lighting.dm

/proc/holographic_overlay(obj/target, icon, icon_state)
	var/image/multiply = make_screen_overlay(icon, icon_state)
	multiply.blend_mode = BLEND_MULTIPLY
	multiply.color = list(
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
		HOLOSCREEN_MULTIPLICATION_FACTOR, HOLOSCREEN_MULTIPLICATION_FACTOR, HOLOSCREEN_MULTIPLICATION_FACTOR, HOLOSCREEN_MULTIPLICATION_OPACITY
	)
	target.overlays += multiply
	var/image/overlay = make_screen_overlay(icon, icon_state)
	overlay.blend_mode = BLEND_ADD
	overlay.color = list(
		HOLOSCREEN_ADDITION_FACTOR, 0, 0, 0,
		0, HOLOSCREEN_ADDITION_FACTOR, 0, 0,
		0, 0, HOLOSCREEN_ADDITION_FACTOR, 0,
		0, 0, 0, HOLOSCREEN_ADDITION_OPACITY
	)
	target.overlays += overlay

/proc/make_screen_overlay(icon, icon_state, brightness_factor = null, glow_radius = 1)
	var/icon/base = new(icon, icon_state) // forgive us, but this is to get the width/height.
	var/height = base.Height() // at least this is cached in most use cases
	var/width = base.Width()
	var/image/overlay = image(icon, icon_state)
	overlay.layer = ABOVE_LIGHTING_LAYER
	var/image/underlay = image(overlay)
	underlay.alpha = 128
	underlay.transform = underlay.transform.Scale((width + glow_radius*2)/width, (height+glow_radius*2)/height)
	underlay.filters = filter(type="blur", size=glow_radius)
	overlay.underlays += underlay
	if (brightness_factor)
		overlay.color = list(
			brightness_factor, 0, 0, 0,
			0, brightness_factor, 0, 0,
			0, 0, brightness_factor, 0,
			0, 0, 0, 1
		)
	return overlay
