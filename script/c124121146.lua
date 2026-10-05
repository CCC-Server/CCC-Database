--샴밧드의 마도서
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	--①: 덱에서 "샴밧드의 마도서" 이외의 "마도서" 마법 카드 2장을 세트(같은 이름은 1장까지)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SET)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,{id,0})
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)
	--②: 상대가 발동한 몬스터 효과의 처리시에, 패 / 필드의 "마도서" 일반 / 속공 마법 1장을 묘지로 보내고 그 효과를 무효
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVING)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(s.negcon)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end
s.listed_series={SET_SPELLBOOK}
s.listed_names={id}
--①
function s.setfilter(c)
	return c:IsSetCard(SET_SPELLBOOK) and c:IsSpell() and not c:IsCode(id) and c:IsSSetable(true)
end
--같은 이름 1장까지 + 필드 마법은 필드 존(1장까지), 그 외는 마법 & 함정 존의 빈칸 수까지
function s.rescon(ft)
	return function(sg,e,tp,mg)
		local fc=sg:FilterCount(Card.IsType,nil,TYPE_FIELD)
		local c1=sg:GetClassCount(Card.GetCode)
		local c2=#sg
		return c1==c2 and fc<=1 and c2-fc<=ft,c1~=c2 or fc>1 or c2-fc>ft
	end
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_DECK,0,nil)
		local ft=Duel.GetLocationCount(tp,LOCATION_SZONE)
		return aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon(ft),0)
	end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_DECK,0,nil)
	local ft=Duel.GetLocationCount(tp,LOCATION_SZONE)
	local sg=aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon(ft),1,tp,HINTMSG_SET)
	if #sg>0 and Duel.SSet(tp,sg)>0 then
		--이 턴에, 이 효과로 세트한 카드는 필드에서 벗어났을 경우에 제외된다
		for tc in sg:Iter() do
			if tc:IsLocation(LOCATION_ONFIELD) then s.redirect(c,tc) end
		end
	end
	--이 턴에, 이 카드는 필드에서 벗어났을 경우에 제외된다
	if c:IsRelateToEffect(e) and c:IsOnField() then s.redirect(c,c) end
end
function s.redirect(c,tc)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(3300)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
	e1:SetValue(LOCATION_REMOVED)
	e1:SetReset(RESET_EVENT|RESETS_REDIRECT|RESET_PHASE|PHASE_END)
	tc:RegisterEffect(e1)
end
--②
function s.tgfilter(c)
	return c:IsSetCard(SET_SPELLBOOK) and (c:IsNormalSpell() or c:IsQuickPlaySpell()) and c:IsAbleToGrave()
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:IsMonsterEffect() and Duel.IsChainDisablable(ev)
		and not Duel.HasFlagEffect(tp,id)
		and Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_HAND|LOCATION_ONFIELD,0,1,nil)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,2)) then return end
	Duel.Hint(HINT_CARD,0,id)
	--1턴에 1번 (카드명 기준)
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_HAND|LOCATION_ONFIELD,0,1,1,nil)
	if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_GRAVE) then
		Duel.NegateEffect(ev)
	end
end
