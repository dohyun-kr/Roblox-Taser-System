-- DamageSystem.lua
-- 감전 데미지 및 상태 관리

local DamageSystem = {}
local RunService = game:GetService("RunService")

local CONFIG = {
	damagePerSecond = 10,
	debounce = 0.1,
	tetherMaxDistance = 30,
	slowEffect = 0.7, -- 속도 감소
}

local activeDamage = {}

-- 감전 시작
function DamageSystem:StartElectricity(taser, target, state)
	if not target or not target:FindFirstChild("Humanoid") then return false end
	
	local humanoid = target:FindFirstChild("Humanoid")
	local damageId = tostring(target) .. "_" .. tostring(taser)
	
	if activeDamage[damageId] then return false end
	
	activeDamage[damageId] = {
		taser = taser,
		target = target,
		humanoid = humanoid,
		state = state,
		lastDamageTime = 0,
		isActive = true,
	}
	
	self:ApplyDamageLoop(damageId)
	
	return true
end

-- 데미지 루프
function DamageSystem:ApplyDamageLoop(damageId)
	local damageData = activeDamage[damageId]
	if not damageData then return end
	
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not damageData.isActive or not damageData.humanoid or damageData.humanoid.Health <= 0 then
			connection:Disconnect()
			activeDamage[damageId] = nil
			return
		end
		
		-- 거리 체크
		local distance = (damageData.taser.Position - damageData.target.Position).Magnitude
		if distance > CONFIG.tetherMaxDistance then
			damageData.isActive = false
			connection:Disconnect()
			activeDamage[damageId] = nil
			return
		end
		
		-- 데미지 적용
		local currentTime = tick()
		if currentTime - damageData.lastDamageTime >= CONFIG.debounce then
			damageData.humanoid:TakeDamage(CONFIG.damagePerSecond * CONFIG.debounce)
			damageData.lastDamageTime = currentTime
			
			-- 속도 감소 효과
			self:ApplySlowEffect(damageData.target)
			
			-- 감전 상태 이펙트
			self:ApplyShockEffect(damageData.target)
		end
	end)
end

-- 속도 감소 효과
function DamageSystem:ApplySlowEffect(target)
	if not target then return end
	
	local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- 현재 속도를 줄임
	local bodyVelocity = humanoidRootPart:FindFirstChild("SlowVelocity")
	if not bodyVelocity then
		bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Name = "SlowVelocity"
		bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
		bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		bodyVelocity.Parent = humanoidRootPart
	end
	
	-- 느린 속도로 설정
	if humanoidRootPart.Velocity.Magnitude > 0 then
		bodyVelocity.Velocity = humanoidRootPart.Velocity * CONFIG.slowEffect
	end
end

-- 감전 상태 이펙트
function DamageSystem:ApplyShockEffect(target)
	if not target then return end
	
	local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- 번개 이펙트
	for _ = 1, 3 do
		local effect = Instance.new("Part")
		effect.Name = "ShockEffect"
		effect.Shape = Enum.PartType.Ball
		effect.Material = Enum.Material.Neon
		effect.Color = Color3.fromRGB(255, 255, 100)
		effect.Size = Vector3.new(0.4, 0.4, 0.4)
		effect.CanCollide = false
		effect.TopSurface = Enum.SurfaceType.Smooth
		effect.BottomSurface = Enum.SurfaceType.Smooth
		
		local randomOffset = Vector3.new(
			math.random(-30, 30) / 10,
			math.random(-30, 30) / 10,
			math.random(-30, 30) / 10
		)
		effect.CFrame = humanoidRootPart.CFrame + randomOffset
		effect.Parent = workspace
		
		game:GetService("Debris"):AddItem(effect, 0.2)
	end
end

-- 감전 중단
function DamageSystem:StopElectricity(taser, target)
	local damageId = tostring(target) .. "_" .. tostring(taser)
	
	if activeDamage[damageId] then
		activeDamage[damageId].isActive = false
		activeDamage[damageId] = nil
		
		-- SlowVelocity 제거
		local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local slowVelocity = humanoidRootPart:FindFirstChild("SlowVelocity")
			if slowVelocity then
				slowVelocity:Destroy()
			end
		end
		
		return true
	end
	
	return false
end

-- 모든 감전 중단
function DamageSystem:StopAllElectricity()
	for damageId, damageData in pairs(activeDamage) do
		damageData.isActive = false
		
		local humanoidRootPart = damageData.target:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local slowVelocity = humanoidRootPart:FindFirstChild("SlowVelocity")
			if slowVelocity then
				slowVelocity:Destroy()
			end
		end
	end
	activeDamage = {}
end

-- 데미지 정보 조회
function DamageSystem:GetDamageInfo(taser, target)
	local damageId = tostring(target) .. "_" .. tostring(taser)
	return activeDamage[damageId]
end

return DamageSystem
