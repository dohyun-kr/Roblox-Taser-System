-- SETUP_GUIDE.md
# 로블록스 테이저 시스템 설정 가이드

## 📁 파일 구조 및 설명

```
Roblox-Taser-System/
├── TaserScript.lua           # [서버] 메인 테이저 로직 (ServerScriptService)
├── TaserClientHandler.lua    # [클라이언트] 입력 처리 (StarterPlayer/StarterCharacterScripts)
├── TaserRemote.lua           # [서버] 리모트 함수 관리
├── TetherSystem.lua          # 줄 물리 및 시뮬레이션
├── VFXManager.lua            # 이펙트 및 라이트 관리
├── DamageSystem.lua          # 감전 데미지 처리
└── SETUP_GUIDE.md            # 이 파일
```

---

## 🔧 로블록스 스튜디오 설정

### 1️⃣ 모델 구조 (Workspace에 준비)

당신의 구조대로:
```
X26 (테이저 모델)
├── BarbMesh
├── BarbScript
├── Cart (카트리지 발사체)
├── Deployed
├── EventScript
│   ├── TaserRemote
│   ├── TaserScript
│   ├── TetherSystem
│   ├── TaserClientHandler
│   ├── VFXManager
│   ├── TimerVal
│   └── DamageSystem
├── LocalScript
├── Cart
├── Cartridge.L (왼쪽 카트리지)
├── Cartridge.R (오른쪽 카트리지)
├── Light
│   ├── Attachment
│   ├── Attachment0
│   ├── ParticleEmitter
│   ├── SpotLight
│   ├── Meshes/Dohyun/Light.02
│   ├── Meshes/Dohyun/Safety (x2)
│   ├── Meshes/Dohyun/Taser.001
│   ├── Meshes/Dohyun/Taser.002
│   └── Meshes/Dohyun/Trigger
├── Handle
├── Part1
└── Part2
```

---

## 📝 설치 단계

### Step 1: 스크립트 복사
1. 로블록스 스튜디오에서 `X26 > EventScript` 선택
2. 각 `.lua` 파일을 Script로 추가:
   - `TaserScript.lua` → Script 이름: "TaserScript"
   - `TaserRemote.lua` → Script 이름: "TaserRemote"
   - `TetherSystem.lua` → Script 이름: "TetherSystem"
   - `VFXManager.lua` → Script 이름: "VFXManager"
   - `DamageSystem.lua` → Script 이름: "DamageSystem"

3. `TaserClientHandler.lua` → LocalScript (StarterPlayer/StarterCharacterScripts)

### Step 2: 서버 스크립트 통합
`ServerScriptService`에 새 `Script` 추가:

```lua
-- 서버 메인 통합 스크립트
local TaserScript = require(game.Workspace:WaitForChild("X26").EventScript:WaitForChild("TaserScript"))
local TetherSystem = require(game.Workspace:WaitForChild("X26").EventScript:WaitForChild("TetherSystem"))
local VFXManager = require(game.Workspace:WaitForChild("X26").EventScript:WaitForChild("VFXManager"))
local DamageSystem = require(game.Workspace:WaitForChild("X26").EventScript:WaitForChild("DamageSystem"))

local Players = game:GetService("Players")

-- 플레이어 테이저 초기화
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local taser = character:FindFirstChild("X26") or workspace:FindFirstChild("X26")
		if taser then
			TaserScript:InitializeTaser(player, taser)
		end
	end)
end)

-- 클라이언트 이벤트 처리
local TaserFireEvent = Instance.new("RemoteEvent")
TaserFireEvent.Name = "TaserFire"
TaserFireEvent.Parent = game:GetService("ReplicatedStorage")

TaserFireEvent.OnServerEvent:Connect(function(player, targetPosition)
	local state = TaserScript:GetState(player)
	if state then
		TaserScript:Fire(player, targetPosition)
	end
end)

local TaserCutEvent = Instance.new("RemoteEvent")
TaserCutEvent.Name = "TaserCut"
TaserCutEvent.Parent = game:GetService("ReplicatedStorage")

TaserCutEvent.OnServerEvent:Connect(function(player)
	TaserScript:CutTether(player)
end)
```

---

## 🎮 게임 내 조작

