--고양이귀무녀 냐미
--ねこみみこにゃみ
--Mimiko Nyami
local s,id=GetID()
function s.initial_effect(c)
	--effect 1
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cst1)
	e1:SetTarget(s.tg1)
	e1:SetOperation(s.op1)
	c:RegisterEffect(e1)
	--effect 2
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET,EFFECT_FLAG2_CHECK_SIMULTANEOUS)
	e2:SetCode(EVENT_CHAIN_SOLVED)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(aux.bfgcost)
	e2:SetCondition(s.selfspcon)
	e2:SetTarget(s.tokentg)
	e2:SetOperation(s.tokenop)
	c:RegisterEffect(e2)
end

--Part of "Mimiko" archetype
s.listed_series={0xda0}

function s.cst1filter(c)
	return (c:IsRace(RACE_BEAST) or c:IsCode(124331019)) and not c:IsPublic()
end

function s.tokenfilter(c)
	return c:IsRace(RACE_BEAST)
end

function s.cst1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.cst1filter,tp,LOCATION_HAND,0,c)
	if chk==0 then return #g>0 and not c:IsPublic() end
	local sg=aux.SelectUnselectGroup(g,e,tp,1,1,aux.TRUE,1,tp,HINTMSG_CONFIRM)
	Duel.ConfirmCards(1-tp,sg+c)
	Duel.ShuffleHand(tp)
end

function s.thfilter(c)
	return c:IsSetCard(0xda0) and c:IsAbleToHand() and not c:IsCode(id)
end
function s.tg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,g,1,0,0)
end

function s.sumfilter(c)
	return c:IsRace(RACE_BEAST) and c:IsSummonable(true,nil)
end

function s.op1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
	local tc=Duel.SelectMatchingCard(tp,s.sumfilter,tp,LOCATION_HAND,0,1,1,nil):GetFirst()
	if tc then
		Duel.Summon(tp,tc,true,nil)
	end
	end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetValue(s.actlimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	aux.RegisterClientHint(e:GetHandler(),nil,tp,1,0,aux.Stringid(id,0),nil)
end
function s.actlimit(e,re,rp)
	local rc=re:GetHandler()
	return re:IsActiveType(TYPE_MONSTER) and not rc:IsRace(RACE_BEAST)
end
function s.selfspconfilter(c,tp)
	return c:IsRace(RACE_BEAST) and c:IsControler(tp)
end

function s.selfspcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()
return (re:IsActiveType(TYPE_MONSTER) and rc:IsRace(RACE_BEAST)) or rc:IsSetCard(0xda0)
end

function s.lvfilter(c,lv)
	return c:IsFaceup() and c:IsLevelBelow(12) and not c:IsLevel(lv)
end

function s.tokentg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
		local c=e:GetHandler()
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE) and chkc:IsRace(RACE_BEAST) and s.lvfilter(chkc,lv) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,12433101,0,TYPES_TOKEN,0,0,1,RACE_BEAST,ATTRIBUTE_EARTH)
		and Duel.IsExistingTarget(s.tokenfilter,tp,LOCATION_GRAVE,0,1,c) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.tokenfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,tp,0)
end

function s.tokenop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0
		or not Duel.IsPlayerCanSpecialSummonMonster(tp,124331012,0,TYPES_TOKEN,0,0,1,RACE_BEAST,ATTRIBUTE_EARTH) then return false end
	local tc=Duel.GetFirstTarget()
	local token=Duel.CreateToken(tp,124331012)
	if Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP) and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		--Change its Level
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_LEVEL)
		e1:SetValue(tc:GetLevel())
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		token:RegisterEffect(e1)
	end
	Duel.SpecialSummonComplete()
end
