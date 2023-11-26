local InteractFunctions = {}
--[[
	<description>
		This class manages resource interaction functions. Default function is used if no function specified for specific item.
	</description> 
	
	<API>
		InteractFunctions.Tree(Core, object: Instance, status: boolean?) ---> nil 
			-- Tree interaction effect. Fire the tree fall interaction to all clients and make it transparent on server.
			Core: Core ---> Core dictionary 
			object: Instance ---> Tree object that is being made transparent 
			status: boolean? ---> True if it was interacted with. False if respawned.
	</API>
	
	<Authors>
		RoGuruu (770772041)
	</Authors>
--]]

--*************************************************************************************************--

function InteractFunctions.Tree(Core, object: Instance, status: boolean?): nil
	local transparency = status and 1 or 0
	if status then
		Core.Utils.Net:RemoteEvent("TreeInteract"):FireAllClients(object)
	end
	for _, v in object:GetChildren() do
		if v:IsA("BasePart") and v.Name ~= "Stump" then
			v.Transparency = transparency
			v.CanCollide = not status
		end
	end
	return
end

function InteractFunctions.Default(Core, object: Instance, status: boolean?): nil
	local transparency = status and 1 or 0
	if status then
		Core.Utils.Net:RemoteEvent("DefaultInteract"):FireAllClients(object)
	end
	for _, v in object:GetChildren() do
		if v:IsA("BasePart") and v.Name ~= "Stump" then
			v.Transparency = transparency
			v.CanCollide = not status
		end
	end
	if object:IsA("BasePart") then
		object.Transparency = transparency
		object.CanCollide = status
	end
	return
end

return InteractFunctions
