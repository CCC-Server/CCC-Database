--샴밧드의 마도서
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	--①-a: 이 카드를 발동했을 경우 (발동이 처리된 후, 별개의 체인으로 유발)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_CHAIN_SOLVED)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,{id,0})
	e1:SetCondition(s.thcon1)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	--①-b: 자신 / 상대가 다른 마법 카드를 발동했을 경우
	local e2=e1:Clone()
	e2:SetCode(EVENT_CHAINING)
	e2:SetCondition(s.thcon2)
	c:RegisterEffect(e2)
	--①-c: 카드의 효과로 마법 카드가 발동된 경우 ("마도서기 쥬논" ② 등, 체인을 형성하지 않는 발동)
	--Duel.ActivateFieldSpell 및 수동 발동 처리가 일으키는 이벤트(4179255)를 감지
	--이 카드 자신이 효과로 발동된 경우와, 다른 마법 카드가 효과로 발동된 경우 모두 포함
	local e4=e1:Clone()
	e4:SetCode(4179255)
	e4:SetCondition(s.thcon3)
	c:RegisterEffect(e4)
	--②: 상대가 엑스트라 덱에서 몬스터를 특수 소환했을 경우
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.rmcon)
	e3:SetTarget(s.rmtg)
	e3:SetOperation(s.rmop)
	c:RegisterEffect(e3)
end
s.listed_series={SET_SPELLBOOK}
s.listed_names={id}
--①
--이 카드 자신의 발동(카드의 발동)이 처리되었을 경우
function s.thcon1(e,tp,eg,ep,ev,re,r,rp)
	return re and re:GetHandler()==e:GetHandler() and re:IsHasType(EFFECT_TYPE_ACTIVATE)
end
--이 카드 이외의 마법 카드가 발동했을 경우 (자신 / 상대 불문)
function s.thcon2(e,tp,eg,ep,ev,re,r,rp)
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:IsSpellEffect() and re:GetHandler()~=e:GetHandler()
end
--효과로 마법 카드가 발동되었을 경우 (이 카드 자신 포함)
function s.thcon3(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	return tc and tc:IsSpell() and re and re:IsHasType(EFFECT_TYPE_ACTIVATE)
end
function s.thfilter(c)
	return c:IsSetCard(SET_SPELLBOOK) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
	--다음 턴 종료시까지, 이 카드는 필드에서 벗어났을 경우에 제외된다
	if c:IsRelateToEffect(e) and c:IsOnField() then
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(3300)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
		e1:SetValue(LOCATION_REMOVED)
		e1:SetReset(RESET_EVENT|RESETS_REDIRECT|RESET_PHASE|PHASE_END,2)
		c:RegisterEffect(e1)
	end
end
--②
function s.rmconfilter(c,tp)
	return c:IsSummonPlayer(1-tp) and c:IsSummonLocation(LOCATION_EXTRA)
end
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.rmconfilter,1,nil,tp)
end
function s.costfilter(c)
	return c:IsSetCard(SET_SPELLBOOK) and c:IsSpell() and (c:IsFaceup() or not c:IsOnField()) and c:IsAbleToRemove()
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=eg:Filter(s.rmconfilter,nil,tp)
	if chk==0 then return g:IsExists(Card.IsAbleToRemove,1,nil)
		and Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND|LOCATION_ONFIELD|LOCATION_GRAVE,0,3,nil) end
	--"그 몬스터"를 추적하기 위해 관련 카드로 지정 (대상을 취하는 효과는 아님)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,3,tp,LOCATION_HAND|LOCATION_ONFIELD|LOCATION_GRAVE)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	--자신의 패 / 필드(앞면 표시) / 묘지에서 "마도서" 마법 카드를 3장 제외
	local cg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.costfilter),tp,LOCATION_HAND|LOCATION_ONFIELD|LOCATION_GRAVE,0,nil)
	if #cg<3 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local sg=cg:Select(tp,3,3,nil)
	local fg=sg:Filter(Card.IsLocation,nil,LOCATION_ONFIELD|LOCATION_GRAVE)
	if #fg>0 then Duel.HintSelection(fg) end
	if Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)<3 then return end
	--그 몬스터를 제외한다
	local tg=Duel.GetTargetCards(e):Filter(Card.IsLocation,nil,LOCATION_MZONE)
	if #tg>0 then
		Duel.Remove(tg,POS_FACEUP,REASON_EFFECT)
	end
end
