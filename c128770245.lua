--Dual Dragon Herald (듀얼 드래곤 헤럴드)
local s,id=GetID()
function s.initial_effect(c)
	----------------------------------------------
	--① 드래곤족 듀얼 취급
	----------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetCode(EFFECT_ADD_RACE)
	e0:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e0:SetValue(RACE_DRAGON)
	c:RegisterEffect(e0)

	local e0b=e0:Clone()
	e0b:SetCode(EFFECT_ADD_TYPE)
	e0b:SetValue(TYPE_GEMINI)
	c:RegisterEffect(e0b)

	----------------------------------------------
	--② 패에서 특수 소환
	----------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	----------------------------------------------
	--③ 서치: “영현의 주악” 또는 “용의 계시”
	----------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	----------------------------------------------
	--④ 융합 소재로 묘지로 보내졌을 경우 토큰 2장 생성
	----------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BE_MATERIAL)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,3})
	e3:SetCondition(s.tkcon)
	e3:SetTarget(s.tktg)
	e3:SetOperation(s.tkop)
	c:RegisterEffect(e3)
end

--------------------------------------------------
--② 조건: 자신 필드에 융합/듀얼 이외의 효과 몬스터 없음
--------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsExistingMatchingCard(s.nonfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.nonfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_EFFECT)
		and not (c:IsType(TYPE_FUSION) or c:IsType(TYPE_GEMINI))
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

--------------------------------------------------
--③ 덱 서치: “영현의 주악”, “용의 계시”
--------------------------------------------------
function s.thfilter(c)
	return (c:IsCode(128770241) or c:IsCode(128770242)) and c:IsAbleToHand()
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

--------------------------------------------------
--④ 융합 소재시 토큰 2장 소환
--------------------------------------------------
function s.tkcon(e,tp,eg,ep,ev,re,r,rp)
	return r & REASON_FUSION ~= 0
end
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
			and Duel.IsPlayerCanSpecialSummonMonster(tp,128770243,0,TYPES_TOKEN,1600,1200,4,RACE_DRAGON,ATTRIBUTE_WATER)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,0)
end
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
	for i=1,2 do
		if Duel.IsPlayerCanSpecialSummonMonster(tp,128770243,0,TYPES_TOKEN,1600,1200,4,RACE_DRAGON,ATTRIBUTE_WATER) then
			local token=Duel.CreateToken(tp,128770243)
			Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP)
			--릴리스 제한
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UNRELEASABLE_SUM)
			e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
			e1:SetRange(LOCATION_MZONE)
			e1:SetValue(s.relval)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e1,true)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_UNRELEASABLE_NONSUM)
			token:RegisterEffect(e2,true)
		end
	end
	Duel.SpecialSummonComplete()
end
function s.relval(e,c)
	return not (c:IsRace(RACE_DRAGON) and c:IsType(TYPE_GEMINI))
end
