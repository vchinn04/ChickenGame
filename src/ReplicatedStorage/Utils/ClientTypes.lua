export type metatable = typeof(setmetatable({}, {}))
export type singleton = {[any] : any}

export type AnimationObject = {
	CreateAnimation : (Animation | string, Folder) -> AnimationTrack,
	GetAnimation : (string, Folder) -> AnimationTrack,
	ResumeAnimation : (string) -> nil,
	PauseAnimation : (string) -> nil,
	StopAnimation : (string, Folder) -> nil,
	PlayAnimation : (string, Folder) -> AnimationTrack,
	SetPriority : (string, Enum.AnimationPriority, Folder) -> nil,
	load_anims : ({[number] : Animation | string}) -> AnimationTrack,
	DoCleaning : () -> nil,
	Destroy : () -> nil
}

return nil