| 키 | 기능 |
|---|---|
| **마우스 클릭** | 테이저 발포 (줄 발사) |
| **U** | 줄 끊기 (감전 중단) |
| **Y** | 라이트 ON/OFF |

---

## ⚙️ 설정값 조정

### TaserScript.lua의 CONFIG
```lua
local CONFIG = {
	maxDistance = 30,          -- 최대 발포 거리
	tetherLength = 30,         -- 줄 최대 길이
	damagePerSecond = 10,      -- 초당 데미지
	debounce = 0.1,            -- 데미지 주기 (초)
	cartridgeCount = 2,        -- 카트리지 개수
}
```

### DamageSystem.lua의 CONFIG
```lua
local CONFIG = {
	damagePerSecond = 10,      -- 초당 데미지
	debounce = 0.1,            -- 데미지 간격
	tetherMaxDistance = 30,    -- 줄 연결 최대거리
	slowEffect = 0.7,          -- 감전 시 속도감소 (0-1)
}
```

---

## 📊 시스템 흐름

```
플레이어가 마우스 클릭
    ↓
TaserClientHandler가 클릭 감지
    ↓
서버의 TaserScript:Fire() 호출
    ↓
줄(Tether) 생성 & 타겟 감지
    ↓
타겟이 Humanoid를 가지면?
    ├─ YES → DamageSystem:StartElectricity()
    │         ↓
    │         매 프레임 데미지 적용
    │         ↓
    │         VFXManager로 이펙트 생성
    │         ↓
    │         U키 또는 거리초과 → 줄 끊김
    │
    └─ NO → 그냥 줄만 표시 후 2초 후 사라짐
```

---

## 🔌 주요 함수

### TaserScript
- `InitializeTaser(player, taser)` - 테이저 초기화
- `Fire(player, mousePosition)` - 발포
- `ApplyElectricity(target, state)` - 감전 적용
- `CutTether(player)` - 줄 끊기

### DamageSystem
- `StartElectricity(taser, target, state)` - 감전 시작
- `StopElectricity(taser, target)` - 감전 중단
- `ApplySlowEffect(target)` - 속도 감소

### VFXManager
- `CreateLightningEffect(startPos, endPos)` - 번개 이펙트
- `CreateMuzzleFlash(barrel)` - 발포 플래시
- `CreateCartridgeExplosion(cartridge)` - 카트리지 폭발

### TetherSystem
- `CreateTether(startPos, endPos, taser, target)` - 줄 생성
- `VisualizeTether(tether)` - 줄 시각화

---

## 🐛 문제 해결

### 발포가 안 됨
- [ ] 카트리지 개수 확인 (`cartridgeCount > 0`)
- [ ] Barrel 파트가 X26에 있는지 확인
- [ ] 서버 스크립트가 실행 중인지 확인

### 줄이 안 보임
- [ ] Workspace가 비어있는지 확인
- [ ] VFXManager가 로드되었는지 확인

### 데미지가 안 들어감
- [ ] 타겟이 Humanoid를 가지고 있는지 확인
- [ ] DamageSystem이 로드되었는지 확인
- [ ] `damagePerSecond` 값이 0 이상인지 확인

---

## ✨ 커스터마이징 팁

### 줄의 색상 변경
TetherSystem.lua에서:
```lua
if i % 2 == 0 then
    part.Color = Color3.fromRGB(255, 255, 255) -- 흰색
else
    part.Color = Color3.fromRGB(50, 50, 50)    -- 검은색
end
```

### 이펙트 크기 조정
VFXManager.lua에서:
```lua
effect.Size = Vector3.new(0.5, 0.5, 0.5) -- 크기 조정
```

### 카트리지 개수 변경
TaserScript.lua에서:
```lua
cartridgeCount = 2, -- 원하는 개수로 변경
```

---

## 📚 참고사항

- 모든 스크립트는 Lua 기반입니다
- 서버-클라이언트 간 통신은 RemoteEvent를 사용합니다
- 물리 시뮬레이션은 Verlet Integration을 사용합니다
- 모든 이펙트는 Debris로 자동 정리됩니다

---

**제작자**: Copilot  
**버전**: 1.0.0  
**마지막 수정**: 2026-09-01
