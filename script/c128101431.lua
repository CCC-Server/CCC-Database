--World Guardian - (Field Spell Prototype)
local s,id=GetID()
function s.initial_effect(c)
	------------------------------------
	-- (1) 발동시 덱에서 "World Guardian" 몬스터 1장 묘지로
	------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- "이 카드명의 카드는 1턴에 1번만 발동할 수 있다."
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)
	
	------------------------------------
	-- (2) 몬스터 효과 발동 시, GY의 "World Guardian" 특소
	------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_FZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	-- "이 카드명의 (2) 효과는 1턴에 1번만 사용할 수 있다."
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	
	------------------------------------
	-- (3) 전투 시작 시, 전투하는 상대 몬스터 제외(표시형 뒷면)
	--    → EVENT_DAMAGE_STEP_START 대신 EVENT_BATTLE_START 사용
	------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_START)          -- 여기 수정
	e3:SetRange(LOCATION_FZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	-- "이 카드명의 (3) 효과는 1턴에 1번만 사용할 수 있다."
	e3:SetCountLimit(1,id+200)
	e3:SetCondition(s.rmcon)
	e3:SetTarget(s.rmtg)
	e3:SetOperation(s.rmop)
	c:RegisterEffect(e3)
end

----------------------------------------------------------
-- (1) 발동시 덱에서 "World Guardian" 몬스터 1장 묘지로
----------------------------------------------------------
function s.tgfilter(c)
	return c:IsSetCard(0xc52) and c:IsType(TYPE_MONSTER) and c:IsAbleToGrave()
end
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	if Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) then
		Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	end
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	if not Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) then return end
	-- "You can" 이라 선택 가능
	if Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoGrave(g,REASON_EFFECT)
		end
	end
end

----------------------------------------------------------
-- (2) 몬스터 효과 발동 시, GY의 "World Guardian" 특소
----------------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsActiveType(TYPE_MONSTER)
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc52) and c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp)
			and s.spfilter(chkc,e,tp)
	end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

----------------------------------------------------------
-- (3) 전투 시작 시, 전투하는 상대 몬스터 제외(표시형 뒷면)
----------------------------------------------------------
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	if not a or not d then return false end
	-- 내 "World Guardian" 몬스터 vs 상대 몬스터
	if a:IsControler(tp) then
		return a:IsFaceup() and a:IsSetCard(0xc52) and a:IsType(TYPE_MONSTER)
			and d:IsControler(1-tp)
	else
		return d:IsControler(tp) and d:IsFaceup() and d:IsSetCard(0xc52) and d:IsType(TYPE_MONSTER)
			and a:IsControler(1-tp)
	end
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	local tc
	if a:IsControler(tp) then
		tc=d
	else
		tc=a
	end
	if chk==0 then return tc~=nil end
	Duel.SetTargetCard(tc)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,tc,1,0,0)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc then return end
	-- "You can" 옵션
	if not (tc:IsRelateToBattle() and tc:IsRelateToEffect(e)) then return end
	if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)
	end
end
