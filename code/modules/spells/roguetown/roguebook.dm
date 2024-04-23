/datum/roguebook_entry
	var/name = "Entry Name"

	var/spell_type = null
	var/desc = ""
	var/category = "Evocation"
	var/cost = 2
	var/refundable = TRUE
	var/surplus = -1 // -1 for infinite, not used by anything atm
	var/obj/effect/proc_holder/spell/S = null //Since spellbooks can be used by only one person anyway we can track the actual spell
	var/buy_word = "Memorize"
	var/limit //used to prevent a spellbook_entry from being bought more than X times with one wizard spellbook
	var/list/no_coexistance_typecache //Used so you can't have specific spells together

/datum/roguebook_entry/New()
	..()
	no_coexistance_typecache = typecacheof(no_coexistance_typecache)

/datum/roguebook_entry/proc/CanBuy(mob/living/carbon/human/user,obj/item/roguebook) // Specific circumstances
	for(var/spell in user.mind.spell_list)
		if(is_type_in_typecache(spell, no_coexistance_typecache))
			return FALSE
	return TRUE

/datum/roguebook_entry/proc/Buy(mob/living/carbon/human/user,obj/item/roguebook) //return TRUE on success
	if(!S || QDELETED(S))
		S = new spell_type()
	//Check if we got the spell already
	for(var/obj/effect/proc_holder/spell/aspell in user.mind.spell_list)
		if(initial(S.name) == initial(aspell.name)) // Not using directly in case it was learned from one spellbook then upgraded in another
			to_chat(user,  "<span class='warning'>You have already memorized this spell!</span>")
			return FALSE

	//No same spell found - just learn it
	user.mind.AddSpell(S)
	to_chat(user, "<span class='notice'>I have memorized [S.name].</span>")
	return TRUE

/datum/roguebook_entry/proc/CanRefund(mob/living/carbon/human/user,obj/item/roguebook)
	if(!refundable)
		return FALSE
	if(!S)
		S = new spell_type()
	for(var/obj/effect/proc_holder/spell/aspell in user.mind.spell_list)
		if(initial(S.name) == initial(aspell.name))
			return TRUE
	return FALSE

/datum/roguebook_entry/proc/Refund(mob/living/carbon/human/user,obj/item/roguebook) //return point value or -1 for failure
	if(!S)
		S = new spell_type()
	var/spell_levels = 0
	for(var/obj/effect/proc_holder/spell/aspell in user.mind.spell_list)
		if(initial(S.name) == initial(aspell.name))
			spell_levels = aspell.spell_level
			user.mind.spell_list.Remove(aspell)
			qdel(S)
			return cost * (spell_levels+1)
	return -1
/datum/roguebook_entry/proc/GetInfo()
	if(!S)
		S = new spell_type()
	var/dat =""
	dat += "<b>[initial(S.name)]</b>"
	if(S.charge_type == "recharge")
		dat += " Cooldown:[S.charge_max/10]"
	dat += "<i>[S.desc][desc]</i><br>"
	return dat

/datum/roguebook_entry/fireball
	name = "Fireball"
	spell_type = /obj/effect/proc_holder/spell/invoked/projectile/fireball
	category = "Evocation"

/datum/roguebook_entry/fetch
	name = "Fetch"
	spell_type = /obj/effect/proc_holder/spell/invoked/projectile/fetch
	category = "Transmutation"


/obj/item/roguebook
	name = "spell book"
	desc = ""
	icon = 'icons/obj/library.dmi'
	icon_state ="book"
	throw_speed = 2
	throw_range = 5
	w_class = WEIGHT_CLASS_TINY
	var/uses = 10
	var/temp = null
	var/tab = null
	var/mob/living/carbon/human/owner
	var/list/datum/roguebook_entry/entries = list()
	var/list/categories = list()

/obj/item/roguebook/examine(mob/user)
	. = ..()
	if(owner)
		. += {"There is a small signature on the front cover: "[owner]"."}
	else
		. += "It appears to have no author."

/obj/item/roguebook/Initialize()
	. = ..()
	prepare_spells()

/obj/item/roguebook/proc/prepare_spells()
	var/entry_types = subtypesof(/datum/roguebook_entry)
	for(var/T in entry_types)
		var/datum/roguebook_entry/E = new T
		entries |= E
		categories |= E.category
	tab = categories[1]

