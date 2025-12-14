---드래곤 듀얼 서포트
local s,id=GetID()
function s.initial_effect(c)
	--이 카드명의 카드는 1턴에 1장밖에 발동할 수 없다
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--② 묘지 제외 후 발동 → 드래곤/듀얼 지정 마법 세트
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_LEAVE_GRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1}) --①② 중 어느 한쪽만 1회
	e2:SetCost(aux.bfgcost) -- 묘지의 자신 제외
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

--① 드래곤족 / 듀얼 지정 몬스터 서치
function s.thfilter(c)
	-- 예시: 실제 대상 카드코드들 (드래곤 듀얼 관련 몬스터)
	return (c:IsCode(128770239) or c:IsCode(128770240) or c:IsCode(128770244)
		or c:IsCode(128770245) or c:IsCode(128770247)
		or c:IsCode(128770248) or c:IsCode(128770249)
		or c:IsCode(128770250))
		and c:IsAbleToHand()
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--② 묘지에서 제외 후 발동 → 드래곤 / 듀얼 지정 마법 세트
function s.setfilter(c)
	return (c:IsCode(128770241) or c:IsCode(128770242) or c:IsCode(128770258)
		or c:IsCode(128770259) or c:IsCode(128770260)
		or c:IsCode(128770261))
		and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,e:GetHandler(),1,0,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g:GetFirst())
		Duel.ConfirmCards(1-tp,g)
	end
end
