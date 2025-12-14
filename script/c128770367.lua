local s,id=GetID()
function s.initial_effect(c)
	c:EnableCounterPermit(0x1)

	-- Activate only if no monster was Normal/Special Summoned
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCondition(s.actcon)
	c:RegisterEffect(e0)

	-- Indestructible by opponent's effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(s.indval)
	c:RegisterEffect(e1)

	-- Count unique Spell Types
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_SZONE)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)

	---------------------------------------------------------
	-- ③ 자동: 카운터 4 이상이면 Spell 효과 데미지 2배
	---------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CHANGE_DAMAGE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetTargetRange(0,1) -- 상대에게 가는 데미지만
	e3:SetValue(s.damval)
	c:RegisterEffect(e3)

	-- Reset Spell Type history each turn
	if not s.global_check then
		s.global_check=true
		s[0]={}
		s[1]={}
		local ge=Effect.CreateEffect(c)
		ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge:SetCode(EVENT_PHASE_START+PHASE_DRAW)
		ge:SetOperation(function()
			s[0]={}
			s[1]={}
		end)
		Duel.RegisterEffect(ge,0)
	end
end

-- 0. 발동 조건 (해당 턴 Monster NS/SS가 없었어야 함)
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetActivityCount(tp,ACTIVITY_NORMALSUMMON)==0
		and Duel.GetActivityCount(tp,ACTIVITY_SPSUMMON)==0
end

-- ① 파괴내성
function s.indval(e,re,rp)
	return rp~=e:GetHandlerPlayer()
end

-- Spell Type 변환 함수
function s.gettype(c)
	if c:IsType(TYPE_RITUAL) then return TYPE_RITUAL end
	if c:IsType(TYPE_QUICKPLAY) then return TYPE_QUICKPLAY end
	if c:IsType(TYPE_FIELD) then return TYPE_FIELD end
	if c:IsType(TYPE_CONTINUOUS) then return TYPE_CONTINUOUS end
	if c:IsType(TYPE_EQUIP) then return TYPE_EQUIP end
	return TYPE_SPELL
end

-- ② 서로 다른 종류의 Spell 발동 시 카운터 +1
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not re or not re:IsActiveType(TYPE_SPELL) then return end
	if rp~=tp then return end
	local st=s.gettype(re:GetHandler())
	if not s[tp][st] then
		s[tp][st]=true
		c:AddCounter(0x1,1)
	end
end

---------------------------------------------------------
-- ③ Spell 효과 데미지 2배 (카운터가 4 이상이면 자동 적용)
---------------------------------------------------------
function s.damval(e,re,val,r,rp,rc)
	local c=e:GetHandler()
	if c:GetCounter(0x1) >= 4
		and re and re:IsActiveType(TYPE_SPELL)
		and bit.band(r,REASON_EFFECT)~=0 then
		return val*2
	end
	return val
end
