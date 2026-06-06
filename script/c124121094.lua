--나츄르 시케이더
local s,id=GetID()
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_HAND+LOCATION_MZONE)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetCondition(s.con1)
	e1:SetCost(s.cost1)
	e1:SetTarget(s.tar1)
	e1:SetOperation(s.op1)
	c:RegisterEffect(e1)
	
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.con3)
	e3:SetCost(s.cost3)
	e3:SetTarget(s.tar3)
	e3:SetOperation(s.op3)
	c:RegisterEffect(e3)
end
s.listed_series={0x2a}

-- ①번 효과 Condition: 일반 소환된 몬스터의 효과 또는 마법 카드가 발동했을 때
function s.con1(e,tp,eg,ep,ev,re,r,rp)
	-- 마법 카드가 발동했을 때
	if re:IsActiveType(TYPE_SPELL) and re:IsHasType(EFFECT_TYPE_ACTIVATE) then
		return true
	end
	
	-- 엘섀도르 세키나가 사양 반영: 일반 소환된 몬스터의 효과가 발동했을 때
	local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	return loc==LOCATION_MZONE and re:IsMonsterEffect()
		and (re:GetHandler():GetSummonType()&SUMMON_TYPE_NORMAL)==SUMMON_TYPE_NORMAL
end

function s.cost1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToGraveAsCost() and Duel.GetFlagEffect(tp,id)==0
	end
	Duel.SendtoGrave(c,REASON_COST)
	Duel.RegisterFlagEffect(tp,id,RESET_CHAIN,0,1)
end

function s.tfil1(c,e,tp)
	return c:IsSetCard(0x2a) and c:IsLevelBelow(2) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.tar1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.tfil1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
			and Duel.GetMZoneCount(tp,c)>0
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end

function s.op1(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.tfil1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

function s.con3(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentPhase()&(PHASE_MAIN1+PHASE_MAIN2)~=0
end

function s.cost3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetFlagEffect(tp,id)==0
	end
	Duel.RegisterFlagEffect(tp,id,RESET_CHAIN,0,1)
end

function s.tfil3(c)
	return c:IsFaceup() and c:IsAbleToDeck() and c:IsSetCard(0x2a) and not c:IsCode(id)
end

function s.tar3(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then
		return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and s.tfil3(chkc)
	end
	if chk==0 then
		return c:IsAbleToHand() and Duel.IsExistingTarget(s.tfil3,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.tfil3,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,3,nil)
	g:AddCard(c)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,4,0,0)
end

function s.op3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetTargetCards(e)
	if c:IsRelateToEffect(e) and #g>0 then
		g:AddCard(c)
		Duel.SendtoDeck(g,nil,2,REASON_EFFECT)
	end
end