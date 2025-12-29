--제 9사도-건설자 루크
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure (Level 12, 2 materials)
	Xyz.AddProcedure(c,nil,12,2)
	c:EnableReviveLimit()

	-- 이 카드는 룰상 "헤블론" 카드로도 취급한다.
	s.listed_series={0xc06}

	-- ①: 이 카드의 공격력은, 이 카드의 엑시즈 소재의 수 × 500 올린다.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	-- ②: 이 카드의 엑시즈 소재의 수에 따라, 이 카드는 이하의 효과를 얻는다.
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_ATTACK_ANNOUNCE+EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetLabel(0)
	e2:SetOperation(s.checkop)
	c:RegisterEffect(e2)

	-- 엑시즈 소재 1개 이상: 이 카드는 전투 / 효과로는 파괴되지 않는다.
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e3:SetValue(1)
	e3:SetCondition(s.ovccon1)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	c:RegisterEffect(e4)

	-- 엑시즈 소재 3개 이상: 이 카드의 속성은 "어둠"으로도 취급한다.
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_ADD_ATTRIBUTE)
	e5:SetValue(ATTRIBUTE_DARK)
	e5:SetCondition(s.ovccon3)
	c:RegisterEffect(e5)

	-- 엑시즈 소재 5개 이상: 이 카드는 이 카드를 대상으로 하는 효과 이외의 상대가 발동한 효과를 받지 않는다.
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCode(EFFECT_IMMUNE_EFFECT)
	e6:SetCondition(s.ovccon5)
	e6:SetValue(s.immval)
	c:RegisterEffect(e6)

	-- 엑시즈 소재 7개 이상: 1턴에 1번, 이 카드가 상대 카드의 효과의 대상이 되었을 때, 또는 상대 몬스터의 공격 대상으로 선택되었을 때에 발동할 수 있다. 상대 필드의 카드를 전부 파괴한다. 그 후, 상대 LP를 절반으로 한다.
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,1))
	e7:SetCategory(CATEGORY_DESTROY+CATEGORY_RECOVER)
	e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e7:SetCode(EVENT_BECOME_TARGET+EVENT_ATTACK_TARGET)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCountLimit(1,{id,2})
	e7:SetCondition(s.ovccon7)
	e7:SetOperation(s.ovop7)
	c:RegisterEffect(e7)
end

-- ① 효과: 엑시즈 소재의 수 × 500만큼 공격력 상승
function s.atkval(e,c)
	return c:GetOverlayCount()*500
end

-- 엑시즈 소재 수 체크
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() then
		local count=c:GetOverlayCount()
		if count~=e:GetLabel() then
			e:SetLabel(count)
			Duel.RaiseEvent(c,EVENT_CUSTOM+id,e,0,0,0,0)
		end
	end
end

-- 엑시즈 소재 1개 이상 조건
function s.ovccon1(e)
	return e:GetHandler():GetOverlayCount()>=1
end

-- 엑시즈 소재 3개 이상 조건
function s.ovccon3(e)
	return e:GetHandler():GetOverlayCount()>=3
end

-- 엑시즈 소재 5개 이상 조건
function s.ovccon5(e)
	return e:GetHandler():GetOverlayCount()>=5
end

-- 엑시즈 소재 5개 이상 효과 (대상 지정 이외 내성)
function s.immval(e,te)
	return te:IsActiveType(TYPE_FIELD) and te:GetOwnerPlayer()~=e:GetHandlerPlayer() and not te:IsHasTarget(e:GetHandler())
end

-- 엑시즈 소재 7개 이상 조건
function s.ovccon7(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:GetOverlayCount()<7 then return false end
	if e:GetCode()==EVENT_BECOME_TARGET then
		local tc=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS):GetFirst()
		return tc==c and rp==1-tp
	else -- EVENT_ATTACK_TARGET
		return Duel.GetAttackTarget()==c and rp==1-tp
	end
end

-- 엑시즈 소재 7개 이상 효과 (필드 전체 파괴 후 LP 절반)
function s.ovop7(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
	Duel.SetLP(1-tp,math.floor(Duel.GetLP(1-tp)/2))
end
