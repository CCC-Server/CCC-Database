local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	
	-- 의식 소환: "기계천사의 의식"으로, 레벨 이상이면 가능
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.ritcon)
	e1:SetOperation(s.ritop)
	e1:SetValue(SUMMON_TYPE_RITUAL)
	c:RegisterEffect(e1)

	-- 의식 소환 성공 시 효과 부여 (2장 이상, 3장 이상, 효과 내성)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.effcon)
	e2:SetOperation(s.effop)
	c:RegisterEffect(e2)

	-- 4장 이상: 상대 필드 전부 묘지로
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_TOGRAVE)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	e5:SetCondition(s.tgcon)
	e5:SetTarget(s.tgtg)
	e5:SetOperation(s.tgop)
	e5:SetCountLimit(1,{id,3})
	c:RegisterEffect(e5)
end

-- "기계천사의 의식" 확인
function s.ritfilter(c)
	return c:IsCode(39996157) and c:IsType(TYPE_RITUAL)
end

-- 의식 소환 조건: 기계천사의 의식 존재 + 레벨 이상 합
function s.ritcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local rg=Duel.GetRitualMaterial(tp)
	return Duel.IsExistingMatchingCard(s.ritfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil)
		and rg:CheckWithSumGreater(function(mat) return mat:GetRitualLevel(c) end, c:GetLevel(), 1, 99)
end

-- 의식 소환 처리
function s.ritop(e,tp,eg,ep,ev,re,r,rp,c)
	local rg=Duel.GetRitualMaterial(tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local mat=rg:SelectWithSumGreater(tp,function(mc) return mc:GetRitualLevel(c) end,c:GetLevel(),1,99)
	c:SetMaterial(mat)
	Duel.ReleaseRitualMaterial(mat)
end

-- 의식 소환 성공 조건: "기계천사의 의식"에 의한 의식 소환
function s.effcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_RITUAL) and re and re:GetHandler():IsCode(39996157)
end

-- 의식 소재 수에 따라 효과 부여
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mat=c:GetMaterial()
	local count=mat:GetCount()

	-- 2장 이상: 릴리스 제거
	if count>=2 then
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,0))
		e1:SetCategory(CATEGORY_RELEASE)
		e1:SetType(EFFECT_TYPE_QUICK_O)
		e1:SetCode(EVENT_FREE_CHAIN)
		e1:SetRange(LOCATION_MZONE)
		e1:SetCountLimit(1,{id,2})
		e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
		e1:SetTarget(s.rltg)
		e1:SetOperation(s.rlop)
		c:RegisterEffect(e1)
	end

	-- 3장 이상: ATK/DEF +2000
	if count>=3 then
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_UPDATE_ATTACK)
		e2:SetValue(2000)
		c:RegisterEffect(e2)
		local e3=e2:Clone()
		e3:SetCode(EFFECT_UPDATE_DEFENSE)
		c:RegisterEffect(e3)
	end

	-- 4장 이상: 효과 무효화 내성
	if count>=4 then
		local e4=Effect.CreateEffect(c)
		e4:SetType(EFFECT_TYPE_SINGLE)
		e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e4:SetCode(EFFECT_IMMUNE_EFFECT)
		e4:SetRange(LOCATION_MZONE)
		e4:SetValue(s.efilter)
		c:RegisterEffect(e4)
	end
end

-- 4장 이상 조건 체크
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_RITUAL)
		and re and re:GetHandler():IsCode(39996157)
		and c:GetMaterialCount()>=4
end

-- 릴리스 제거 대상 선택
function s.rltg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and chkc:IsReleasable() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsReleasable,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectTarget(tp,Card.IsReleasable,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_RELEASE,g,1,0,0)
end

-- 릴리스 제거 실행
function s.rlop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.Release(tc,REASON_EFFECT)
	end
end

-- 효과 무효화 내성
function s.efilter(e,te)
	return te:GetOwner()~=e:GetOwner()
end

-- 상대 필드 전부 묘지로 보내기
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToGrave,tp,0,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,#g,0,0)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,0,LOCATION_ONFIELD,nil)
	Duel.SendtoGrave(g,REASON_EFFECT)
end

