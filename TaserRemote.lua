-- TaserRemote.lua
-- 테이저 시스템의 메인 제어 스크립트 (ServerScriptService)

local TaserRemote = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 설정값
local TASER_CONFIG = {
	maxDistance = 30, -- 최대 거리
	tetherLength = 30, -- 줄 길이
	damagePerSecond = 10, -- 초당 데미지
	debounce = 0.1, -- 데미지 쿨다운
}

-- 테이저별 상태 저장
local taserStates = {}

-- 테이저 초기화
function TaserRemote.Initialize(player, taser)
	if not taserStates[player.UserId] then
		taserStates[player.UserId] = {
			player = player,
			taser = taser,
			isActive = false,
			target = nil,
			tetherWeld = nil,
			lastDamageTime = 0,
			cartridgeCount = 2,
		}
	end
	return taserStates[player.UserId]
end

-- 발포 함수
function TaserRemote.Fire(player, targetPosition)
	local state = taserStates[player.UserId]
	if not state then return false end
	
	-- 이미 활성화되어 있으면 중단
	if state.isActive then return false end
	
	-- 카트리지 확인
	if state.cartridgeCount <= 0 then
		print("탄약 없음!")
		return false
	end
	
	state.isActive = true
	state.cartridgeCount = state.cartridgeCount - 1
	
	-- 클라이언트에게 발포 이펙트 표시 요청
	local TaserFireEvent = Instance.new("RemoteEvent")
	TaserFireEvent.Name = "TaserFire"
	TaserFireEvent.Parent = ReplicatedStorage
	
	-- 줄 생성
	TaserRemote.CreateTether(player, targetPosition)
	
	return true
end

-- 줄 생성 함수
function TaserRemote.CreateTether(player, targetPosition)
	local state = taserStates[player.UserId]
	if not state then return end
	
	local taser = state.taser
	local barrel = taser:FindFirstChild("Barrel")
	if not barrel then return end
	
	-- 줄의 시작점
	local startPos = barrel.Position + barrel.CFrame.LookVector * 2
	
	-- 광선 추적
	local rayOrigin = startPos
	local rayDirection = (targetPosition - startPos).Unit * TASER_CONFIG.maxDistance
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {player.Character}
	
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	if rayResult then
		state.target = rayResult.Instance.Parent
		
		-- 줄 시각화
		TaserRemote.VisualizeTether(startPos, rayResult.Position)
		
		-- 타겟이 사람이면 감전 시작
		if state.target:FindFirstChild("Humanoid") then
			TaserRemote.ApplyElectricity(state.target, state)
		end
	end
end

-- 줄 시각화
function TaserRemote.VisualizeTether(startPos, endPos)
	local tether = Instance.new("Part")
	tether.Name = "Tether"
	tether.Shape = Enum.PartType.Cylinder
	tether.Material = Enum.Material.Neon
	tether.Color = Color3.fromRGB(255, 255, 255) -- 흰색
	tether.CanCollide = false
	tether.CFrame = CFrame.new((startPos + endPos) / 2, endPos)
	tether.Size = Vector3.new(0.3, (startPos - endPos).Magnitude, 0.3)
	tether.TopSurface = Enum.SurfaceType.Smooth
	tether.BottomSurface = Enum.SurfaceType.Smooth
	tether.Parent = workspace
	
	-- 줄 자동 삭제 (2초)
	game:GetService("Debris"):AddItem(tether, 2)
end

-- 감전 함수
function TaserRemote.ApplyElectricity(target, state)
	if not target:FindFirstChild("Humanoid") then return end
	
	local humanoid = target:FindFirstChild("Humanoid")
	local connection
	
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		-- 거리 체크
		local distance = (state.taser.Position - target.Position).Magnitude
		if distance > TASER_CONFIG.tetherLength or not state.isActive then
			connection:Disconnect()
			state.target = nil
			return
		end
		
		-- 데미지 적용 (debounce)
		local currentTime = tick()
		if currentTime - state.lastDamageTime >= TASER_CONFIG.debounce then
			humanoid:TakeDamage(TASER_CONFIG.damagePerSecond * TASER_CONFIG.debounce)
			state.lastDamageTime = currentTime
			
			-- 번개 이펙트 생성
			TaserRemote.CreateElectricEffect(target)
		end
	end)
end

-- 번개 이펙트
function TaserRemote.CreateElectricEffect(target)
	local effect = Instance.new("Part")
	effect.Name = "ElectricEffect"
	effect.Shape = Enum.PartType.Ball
	effect.Material = Enum.Material.Neon
	effect.Color = Color3.fromRGB(255, 255, 0) -- 노란색
	effect.Size = Vector3.new(1, 1, 1)
	effect.CanCollide = false
	effect.CFrame = target.PrimaryPart.CFrame + Vector3.new(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2))
	effect.Parent = workspace
	
	game:GetService("Debris"):AddItem(effect, 0.2)
end

-- 줄 끊기 (U키 - 클라이언트에서 호출)
function TaserRemote.CutTether(player)
	local state = taserStates[player.UserId]
	if state then
		state.isActive = false
		state.target = nil
	end
end

return TaserRemote
