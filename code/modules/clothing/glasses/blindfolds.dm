/obj/item/clothing/glasses/blindfold
	name = "blindfold"
	desc = "Covers the eyes, preventing sight."
	action_button_name = "Adjust Blindfold"
	icon_state = "blindfold"
	item_state = "blindfold"
	off_state = "blindfoldup"
	tint = TINT_BLIND
	flash_protection = FLASH_PROTECTION_MAJOR
	item_flags = ITEM_FLAG_WASHER_ALLOWED
	darkness_view = -1
	toggleable = TRUE
	activation_sound = null
	drop_sound = 'sound/items/drop/gloves.ogg'
	pickup_sound = 'sound/items/pickup/gloves.ogg'

/obj/item/clothing/glasses/blindfold/Initialize()
	. = ..()
	toggle_off_message = "You flip \the [src] up."
	toggle_on_message = "You slide \the [src] down, blinding yourself."

/obj/item/clothing/glasses/blindfold/attack_self()
	. =..()
	if(!.)
		return
	if(active)
		flags_inv &= ~HIDEEYES
		body_parts_covered &= ~EYES
	else
		flags_inv |= HIDEEYES
		body_parts_covered |= EYES

/obj/item/clothing/glasses/blindfold/tape
	name = "length of tape"
	desc = "It's a robust DIY blindfold!"
	icon = 'icons/obj/bureaucracy.dmi'
	action_button_name = null
	icon_state = "tape_cross"
	item_state = null
	item_flags = null
	w_class = ITEM_SIZE_TINY
	toggleable = FALSE
