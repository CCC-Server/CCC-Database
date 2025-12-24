--F로그라이크 데블 래틀 헤드
local s,id=GetID()
function c128220103.initial_effect(c)
	c:EnableReviveLimit()
	--Fusion summon procedure
	Fusion.AddProcMix(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,0xc25),aux.FilterBoolFunctionEx(Card.IsRace,RACE_ZOMBIE))
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetOperation(s.tdop)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(Cost.SelfBanish)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,1))
	local g=Duel.SelectMatchingCard(tp,Card.IsSetCard,tp,LOCATION_DECK,0,1,1,nil,0xc25)
	local tc=g:GetFirst()
	if tc then
		Duel.ShuffleDeck(tp)
		Duel.MoveSequence(tc,0)
		Duel.ConfirmDecktop(tp,1)
	end
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=3 end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.filter(c)
	return ((c:IsMonster() or c:IsSpell() or c:IsTrap()) and c:IsAbleToGrave())
end
function s.thfilter(c)
	return c:IsSetCard(0xc25) and c:IsMonster()
end
function s.tthfilter(c)
	return c:IsSetCard(0xc25) and c:IsSpellTrap()
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=3 then
        Duel.ConfirmDecktop(tp,3)
        local g=Duel.GetDecktopGroup(tp,3)
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
        local sc=g:FilterSelect(tp,s.filter,1,1,nil):GetFirst()
        if sc then
            Duel.DisableShuffleCheck()
            if sc:IsMonster() then
				if Duel.SendtoGrave(sc,tp,REASON_EFFECT)>0 and sc:IsLocation(LOCATION_GRAVE) then
                    Duel.ConfirmCards(1-tp,sc)
                   if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g==0 then return end
		Duel.BreakEffect()
		Duel.SendtoHand(g,tp,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		Duel.BreakEffect()
		end
                end
				 elseif sc:IsTrap() or sc:IsSpell() then
			             if Duel.SendtoGrave(sc,tp,REASON_EFFECT)>0 and sc:IsLocation(LOCATION_GRAVE) then
                    Duel.ConfirmCards(1-tp,sc)
                   if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.tthfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g==0 then return end
		Duel.BreakEffect()
		Duel.SendtoHand(g,tp,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		Duel.BreakEffect()
		end
		end
                end
            end
        end
        Duel.ShuffleDeck(tp) -- 확인 후 남은 카드는 섞어야 함
    end