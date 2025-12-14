--Spellcraft Witch (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--① 패에서 발동: 자신을 덱으로 되돌리고 "스펠크래프트 마녀의 가마솥"을 마/함 존에 앞면으로 놓는다
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	--② 파괴되었을 때: 가마솥에 마력 카운터 1개 추가
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_COUNTER)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.cttg)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)
end

---------------------------------------------------------------
--① 가마솥 배치 효과
function s.setfilter(c)
	return c:IsCode(128770286) and c:IsSSetable()  -- "스펠크래프트 마녀의 가마솥"
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
			and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and e:GetHandler():IsAbleToDeck()
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not (c:IsRelateToEffect(e) and Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_COST)>0) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
		Duel.ConfirmCards(1-tp,tc)
	end
end

---------------------------------------------------------------
--② 파괴 시 가마솥에 마력 카운터 1개 추가
function s.ctfilter(c)
	return c:IsFaceup() and c:IsCode(128770286) and c:IsCanAddCounter(0x1,2)
end
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.ctfilter,tp,LOCATION_SZONE,0,1,nil) end
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstMatchingCard(s.ctfilter,tp,LOCATION_SZONE,0,nil)
	if tc then
		tc:AddCounter(0x1,2)
	end
end
