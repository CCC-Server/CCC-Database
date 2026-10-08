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
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SET)
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
	local e3=e1:Clone()
	e3:SetCode(4179255)
	e3:SetCondition(s.thcon3)
	c:RegisterEffect(e3)
	--②: 자신은 "마도서" 속공 마법 카드 1장을 세트한 턴에 발동할 수 있다 (1턴에 1번)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
	e4:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e4:SetRange(LOCATION_SZONE)
	e4:SetTargetRange(LOCATION_SZONE,0)
	e4:SetCountLimit(1,{id,1})
	e4:SetTarget(function(e,c) return c:IsSetCard(SET_SPELLBOOK) and c:IsQuickPlaySpell() end)
	c:RegisterEffect(e4)
end
s.listed_series={SET_SPELLBOOK}
s.listed_names={id}
--①
--이 카드 자신의 발동(카드의 발동)이 처리되었을 경우
function s.thcon1(e,tp,eg,ep,ev,re,r,rp)
	return re and re:GetHandler()==e:GetHandler() and re:IsHasType(EFFECT_TYPE_ACTIVATE)
end
--이 카드 이외의 마법 "카드"가 발동했을 경우 (자신 / 상대 불문, "엘렉트로 거너" 참조)
--EFFECT_TYPE_ACTIVATE = 카드의 발동. 필드에 있는 마법 카드의 효과의 발동(기동 효과 등)은 포함하지 않는다
function s.thcon2(e,tp,eg,ep,ev,re,r,rp)
	return re:IsSpellEffect() and re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:GetHandler()~=e:GetHandler()
end
--효과로 마법 카드가 발동되었을 경우 (이 카드 자신 포함)
function s.thcon3(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	return tc and tc:IsSpell() and re and re:IsHasType(EFFECT_TYPE_ACTIVATE)
end
--"샴밧드의 마도서" 이외의 "마도서" 마법 카드 (패에 넣거나 세트할 수 있는 것)
function s.thfilter(c)
	return c:IsSetCard(SET_SPELLBOOK) and c:IsSpell() and not c:IsCode(id)
		and (c:IsAbleToHand() or c:IsSSetable())
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	--덱에서 1장을 고르고, 패에 넣거나 자신 필드에 세트한다
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_OPERATECARD)
	local tc=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
	if tc then
		aux.ToHandOrElse(tc,tp,
			function(sc) return sc:IsSSetable() end,
			function(sc) Duel.SSet(tp,sc) end,
			1153)
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
