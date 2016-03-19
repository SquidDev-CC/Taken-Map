local items = {}

-- /summon Item ~ ~ ~3 {Item:{id:276,Count:3,Damage:3,tag:{display:{Name:"your name"}}},Age:-32768}
-- /summon Item ~ ~ ~3 {Item:{id:"minecraft_diamond_sword",Count:3,Damage:3}}
-- /give @p 268 1 0 {display:{Name:"This can Rename an Item",Lore:[This is a line of 'Lore']}}

function items.createItem(id, damage, tags)
	return {id=id,Damage=damage,tag=tags,Count=1}
end

function items.itemEntity(item, noDespawn)
	local data = {Item=item}
	if noDespawn then
		data.Age = -32768
	end

	return data
end

return items
