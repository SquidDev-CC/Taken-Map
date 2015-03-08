--[[
 0x00: Introduction

 Congratulations,
 you've picked
 up your computer.

 You now need to
 head to the exit
 (the beacon)
]]

function Generate(world)
 world.setDimensions(10, 10)

 world.setExit(9, 9)

 world.setPlayer(0, 0)
 world.addItem(5, 0, 5, Items.createItem(
  Config.BlockInfo.Pocket.Id,
  1,
  Computers.createPocket(0, "Someone's pocket", true)
 ))
end
