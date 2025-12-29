--제 9사도-건설자 루크
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure (Level 12, 2 materials)
	Xyz.AddProcedure(c,nil,12,2)
	c:EnableReviveLimit()
	
	-- 룰상 "헤블론" 취급 (listed_series는 보조 정보이므로 실제 효과 처리는 아님)
	s.listed_series={0xc06}

	-- ①: 공수 상승 (Update Attack/Defense는 지속 효과)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	-- ②: 엑시즈 소재 1개 이상: 전투/효과 파괴 내성
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetCondition(s.ovccon1)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	c:RegisterEffect(e3)

	-- ③: 엑시즈 소재 3개 이상: 어둠 속성 취급
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_ADD_ATTRIBUTE)
	e4:SetCondition(s.ovccon3)
	e4:SetValue(ATTRIBUTE_DARK)
	c:RegisterEffect(e4)

	-- ④: 엑시즈 소재 5개 이상: 대상 외 내성
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCode(EFFECT_IMMUNE_EFFECT)
	e5:SetCondition(s.ovccon5)
	e5:SetValue(s.immval)
	c:RegisterEffect(e5)

	-- ⑤: 엑시즈 소재 7개 이상: 필드 클린
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_DESTROY+CATEGORY_RECOVER)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O) -- FIELD 트리거로 변경 권장
	e6:SetCode(EVENT_BECOME_TARGET)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1,{id,1})
	e6:SetCondition(s.ovccon7_target)
	e6:SetOperation(s.ovop7)
	c:RegisterEffect(e6)
	local e7=e6:Clone()
	e7:SetCode(EVENT_ATTACK_TARGET)
	e7:SetCondition(s.ovccon7_attack)
	c:RegisterEffect(e7)
end

function s.atkval(e,c)
	return c:GetOverlayCount()*500
end

function s.ovccon1(e) return e:GetHandler():GetOverlayCount()>=1 end
function s.ovccon3(e) return e:GetHandler():GetOverlayCount()>=3 end
function s.ovccon5(e) return e:GetHandler():GetOverlayCount()>=5 end

-- 대상 지정 이외의 상대가 발동한 효과 내성
function s.immval(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer() 
		and te:IsActivated() -- 발동한 효과
		and not te:IsHasTarget(e:GetHandler()) -- 대상을 취하지 않는
end

-- 소재 7개: 대상이 되었을 때
function s.ovccon7_target(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetOverlayCount()>=7 and eg:IsContains(c) and rp==1-tp
end

-- 소재 7개: 공격 대상이 되었을 때
function s.ovccon7_attack(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetOverlayCount()>=7 and Duel.GetAttackTarget()==c and rp==1-tp
end

function s.ovop7(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
	-- LP 절반 (GetLP 사용)
	Duel.SetLP(1-tp,math.ceil(Duel.GetLP(1-tp)/2))
end