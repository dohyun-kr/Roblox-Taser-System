-- VFXManager.lua
-- 이펙트 및 라이트 관리

local VFXManager = {}
local RunService = game:GetService("RunService")

-- 번개 이펙트 생성
function VFXManager:CreateLightningEffect(startPos, endPos)
	local distance = (endPos - startPos).Magnitude
	local segmentCount = math.floor(distance / 2)
	
	for i = 1, segmentCount do
		local t = i / (segmentCount + 1)
		local basePos = startPos:Lerp(endPos, t)
		
		-- 번개 파장 효과
		local randomOffset = Vector3.new(
			math.random(-50, 50) / 100,
			math.random(-50, 50) / 100,
			math.random(-50, 50) / 100
		)
		
		local bolt = Instance.new("Part")
		bolt.Name = "LightningBolt"
		bolt.Shape = Enum.PartType.Cylinder
		bolt.Material = Enum.Material.Neon
		bolt.Color = Color3.fromRGB(255, 255, 150) -- 노란색
		bolt.Size = Vector3.new(0.2, 2, 0.2)
		bolt.CanCollide = false
		bolt.TopSurface = Enum.SurfaceType.Smooth
		bolt.BottomSurface = Enum.SurfaceType.Smooth
		bolt.CFrame = CFrame.new(basePos + randomOffset)
		bolt.Parent = workspace
		
		game:GetService("Debris"):AddItem(bolt, 0.1)
	end
end

-- 번개 연쇄 이펙트
function VFXManager:CreateChainLightning(target)
	if not target or not target:FindFirstChild("HumanoidRootPart") then return end
	
	local hrp = target:FindFirstChild("HumanoidRootPart")
	
	for _ = 1, 5 do
		local effect = Instance.new("Part")
		effect.Name = "ChainLightning"
		effect.Shape = Enum.PartType.Ball
		effect.Material = Enum.Material.Neon
		effect.Color = Color3.fromRGB(100, 200, 255) -- 파란색
		effect.Size = Vector3.new(0.3, 0.3, 0.3)
		effect.CanCollide = false
		effect.TopSurface = Enum.SurfaceType.Smooth
		effect.BottomSurface = Enum.SurfaceType.Smooth
		
		local randomPos = hrp.Position + Vector3.new(
			math.random(-20, 20) / 10,
			math.random(-20, 20) / 10,
			math.random(-20, 20) / 10
		)
		effect.CFrame = CFrame.new(randomPos)
		effect.Parent = workspace
		
		game:GetService("Debris"):AddItem(effect, 0.3)
	end
end

-- 발포 이펙트
function VFXManager:CreateMuzzleFlash(barrel)
	if not barrel then return end
	
	-- 주황색 플래시
	local flash = Instance.new("Part")
	flash.Name = "MuzzleFlash"
	flash.Shape = Enum.PartType.Ball
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(255, 150, 50)
	flash.Size = Vector3.new(1.5, 1.5, 1.5)
	flash.CanCollide = false
	flash.TopSurface = Enum.SurfaceType.Smooth
	flash.BottomSurface = Enum.SurfaceType.Smooth
	flash.CFrame = barrel.CFrame + barrel.CFrame.LookVector * 3
	flash.Parent = workspace
	
	-- 플래시 페이드
	local startTime = tick()
	local fadeConnection
	fadeConnection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		if elapsed > 0.2 then
			flash:Destroy()
			fadeConnection:Disconnect()
		else
			flash.Transparency = elapsed / 0.2
		end
	end)
end

-- 카트리지 파괴 이펙트
function VFXManager:CreateCartridgeExplosion(cartridge)
	if not cartridge then return end
	
	-- 폭발 파티클
	for i = 1, 15 do
		local particle = Instance.new("Part")
		particle.Name = "CartridgeParticle"
		particle.Shape = Enum.PartType.Ball
		particle.Material = Enum.Material.SmoothPlastic
		particle.Color = Color3.fromRGB(200, 100, 50)
		particle.Size = Vector3.new(0.3, 0.3, 0.3)
		particle.CanCollide = true
		particle.TopSurface = Enum.SurfaceType.Smooth
		particle.BottomSurface = Enum.SurfaceType.Smooth
		particle.CFrame = cartridge.CFrame + Vector3.new(
			math.random(-20, 20) / 10,
			math.random(-20, 20) / 10,
			math.random(-20, 20) / 10
		)
		particle.Velocity = (particle.Position - cartridge.Position).Unit * math.random(20, 50)
		particle.Parent = workspace
		
		game:GetService("Debris"):AddItem(particle, 1)
	end
	
	-- 폭발 충격파 (Neon 구)
	local shockwave = Instance.new("Part")
	shockwave.Name = "Shockwave"
	shockwave.Shape = Enum.PartType.Ball
	shockwave.Material = Enum.Material.Neon
	shockwave.Color = Color3.fromRGB(255, 200, 100)
	shockwave.Size = Vector3.new(0.5, 0.5, 0.5)
	shockwave.CanCollide = false
	shockwave.CFrame = cartridge.CFrame
	shockwave.Parent = workspace
	
	-- 충격파 확장
	local startTime = tick()
	local expandConnection
	expandConnection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		if elapsed > 0.5 then
			shockwave:Destroy()
			expandConnection:Disconnect()
		else
			local scale = 1 + elapsed * 10
			shockwave.Size = Vector3.new(0.5, 0.5, 0.5) * scale
			shockwave.Transparency = elapsed / 0.5
		end
	end)
end

-- 라이트 설정
function VFXManager:SetupLight(light)
	if not light then return end
	
	-- SpotLight 생성
	local attachment = Instance.new("Attachment")
	attachment.Name = "LightAttachment"
	attachment.Parent = light
	
	local spotlight = Instance.new("SpotLight")
	spotlight.Name = "SpotLight"
	spotlight.Brightness = 2
	spotlight.Range = 30
	spotlight.Color = Color3.fromRGB(255, 255, 255)
	spotlight.Enabled = false
	spotlight.Parent = attachment
	
	return spotlight
end

-- 라이트 토글
function VFXManager:ToggleLight(light, state)
	if not light then return end
	
	local attachment = light:FindFirstChild("LightAttachment")
	if attachment then
		local spotlight = attachment:FindFirstChild("SpotLight")
		if spotlight then
			spotlight.Enabled = state
		end
	end
end

-- 범위 내 이펙트
function VFXManager:CreateAreaEffect(position, radius)
	local particles = Instance.new("Part")
	particles.Name = "AreaEffect"
	particles.Shape = Enum.PartType.Ball
	particles.Material = Enum.Material.Neon
	particles.Color = Color3.fromRGB(100, 150, 255)
	particles.Size = Vector3.new(radius, radius, radius)
	particles.CanCollide = false
	particles.CFrame = CFrame.new(position)
	particles.Transparency = 0.5
	particles.TopSurface = Enum.SurfaceType.Smooth
	particles.BottomSurface = Enum.SurfaceType.Smooth
	particles.Parent = workspace
	
	-- 페이드 아웃
	local startTime = tick()
	local fadeConnection
	fadeConnection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		if elapsed > 0.5 then
			particles:Destroy()
			fadeConnection:Disconnect()
		else
			particles.Transparency = 0.5 + (elapsed / 0.5) * 0.5
		end
	end)
end

return VFXManager
