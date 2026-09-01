-- TaserScript.lua
-- ServerScriptService의 메인 서버 스크립트

local TaserScript = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- 테이저 상태 관리
local taserStates = {}

-- 설정
local CONFIG = {
	maxDistance = 30,
	tetherLength = 30,
	damagePerSecond = 10,
	debounce = 0.1,
	cartridgeCount = 2,
}

-- 플레이어가 테이저를 들었을 때
function TaserScript:InitializeTaser(player, taser)
	if not taserStates[player.UserId] then
		taserStates[player.UserId] = {
			player = player,
			taser = taser,
			isActive = false,
			target = nil,
			lastDamageTime = 0,
			cartridgeCount = CONFIG.cartridgeCount,
			isConnected = false,
		}
	end
end

-- 발포 처리
function TaserScript:Fire(player, mousePosition)
	local state = taserStates[player.UserId]
	if not state or state.isActive then return false end
	
	if state.cartridgeCount <= 0 then
		print("탄약 없음!")
		return false
	end
	
	state.isActive = true
	state.cartridgeCount = state.cartridgeCount - 1
	
	-- 줄 생성 및 타겟 탐지
	self:CreateTether(player, mousePosition)
	
	return true
end

-- 줄 생성
function TaserScript:CreateTether(player, targetPos)
	local state = taserStates[player.UserId]
	if not state then return end
	
	local taser = state.taser
	local barrel = taser:FindFirstChild("Barrel")
	if not barrel then return end
	
	local startPos = barrel.Position + barrel.CFrame.LookVector * 2
	local direction = (targetPos - startPos).Unit * CONFIG.maxDistance
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {player.Character}
	
	local rayResult = workspace:Raycast(startPos, direction, raycastParams)
	
	if rayResult then
		local hitPart = rayResult.Instance
		local hitCharacter = hitPart.Parent
		
		-- 줄 시각화
		self:VisualizeTether(startPos, rayResult.Position)
		
		-- 카트리지 파괴 이펙트
		self:DestroyCartridges(taser)
		
		-- 타겟이 Humanoid를 가지면 감전
		if hitCharacter:FindFirstChild("Humanoid") then
			state.target = hitCharacter
			state.isConnected = true
			self:ApplyElectricity(hitCharacter, state)
		end
	end
end

-- 줄 시각화 (흰색/검은색 줄무늬)
function TaserScript:VisualizeTether(startPos, endPos)
	local distance = (startPos - endPos).Magnitude
	local segmentCount = math.floor(distance / 1)
	
	for i = 1, segmentCount do
		local t = i / segmentCount
		local pos = startPos:Lerp(endPos, t)
		
		local tether = Instance.new("Part")
		tether.Name = "TetherSegment"
		tether.Shape = Enum.PartType.Cylinder
		tether.Material = Enum.Material.Neon
		
		-- 흰색/검은색 교대
		if i % 2 == 0 then
			tether.Color = Color3.fromRGB(255, 255, 255) -- 흰색
		else
			tether.Color = Color3.fromRGB(50, 50, 50) -- 검은색
		end
		
		tether.CanCollide = false
		tether.Size = Vector3.new(0.2, 1, 0.2)
		tether.CFrame = CFrame.new(pos)
		tether.Parent = workspace
		
		game:GetService("Debris"):AddItem(tether, 2)
	end
end

-- 카트리지 파괴 이펙트
function TaserScript:DestroyCartridges(taser)
	local cartridgeL = taser:FindFirstChild("Cartridge.L")
	local cartridgeR = taser:FindFirstChild("Cartridge.R")
	
	if cartridgeL then
		self:ExploadCartridge(cartridgeL)
	end
	if cartridgeR then
		self:ExploadCartridge(cartridgeR)
	end
end

-- 카트리지 폭발 효과
function TaserScript:ExploadCartridge(cartridge)
	-- 카트리지 파괴 처리
	local explosion = Instance.new("Part")
	explosion.Name = "Explosion"
	explosion.Shape = Enum.PartType.Ball
	explosion.Material = Enum.Material.Neon
	explosion.Color = Color3.fromRGB(255, 165, 0) -- 주황색
	explosion.Size = Vector3.new(2, 2, 2)
	explosion.CanCollide = false
	explosion.CFrame = cartridge.CFrame
	explosion.Parent = workspace
	
	-- 물리적 폭발
	local velocity = explosion.Position - cartridge.Position
	explosion.Velocity = velocity.Unit * 50
	
	game:GetService("Debris"):AddItem(explosion, 0.5)
end

-- 감전 처리
function TaserScript:ApplyElectricity(target, state)
	if not target:FindFirstChild("Humanoid") then return end
	
	local humanoid = target:FindFirstChild("Humanoid")
	local connection
	
	connection = RunService.Heartbeat:Connect(function()
		if not state.isActive or not state.isConnected then
			connection:Disconnect()
			state.target = nil
			state.isConnected = false
			return
		end
		
		-- 거리 체크 (줄 끊김)
		local distance = (state.taser.Position - target.Position).Magnitude
		if distance > CONFIG.tetherLength then
			connection:Disconnect()
			state.isActive = false
			state.isConnected = false
			state.target = nil
			return
		end
		
		-- 데미지 적용
		local currentTime = tick()
		if currentTime - state.lastDamageTime >= CONFIG.debounce then
			humanoid:TakeDamage(CONFIG.damagePerSecond * CONFIG.debounce)
			state.lastDamageTime = currentTime
			
			-- 번개 이펙트
			self:CreateElectricEffect(target)
		end
	end)
end

-- 번개 이펙트
function TaserScript:CreateElectricEffect(target)
	local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	local effect = Instance.new("Part")
	effect.Name = "ElectricEffect"
	effect.Shape = Enum.PartType.Ball
	effect.Material = Enum.Material.Neon
	effect.Color = Color3.fromRGB(255, 255, 0)
	effect.Size = Vector3.new(0.5, 0.5, 0.5)
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

-- 줄 끊기
function TaserScript:CutTether(player)
	local state = taserStates[player.UserId]
	if state then
		state.isActive = false
		state.isConnected = false
		state.target = nil
	end
end

-- 리필
function TaserScript:Refill(player)
	local state = taserStates[player.UserId]
	if state then
		state.cartridgeCount = CONFIG.cartridgeCount
		print("탄약 리필됨!")
	end
end

-- 상태 조회
function TaserScript:GetState(player)
	return taserStates[player.UserId]
end

return TaserScript
