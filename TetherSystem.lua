-- TetherSystem.lua
-- 줄 물리 시뮬레이션 및 관리

local TetherSystem = {}
local RunService = game:GetService("RunService")

local CONFIG = {
	tetherLength = 30,
	segmentCount = 10,
	gravity = 196.2,
	damping = 0.99,
	rigidity = 0.9,
}

local activeTethers = {}

-- 줄 생성
function TetherSystem:CreateTether(startPos, endPos, taser, target)
	local tether = {
		startPos = startPos,
		endPos = endPos,
		taser = taser,
		target = target,
		distance = (endPos - startPos).Magnitude,
		isActive = true,
		segments = {},
		createdAt = tick(),
	}
	
	-- 세그먼트 생성
	for i = 1, CONFIG.segmentCount do
		local t = i / (CONFIG.segmentCount + 1)
		local pos = startPos:Lerp(endPos, t)
		
		table.insert(tether.segments, {
			position = pos,
			oldPosition = pos,
			pinned = false,
		})
	end
	
	-- 첫 번째 세그먼트는 테이저에 고정
	tether.segments[1].pinned = true
	
	-- 마지막 세그먼트는 타겟에 고정
	if tether.segments[CONFIG.segmentCount] then
		tether.segments[CONFIG.segmentCount].pinned = true
	end
	
	table.insert(activeTethers, tether)
	
	-- 시물레이션 시작
	self:SimulateTether(tether)
	
	return tether
end

-- 줄 시뮬레이션
function TetherSystem:SimulateTether(tether)
	local connection
	local elapsed = 0
	
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not tether.isActive then
			connection:Disconnect()
			return
		end
		
		elapsed = elapsed + deltaTime
		
		-- 줄 업데이트
		self:UpdateTether(tether, deltaTime)
		
		-- 줄 시각화
		self:VisualizeTether(tether)
		
		-- 2초 후 자동 정리
		if elapsed > 2 then
			tether.isActive = false
			connection:Disconnect()
		end
	end)
end

-- 줄 업데이트 (Verlet Integration)
function TetherSystem:UpdateTether(tether, deltaTime)
	-- 중력 적용
	for i = 1, #tether.segments do
		local segment = tether.segments[i]
		
		if not segment.pinned then
			local velocity = (segment.position - segment.oldPosition) * CONFIG.damping
			segment.oldPosition = segment.position
			segment.position = segment.position + velocity + Vector3.new(0, -CONFIG.gravity * deltaTime * deltaTime, 0)
		end
	end
	
	-- 제약 조건 적용
	for _ = 1, 3 do
		for i = 1, #tether.segments - 1 do
			local seg1 = tether.segments[i]
			local seg2 = tether.segments[i + 1]
			
			local delta = seg2.position - seg1.position
			local distance = delta.Magnitude
			local targetDistance = tether.distance / CONFIG.segmentCount
			
			local correction = (distance - targetDistance) / distance * 0.5 * CONFIG.rigidity
			
			if not seg1.pinned then
				seg1.position = seg1.position + delta * correction
			end
			if not seg2.pinned then
				seg2.position = seg2.position - delta * correction
			end
		end
	end
	
	-- 시작점과 끝점 고정
	if tether.taser then
		local barrel = tether.taser:FindFirstChild("Barrel")
		if barrel then
			tether.segments[1].position = barrel.Position + barrel.CFrame.LookVector * 2
			tether.segments[1].oldPosition = tether.segments[1].position
		end
	end
	
	if tether.target then
		local humanoidRootPart = tether.target:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local lastSegment = tether.segments[#tether.segments]
			if lastSegment then
				lastSegment.position = humanoidRootPart.Position
				lastSegment.oldPosition = lastSegment.position
			end
		end
	end
end

-- 줄 시각화 (흰색/검은색 줄무늬)
function TetherSystem:VisualizeTether(tether)
	-- 기존 줄 제거
	for _, child in pairs(tether.visualParts or {}) do
		child:Destroy()
	end
	tether.visualParts = {}
	
	-- 새 줄 생성
	for i = 1, #tether.segments - 1 do
		local seg1 = tether.segments[i]
		local seg2 = tether.segments[i + 1]
		
		local part = Instance.new("Part")
		part.Name = "TetherSegment"
		part.Shape = Enum.PartType.Cylinder
		part.Material = Enum.Material.Neon
		part.CanCollide = false
		
		-- 흰색/검은색 교대
		if i % 2 == 0 then
			part.Color = Color3.fromRGB(255, 255, 255) -- 흰색
		else
			part.Color = Color3.fromRGB(50, 50, 50) -- 검은색
		end
		
		local distance = (seg2.position - seg1.position).Magnitude
		part.Size = Vector3.new(0.2, distance, 0.2)
		part.CFrame = CFrame.new((seg1.position + seg2.position) / 2, seg2.position)
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = workspace
		
		table.insert(tether.visualParts, part)
	end
end

-- 줄 제거
function TetherSystem:RemoveTether(tether)
	tether.isActive = false
	if tether.visualParts then
		for _, part in pairs(tether.visualParts) do
			part:Destroy()
		end
	end
end

-- 모든 활성 줄 제거
function TetherSystem:RemoveAllTethers()
	for _, tether in pairs(activeTethers) do
		self:RemoveTether(tether)
	end
	activeTethers = {}
end

return TetherSystem
