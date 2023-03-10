/obj/item/stock_parts
	name = "stock part"
	desc = "What?"
	gender = NEUTER
	icon = 'icons/obj/stock_parts.dmi'
	randpixel = 5
	w_class = ITEM_SIZE_SMALL
	var/part_flags = PART_FLAG_LAZY_INIT | PART_FLAG_HAND_REMOVE
	var/rating = 1
	var/status = 0             // Flags using PART_STAT defines.
	var/base_type              // Type representing parent of category for replacer usage.
	drop_sound = 'sound/items/drop/glass.ogg'
	pickup_sound = 'sound/items/pickup/glass.ogg'

/obj/item/stock_parts/attack_hand(mob/user)
	if(istype(loc, /obj/machinery))
		return FALSE // Can potentially add uninstall code here, but not currently supported.
	return ..()

/obj/item/stock_parts/proc/set_status(obj/machinery/machine, flag)
	var/old_stat = status
	status |= flag
	if(old_stat != status)
		if(!machine)
			machine = loc
		if(istype(machine))
			machine.component_stat_change(src, old_stat, flag)

/obj/item/stock_parts/proc/unset_status(obj/machinery/machine, flag)
	var/old_stat = status
	status &= ~flag
	if(old_stat != status)
		if(!machine)
			machine = loc
		if(istype(machine))
			machine.component_stat_change(src, old_stat, flag)

/obj/item/stock_parts/proc/on_install(obj/machinery/machine)
	set_status(machine, PART_STAT_INSTALLED)

/obj/item/stock_parts/proc/on_uninstall(obj/machinery/machine, temporary = FALSE)
	unset_status(machine, PART_STAT_INSTALLED)
	stop_processing(machine)
	if(!temporary && (part_flags & PART_FLAG_QDEL))
		qdel(src)

// Use to process on the machine it's installed on.

/obj/item/stock_parts/proc/start_processing(obj/machinery/machine)
	LAZYDISTINCTADD(machine.processing_parts, src)
	START_PROCESSING_MACHINE(machine, MACHINERY_PROCESS_COMPONENTS)
	set_status(machine, PART_STAT_PROCESSING)

/obj/item/stock_parts/proc/stop_processing(obj/machinery/machine)
	LAZYREMOVE(machine.processing_parts, src)
	if(!LAZYLEN(machine.processing_parts))
		STOP_PROCESSING_MACHINE(machine, MACHINERY_PROCESS_COMPONENTS)
	unset_status(machine, PART_STAT_PROCESSING)

/obj/item/stock_parts/proc/machine_process(obj/machinery/machine)
	return PROCESS_KILL

// RefreshParts has been called, likely meaning other componenets were added/removed.
/obj/item/stock_parts/proc/on_refresh(obj/machinery/machine)
