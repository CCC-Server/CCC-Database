--스펠크래프트 시그마 마기아 (예시 이름)
local s,id=GetID()
function s.initial_effect(c)
	--링크 소환 조건: "스펠크래프트" 몬스터 2장 이상
	Link.AddProcedure(c,s.matfilter,2,99)
	c:EnableReviveLimit()

	--① 링크 소환 성공 시 상대 필드/묘지의 몬스터를 장착
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,{id,0})
	e1:SetCondition(s.eqcon)
	e1:SetTarget(s.eqtg)
	e1:SetOperation(s.eqop)
	c:RegisterEffect(e1)

	--② 상대 효과 발동시, 마력 카운터 3개 제거 → 발동 무효 및 파괴
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	--③ "가마솥" 카운터 15개 이상일 때 스펠크래프트 효과 발동 시 200 데미지
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_CHAIN_SOLVING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetOperation(s.damop)
	c:RegisterEffect(e3)
end

--링크 소재 필터
function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(0x761,lc,sumtype,tp)
end

--① 링크 소환 성공 시 조건
function s.eqcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end
function s.eqfilter(c)
	return c:IsType(TYPE_MONSTER) and c:IsAbleToChangeControler()
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE+LOCATION_GRAVE) and chkc:IsControler(1-tp) and s.eqfilter(chkc) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingTarget(s.eqfilter,tp,0,LOCATION_MZONE+LOCATION_GRAVE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectTarget(tp,s.eqfilter,tp,0,LOCATION_MZONE+LOCATION_GRAVE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,1,0,0)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() or Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	if tc and tc:IsRelateToEffect(e) then
		Duel.Equip(tp,tc,c,true)
		--장착 제한
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetValue(function(e,c) return c==e:GetOwner() end)
		tc:RegisterEffect(e1)
		--공격력 상승 +1000
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_EQUIP)
		e2:SetCode(EFFECT_UPDATE_ATTACK)
		e2:SetValue(1000)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e2)
	end
end

--② 상대 효과 발동 시 무효 조건
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and Duel.IsChainNegatable(ev)
end
-- "스펠크래프트 마녀의 가마솥"의 카운터 3개 제거
function s.cfilter(c)
	return c:IsFaceup() and c:IsCode(128770286) and c:GetCounter(0x1)>=3
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_SZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local tc=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_SZONE,0,1,1,nil):GetFirst()
	if tc then
		tc:RemoveCounter(tp,0x1,3,REASON_COST)
	end
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

--③ 카운터 15개 이상 + 자신이 스펠크래프트 카드 발동 시 200 데미지
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	if not re then return end
	local rc=re:GetHandler()
	if rc:IsSetCard(0x761) and re:IsHasType(EFFECT_TYPE_ACTIVATE) then
		local g=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_SZONE,0,nil,128770286)
		local total=0
		for tc in aux.Next(g) do
			total=total+tc:GetCounter(0x1)
		end
		if total>=15 then
			Duel.Damage(1-tp,200,REASON_EFFECT)
		end
	end
end
