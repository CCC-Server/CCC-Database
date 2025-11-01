--암군 ??? 융합체
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Fusion Material: 암군 라크쉬룸 + Fusion Monster
	Fusion.AddProcMix(c,true,true,128101255,aux.FilterBoolFunction(Card.IsType,TYPE_FUSION))

	--① 융합 소환 성공 or 상대 효과 발동시: 특소 + (상대 턴이라면 제외)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	local e1b=Effect.CreateEffect(c)
	e1b:SetDescription(aux.Stringid(id,0))
	e1b:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e1b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1b:SetCode(EVENT_CHAINING)
	e1b:SetRange(LOCATION_MZONE)
	e1b:SetProperty(EFFECT_FLAG_DELAY)
	e1b:SetCountLimit(1,id)
	e1b:SetCondition(s.spcon2)
	e1b:SetTarget(s.sptg)
	e1b:SetOperation(s.spop)
	c:RegisterEffect(e1b)

	--② GY로 보내졌을 때 → 몬스터 1장 되돌림
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.rtg)
	e2:SetOperation(s.rop)
	c:RegisterEffect(e2)
end
s.listed_series={0xc45}
s.listed_names={128101255}

-----------------------------------------------------------
-- ① 특수 소환 + 상대 턴에 제외
-----------------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp and re:IsActivated()
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc45) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.rmfilter(c)
	return c:IsAbleToRemove() and c:IsOnField()
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
	if Duel.GetTurnPlayer()~=tp then
		Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_ONFIELD)
	end
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		if Duel.GetTurnPlayer()~=tp then
			local rg=Duel.GetMatchingGroup(s.rmfilter,tp,0,LOCATION_ONFIELD,nil)
			if #rg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
				local sg=rg:Select(tp,1,1,nil)
				Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
			end
		end
	end
end

-----------------------------------------------------------
-- ② 묘지로 보내졌을 때: 앞면 몬스터 1장 → 패로
-----------------------------------------------------------
function s.rtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() and chkc:IsAbleToHand() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToHand,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.rop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end
