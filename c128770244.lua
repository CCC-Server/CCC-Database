--대해의 사자 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	-----------------------------------
	--① 패에서 묘지로 보내고 서치
	-----------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-----------------------------------
	--② 릴리스 없이 일반 소환 가능
	-----------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_SUMMON_PROC)
	e2:SetCondition(s.ntcon)
	c:RegisterEffect(e2)

	-----------------------------------
	--③ 소환 성공 시 토큰 2장 특수 소환
	-----------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.tktg)
	e3:SetOperation(s.tkop)
	c:RegisterEffect(e3)
	-- 특수 소환 시에도 동일하게
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
end

-----------------------------------
--① : 패에서 묘지로 보내고 서치
-----------------------------------
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToGraveAsCost() end
	Duel.SendtoGrave(c,REASON_COST)
end
function s.thfilter(c)
	return (c:IsCode(128770241) or c:IsCode(128770242)) and c:IsAbleToHand() 
	-- "영현의 주악"과 "용의 계시"의 실제 코드로 교체 필요
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

-----------------------------------
--② : 릴리스 없이 일반 소환 가능
-----------------------------------
function s.ntcon(e,c,minc)
	if c==nil then return true end
	local tp=c:GetControler()
	return minc==0 and Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
		or not Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_MZONE,0,1,nil,TYPE_EFFECT)
end

-----------------------------------
--③ : 토큰 특수 소환
-----------------------------------
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
			and Duel.IsPlayerCanSpecialSummonMonster(tp,id+1,0,TYPES_TOKEN,1600,1200,4,RACE_DRAGON,ATTRIBUTE_WATER)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,0)
end
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,128770243,0,TYPES_TOKEN,1600,1200,4,RACE_DRAGON,ATTRIBUTE_WATER) then return end
	for i=1,2 do
		local token=Duel.CreateToken(tp,128770243)
		Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP)
		-- 릴리스 제한 부여
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UNRELEASABLE_SUM)
		e1:SetValue(s.unrelval)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		token:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_UNRELEASABLE_NONSUM)
		token:RegisterEffect(e2)
	end
	Duel.SpecialSummonComplete()
end
function s.unrelval(e,c)
	-- 드래곤족 듀얼 몬스터의 어드밴스 소환 / 융합 소재만 허용
	return not (c and c:IsRace(RACE_DRAGON) and c:IsType(TYPE_DUAL))
end
