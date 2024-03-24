local ProbabilityUtil = {}
ProbabilityUtil.__index = ProbabilityUtil

function get_total(probabilities): number
	local total: number = 0
	for _, entry in probabilities do
		total += entry[2]
	end
	return total
end

function ProbabilityUtil:GetPrediction(): string?
	local next_weight = self._random_generator:NextInteger(0, self._total)
	local total = 0
	for _, item in self._probabilities do
		total += item[2]
		if total >= next_weight then
			return item[1]
		end
	end

	return nil
end

function ProbabilityUtil:AdjustProbability(key, value): nil
	if self._probabilities[key] ~= nil then
		self._total += value - self._probabilities[key][2]
		self._probabilities[key][2] = value
	end

	return nil
end

function ProbabilityUtil:Destroy(): nil
	self._probabilities = nil
	self._total = nil
	self = nil
	return
end

function ProbabilityUtil.new(probabilities)
	local self = setmetatable({}, ProbabilityUtil)
	self._probabilities = probabilities
	self._total = get_total(probabilities)
	self._random_generator = Random.new(tick())
	return self
end
return ProbabilityUtil
