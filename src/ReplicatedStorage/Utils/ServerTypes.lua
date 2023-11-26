export type metatable = typeof(setmetatable({}, {}))
export type singleton = {[any] : any}

export type IPlayer = {
	AddTool : (IPlayer, string, Tool) -> nil,
	RemoveTool : (IPlayer, string) -> nil,
	EquipTool : (IPlayer, string) -> nil,
	UnequipTool : (IPlayer, string) -> nil,
	UnequipAll : (IPlayer) -> nil,
	DoDamage : (IPlayer, number, string?) -> nil,
	HandleCharacter : (IPlayer) -> nil,
	HandleDeath : (IPlayer) -> nil
}

return nil
