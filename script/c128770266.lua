--스펠크래프트 서포터
local s,id=GetID()
function s.initial_effect(c)
	--① 패에서 링크 소재로 사용 가능
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCode(EFFECT_EXTRA_MATERIAL)
	e1:SetCountLimit(1,{id,1})
	e1:SetOperation(s.extracon)
	e1:SetValue(s.extraval)
	c:RegisterEffect(e1)

	--② 링크 소재로 묘지로 갔을 때
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_COUNTER)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCountLimit(1,{id,2})
	e2:SetCondition(s.ctcon)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)

	--③ 카운터 2개 제거 → 공격력 +1000 & 마/함 파괴
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,3})
	e3:SetCost(s.descost)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

---------------------------------------------------
--① 패에서 링크 소재로 사용 가능
---------------------------------------------------
function s.extracon(e,tp,eg,ep,ev,re,r,rp,lc,og)
	return lc:IsSetCard(0x761) -- 링크 소환 대상이 "스펠크래프트"인 경우
end
function s.extraval(e,c)
	if not c:IsRace(RACE_SPELLCASTER) then return nil end
	return LOCATION_HAND,0
end

---------------------------------------------------
--② 링크 소재로 묘지로 갔을 때
---------------------------------------------------
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return r==REASON_LINK and c:IsPreviousLocation(LOCATION_HAND+LOCATION_MZONE)
		and c:GetReasonCard():IsSetCard(0x761)
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_SZONE,0,nil,128770280) -- 스펠크래프트 마녀의 가마솥 코드
	local added=false
	if #g>0 then
		local tc=g:GetFirst()
		tc:AddCounter(0x1,2) -- 마력 카운터 2개 추가
	end
	if c:IsPreviousLocation(LOCATION_MZONE) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #sg>0 then
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
			added=true
		end
	end
end
function s.cfilter(c)
	return c:IsCode(128770280) and c:IsAbleToHand() -- 스펠크래프트 마녀의 가마솥
end

---------------------------------------------------
--③ 카운터 2개 제거 → 공격력 +1000 & 마/함 파괴
---------------------------------------------------
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_SZONE,0,nil,128770280)
	local tc=g:GetFirst()
	if chk==0 then return tc and tc:IsCanRemoveCounter(tp,0x1,2,REASON_COST) end
	tc:RemoveCounter(tp,0x1,2,REASON_COST)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and chkc:IsType(TYPE_SPELL+TYPE_TRAP) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_SZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_SZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(1000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e1)
	end
end