/obj/item/roguebook/proc/GetCategoryHeader(category)
	var/dat = ""
	switch(category)
		if("Evocation")
			dat += "Magic for creating and manipulating raw magical energy to produce powerful effects.<BR><BR>"
		if("Abjuration")
			dat += "Magic focused on protection and warding off harmful effects.<BR><BR>"
		if("Conjuration")
			dat += "Magic for summoning creatures, objects, or energy from other planes.<BR><BR>"
		if("Divination")
			dat += "Magic centered around gaining knowledge, foresight, and insight.<BR><BR>"
		if("Illusion")
			dat += "Magic for creating sensory effects or images that deceive the senses.<BR><BR>"
		if("Transmutation")
			dat += "Magic for altering the properties of objects, creatures, or the environment.<BR><BR>"
		if("Enchantment")
			dat += "Magic for influencing or controlling the minds of others.<BR><BR>"
		if("Necromancy")
			dat += "Magic dealing with death, undeath, and manipulating life force.<BR><BR>"
	return dat

/obj/item/roguebook/proc/wrap(content)
	var/dat = ""
	dat +="<html><head><title>Spellbook</title></head>"
	dat += {"
	<head>
		<style type="text/css">
      		body { font-family: "Papyrus", cursive, sans-serif; }
      		ul#tabs { list-style-type: none; margin: 30px 0 0 0; padding: 0 0 0.3em 0; }
      		ul#tabs li { display: inline; }
      		ul#tabs li a { color: #42454a; background-color: #dedbde; border: 1px solid #c9c3ba; border-bottom: none; padding: 0.3em; text-decoration: none; }
      		ul#tabs li a:hover { background-color: #f1f0ee; }
      		ul#tabs li a.selected { color: #000; background-color: #f1f0ee; font-weight: bold; padding: 0.7em 0.3em 0.38em 0.3em; }
      		div.tabContent { border: 1px solid #c9c3ba; padding: 0.5em; background-color: #f1f0ee; }
      		div.tabContent.hide { display: none; }
    	</style>
  	</head>
	"}
	dat += {"[content]</body></html>"}
	return dat

/obj/item/roguebook/attack_self(mob/user)
	user.set_machine(src)
	var/dat = ""

	dat += "<ul id=\"tabs\">"
	var/list/cat_dat = list()
	for(var/category in categories)
		cat_dat[category] = "<hr>"
		dat += "<li><a [tab==category?"class=selected":""] href='byond://?src=[REF(src)];page=[category]'>[category]</a></li>"

	dat += "<li><a><b>Points remaining : [uses]</b></a></li>"
	dat += "</ul>"

	var/datum/roguebook_entry/E
	for(var/i=1,i<=entries.len,i++)
		var/spell_info = ""
		E = entries[i]
		spell_info += E.GetInfo()
		if(E.CanBuy(user,src))
			spell_info+= "<a href='byond://?src=[REF(src)];buy=[i]'>[E.buy_word]</A><br>"
		else
			spell_info+= "<span>Can't [E.buy_word]</span><br>"
		if(E.CanRefund(user,src))
			spell_info+= "<a href='byond://?src=[REF(src)];refund=[i]'>Refund</A><br>"
		spell_info += "<hr>"
		if(cat_dat[E.category])
			cat_dat[E.category] += spell_info

	for(var/category in categories)
		dat += "<div class=\"[tab==category?"tabContent":"tabContent hide"]\" id=\"[category]\">"
		dat += GetCategoryHeader(category)
		dat += cat_dat[category]
		dat += "</div>"

	user << browse(wrap(dat), "window=spellbook;size=700x500")
	onclose(user, "spellbook")
	return

/obj/item/roguebook/Topic(href, href_list)
	..()
	var/mob/living/carbon/human/H = usr

	if(H.stat || H.restrained())
		return
	if(!ishuman(H))
		return TRUE

	var/datum/roguebook_entry/E = null
	if(loc == H || (in_range(src, H) && isturf(loc)))
		H.set_machine(src)
		if(href_list["buy"])
			E = entries[text2num(href_list["buy"])]
			if(E && E.CanBuy(H,src))
				if(E.Buy(H,src))
					if(E.limit)
						E.limit--
					uses -= E.cost
		else if(href_list["refund"])
			E = entries[text2num(href_list["refund"])]
			if(E && E.refundable)
				var/result = E.Refund(H,src)
				if(result > 0)
					if(!isnull(E.limit))
						E.limit += result
					uses += result
		else if(href_list["page"])
			tab = sanitize(href_list["page"])
	attack_self(H)
	return
