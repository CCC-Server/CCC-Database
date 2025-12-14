--스펠크래프트 링크 마녀 (예시 이름)
local s,id=GetID()
function s.initial_effect(c)
	--링크 소환 조건: 레벨4 이하의 스펠크래프트 몬스터 1장
	Link.AddProcedure(c,s.matfilter,1,1)
	c:EnableReviveLimit()

	--① 링크 소환 성공 시 "스펠크래프트" 카드 1장 서치
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,{id,0})
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--② (프리체인) 상대 필드의 카드 1장 파괴 + 카운터 제거 시 확산 파괴
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMING_MAIN_END+TIMINGS_CHECK_MONSTER)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

--링크 소재: 레벨 4 이하의 "스펠크래프트" 몬스터
function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(0x761,lc,sumtype,tp) and c:IsLevelBelow(4)
end

--① 조건: 링크 소환으로 소환되었을 때
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end
function s.thfilter(c)
	return c:IsSetCard(0x761) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--② 상대 필드 카드 1장 파괴 + 카운터 제거 시 동일 이름 확산
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.cfilter(c)
	return c:IsFaceup() and c:IsCode(128770286) and c:GetCounter(0x1)>=5
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if Duel.Destroy(tc,REASON_EFFECT)>0 then
		-- 추가효과: 가마솥에서 카운터 5개 제거 가능 시
		local g=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_SZONE,0,nil)
		if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
			local gc=g:Select(tp,1,1,nil):GetFirst()
			if gc then
				gc:RemoveCounter(tp,0x1,5,REASON_EFFECT)
				-- 서로의 덱 공개 후 동일 이름 전부 파괴
				Duel.ConfirmDecktop(tp,Duel.GetFieldGroupCount(tp,LOCATION_DECK,0))
				Duel.ConfirmDecktop(1-tp,Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0))
				local name=tc:GetCode()
				local dg=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_ONFIELD+LOCATION_HAND+LOCATION_GRAVE+LOCATION_DECK,LOCATION_ONFIELD+LOCATION_HAND+LOCATION_GRAVE+LOCATION_DECK,nil,name)
				if #dg>0 then
					Duel.Destroy(dg,REASON_EFFECT)
				end
				Duel.ShuffleDeck(tp)
				Duel.ShuffleDeck(1-tp)
			end
		end
	end
end
